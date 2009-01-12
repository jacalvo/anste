# Copyright (C) 2007 José Antonio Calvo Fernández <jacalvo@warp.es> 
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package ANSTE::Virtualizer::Virt;

use base 'ANSTE::Virtualizer::Virtualizer';

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Image::Image;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::NotFound;

use File::Temp qw(tempfile);
use File::Copy;
use File::Copy::Recursive qw(dircopy);

use constant KVM_CONFIG_TEMPLATE => 'kvm-config.tmpl';
use constant KVM_NETWORK_CONFIG_TEMPLATE => 'kvm-bridge.tmpl';

# Class: Virt
#
#   Implementation of the Virtualizer class that interacts
#   with libvirt.
#

# Method: createBaseImage
#
#   Overriden method that creates a new base image using the xen-create-image
#   utility from xen-tools.
#
# Parameters: 
#   
#   name    - name of the image type to be created
#   ip      - ip address that will be assigned to the image
#   memory  - *optional* size of the RAM memory to be used
#   size    - *optional* size of the root partition
#   swap    - *optional* size of the swap partition to be used
#   dist    - distribution to be installed (for debootstrap method)
#   command - command to be used for the installation (for debootstrap method)
#
# Returns:
#
#   boolean - Always returns true due to xen-create-image is broken and
#             returns it although the creation process fails.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createBaseImage # (%params)
{
    my ($self, %params) = @_;

    exists $params{name} or
        throw ANSTE::Exceptions::MissingArgument('name');
    exists $params{ip} or
        throw ANSTE::Exceptions::MissingArgument('ip');

    my $name = $params{name};
    my $ip = $params{ip};
    my $memory = $params{memory};
    my $swap = $params{swap};
    my $dist = $params{dist};
    my $size = $params{size};

    my $config = ANSTE::Config->instance();

    my $gateway = $config->gateway();
    my $netmask = '255.255.255.0';

    if (not $size) {
        $size = $config->virtSize();
    }
    if (not $memory) {
        $memory = $config->virtMemory();
    }        

    my $dir = $config->imagePath() . '/' . $name;
    if (-d $dir) {
        die "Directory $dir already exists";
    }

    # TODO: change this to generic $config->mirror() ?
    my $mirror = $config->xenMirror(); 

    my $vm = 'kvm'; # TODO: Unhardcode this when supporting other virtualizers
    my $command = "ubuntu-vm-builder $vm $dist --dest $dir --hostname $name" .
                  " --ip $ip --mirror $mirror --mem $memory" . 
                  " --mask $netmask --gw $gateway --rootsize $size" .
                  " --components main,universe"; 
    
    # FIXME: We don't use swap at the moment to speed up the process
    $command .= " --swapsize 0";
    #if ($swap) {
    #   $command .= " --swapsize $swap";
    #}
    
    $self->execute($command) or
        die "Error executing ubuntu-vm-builder";

    # Creates the configuration file for the new image
    my $image = new ANSTE::Image::Image(name => $name,
                                        ip => $ip,
                                        memory => $memory);
    my $network = $self->_networkForBaseImage($ip);
    $image->setNetwork($network);
    my $xml = $self->_createImageConfig($image, $dir);

    # Writes the qemu configuration file
    my $FILE;
    my $xmlFile = "$dir/domain.xml";
    open($FILE, '>', $xmlFile) or return 0;
    print $FILE $xml;
    close($FILE) or return 0; 

    # Convert to raw format so we can mount it with -o loop
    my $imgcommand;
    if (-f '/usr/bin/kvm-img') { 
    	$imgcommand = 'kvm-img'; 
    } else {
    	$imgcommand = 'qemu-img'; 
    }
    $self->execute("$imgcommand convert $dir/root.qcow2 -O raw $dir/root.img");

    # Delete qcow2 image
    unlink("$dir/root.qcow2");
}

# Method: shutdownImage 
#
#   Overriden method that shuts down a Xen running image.
#
# Parameters:
#
#   image - name of the image to shutdown 
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub shutdownImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $config = ANSTE::Config->instance();

    # It seems that virsh shutdown destroys the machine immediately,
    # so we wait a few seconds until some operations finish
    sleep 5;

    $self->execute("virsh shutdown $image");

    # Wait until shutdown finishes
    my $waitScript = $config->scriptFile('kvm-waitshutdown.sh');
    system("$waitScript $image");
}

# Method: destroyImage 
#
#   Overriden method that destroys a Xen running image.
#
# Parameters:
#
#   image - name of the image to shutdown 
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub destroyImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    $self->execute("virsh destroy $image");
}

# Method: createVM
#
#   Overriden method that creates a KVM Virtual Machine.
#
# Parameters:
#
#   name - name of the libvirt configuration file for the image 
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createVM # (name)
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');
    
    my $path = ANSTE::Config->instance()->imagePath();
    $self->execute("virsh create $path/$name/domain.xml");
}

# Method: imageFile
#
#   Overriden method to get the path o a KVM disk image. 
#
# Parameters:
#
#   path - root directory where images are stored
#   name - name of the image (of the directory in the KVM case)
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub imageFile # (path, name)
{
    my ($self, $path, $name) = @_;

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    return "$path/$name/root.img";
}

# Method: copyImage
#
#  Overriden method that creates a copy of a base image
#  with the specified new configuration.
#
# Parameters:
#
#   baseimage - an <ANSTE::Scenario::BaseImage> object with the configuration
#               of the base image
#   newimage  - an <ANSTE::Image::Image> object with the configuration 
#               of the new image
#
# Returns:
#   
#   boolean   - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType>     - throw if argument has invalid type
#
sub createImageCopy # (baseimage, newimage)
{
    my ($self, $baseimage, $newimage) = @_;

    defined $baseimage or
        throw ANSTE::Exceptions::MissingArgument('baseimage');
    defined $newimage or
        throw ANSTE::Exceptions::MissingArgument('newimage');

    if (not $baseimage->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exception::InvalidType('baseimage',
                                            'ANSTE::Scenario::BaseImage');
    }
    if (not $newimage->isa('ANSTE::Image::Image')) {
        throw ANSTE::Exception::InvalidType('newimage',
                                            'ANSTE::Image::Image');
    }

    my $path = ANSTE::Config->instance()->imagePath();

    my $basename = $baseimage->name();
    my $newname = $newimage->name();

    if (not -r $self->imageFile($path, $basename)) {
        throw ANSTE::Exceptions::NotFound('Image', $basename);
    }

    dircopy("$path/$basename", "$path/$newname");

    # Creates the configuration file for the new image
    my $config = $self->_createImageConfig($newimage, "$path/$newname");

    # Writes the xen configuration file
    my $FILE;
    my $configFile = "$path/$newname/domain.xml";
    open($FILE, '>', $configFile) or return 0;
    print $FILE $config;
    close($FILE) or return 0; 

    return 1;
}

# Method: deleteImage 
#
#   Overriden method that deletes the kvm image.
#
# Parameters: 
#   
#   image - name of the image to be deleted
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub deleteImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $dir = ANSTE::Config->instance()->imagePath();

    $self->execute("rm -rf $dir/$image");
}

# Method: createNetwork
#
#   Overriden method that creates bridges with
#   libvirt for the network of the given scenario.
#
# Parameters: 
#   
#   scenario   - a <ANSTE::Scenario::Scenario> object
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType>     - throw if argument has invalid type
#
sub createNetwork # (scenario)
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw ANSTE::Exceptions::InvalidType('scenario',
                                            'ANSTE::Scenario::Scenario');
    }                                            

    my $path = ANSTE::Config->instance()->imagePath();

    my %bridges = %{$scenario->bridges()};
    while (my ($net, $num) = each %bridges) {
        # Writes the libvirt XML
        my $xml = $self->_createNetworkConfig($net, $num);

        my $FILE;
        my $xmlFile = "$path/bridge$num.xml";
        open($FILE, '>', $xmlFile) or return 0;
        print $FILE $xml;
        close($FILE) or return 0; 
        
        if (not $self->execute("virsh net-create $xmlFile")) {
            $self->execute("ifconfig virbr$num down");
            $self->execute("brctl delbr virbr$num");
            $self->execute("virsh net-create $xmlFile") or return 0;
        }
    }
    return 1;
}


# Method: destroyNetwork
#
#   Overriden method that destroy previously creaated bridges with
#   libvirt for the network of the given scenario.
#
# Parameters: 
#   
#   scenario   - a <ANSTE::Scenario::Scenario> object
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType>     - throw if argument has invalid type
#
sub destroyNetwork # (scenario)
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw ANSTE::Exceptions::InvalidType('scenario',
                                            'ANSTE::Scenario::Scenario');
    }                                            
    my $path = ANSTE::Config->instance()->imagePath();

    my %bridges = %{$scenario->bridges()};
    while (my ($net, $num) = each %bridges) {
        $self->execute("virsh net-destroy bridge$num");
        unlink("$path/bridge$num.xml");
    }
}

sub _createImageConfig # (image, path) returns config string
{
    my ($self, $image, $path) = @_;

    my $config = ANSTE::Config->instance();
    my $name = $image->name();
    my $memory = $image->memory() * 1024;

    my $imageConfig = "<domain type='kvm'>\n"; # TODO: Unhardcode kvm
    $imageConfig .= "\t<name>$name</name>\n";
    $imageConfig .= "\t<memory>$memory</memory>\n";
    $imageConfig .= "\t<vcpu>1</vcpu>\n";
    $imageConfig .= "\t<os><type arch='i686'>hvm</type></os>\n";
    $imageConfig .= "\t<clock sync='localtime'/>\n";
    $imageConfig .= "\t<on_poweroff>destroy</on_poweroff>\n";
    $imageConfig .= "\t<on_reboot>restart</on_reboot>\n";
    $imageConfig .= "\t<on_crash>restart</on_crash>\n";
    $imageConfig .= "\t<devices>\n";
    $imageConfig .= "\t\t<emulator>/usr/bin/kvm</emulator>\n";
    $imageConfig .= "\t\t<disk type='file' device='disk'>\n";
    $imageConfig .= "\t\t\t<source file='$path/root.img'/>\n";
    $imageConfig .= "\t\t\t<target dev='hda' bus='ide'/>\n";
    $imageConfig .= "\t\t</disk>\n";
    foreach my $iface (@{$image->network()->interfaces()}) {
        $imageConfig .= "\t\t<interface type='bridge'>\n";
        my $bridge = $iface->bridge();
        my $mac = $iface->hwAddress();
        $imageConfig .= "\t\t\t<source bridge='virbr$bridge'/>\n"; 
        $imageConfig .= "\t\t\t<mac address='$mac'/>\n"; 
        $imageConfig .= "\t\t</interface>\n";
    }
    $imageConfig .= "\t\t<graphics type='vnc' port='-1' autoport='yes' keymap='es'/>\n";
    $imageConfig .= "\t</devices>\n";
    $imageConfig .= "</domain>\n";

    return $imageConfig;
}

sub _createNetworkConfig # (net, bridge) returns config string
{
    my ($self, $net, $bridge) = @_;

    my $config = ANSTE::Config->instance();

    # Only allow forward for the first bridge (ANSTE communication network)
    my $forward = 0;
    my $address;
    my $netmask = '255.255.255.0'; # FIXME: Unharcode this

    if ($bridge == 1) {
        $forward = 1;
        $address = $config->gateway();
    }
    else {
        $address = ANSTE::Validate::ip($net) ? $net : "$net.254";
    }

    my $networkConfig = "<network>\n";
    $networkConfig .= "\t<name>bridge$bridge</name>\n";
    $networkConfig .= "\t<uuid></uuid>\n";
    $networkConfig .= "\t<bridge name=\"virbr$bridge\" />\n";
    if ($forward) {
        $networkConfig .= "\t<forward/>\n";
    }
    $networkConfig .= "\t<ip address=\"$address\" netmask=\"$netmask\" />\n";
    $networkConfig .= "</network>\n";

    return $networkConfig;
}

sub _networkForBaseImage # (ip) returns network object
{
    my ($self, $ip) = @_;

    my $config = ANSTE::Config->instance();

    my $gateway = $config->gateway();
    my $netmask = '255.255.255.0';

    my $network = new ANSTE::Scenario::Network();
    my $iface = new ANSTE::Scenario::NetworkInterface();
    $iface->setName('eth0');
    $iface->setTypeStatic();
    $iface->setAddress($ip);
    $iface->setNetmask($netmask);
    $iface->setGateway($gateway);
    $iface->setBridge(1);
    $network->addInterface($iface);

    return $network;
}


1;

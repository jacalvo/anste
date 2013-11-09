# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

package ANSTE::Virtualizer::VBox;

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

# Class: Virt
#
#   Implementation of the Virtualizer class that interacts
#   with Virtual Box.
#

my $BRIDGE_PREFIX = 'anstebr';
my $VBOXCMD = 'vboxmanage -nologo';
my $IDE_CTL = 'idectl';
my $SATA_CTL = 'satactl';

# Method: createBaseImage
#
#   Overriden method that creates a new base image
#
# Parameters:
#
#   name    - name of the image type to be created
#   ip      - ip address that will be assigned to the image
#   memory  - *optional* size of the RAM memory to be used
#   size    - *optional* size of the root partition
#   swap    - *optional* size of the swap partition to be used
#   arch    - *optional* architecture to be used
#   dist    - distribution to be installed (for debootstrap method)
#   command - command to be used for the installation (for debootstrap method)
#   mirror  - mirror to be used for the installation
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
    my $arch = $params{arch};
    my $mirror = $params{mirror};

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

    if (not $mirror) {
        $mirror = $config->vmBuilderMirror();
    }

    my $vm = 'vbox'; # TODO: Unhardcode this when supporting other virtualizers
    my $command = "ubuntu-vm-builder $vm $dist --dest $dir --hostname $name" .
                  " --ip $ip --mirror $mirror --mem $memory --kernel-flavour generic --addpkg linux-generic" .
                  " --mask $netmask --gw $gateway --rootsize $size" .
                  " --components main,universe --removepkg=cron --domain $name";

    if ($arch) {
        $command .= " --arch $arch";
    }

    # FIXME: We don't use swap at the moment to speed up the process
    $command .= " --swapsize 8";
    #if ($swap) {
    #   $command .= " --swapsize $swap";
    #}

    my $proxy = $config->vmBuilderProxy();
    if ($proxy) {
        $command .= " --proxy $proxy";
    }

    my $securityMirror = $config->vmBuilderSecurityMirror();
    if ($securityMirror) {
        $command .= " --security-mirror $securityMirror";
    }

    $self->execute($command) or
        die "Error executing ubuntu-vm-builder";

    # Creates the configuration file for the new image
    my $image = new ANSTE::Image::Image(name => $name,
                                        ip => $ip,
                                        memory => $memory);
    my $network = $self->_networkForBaseImage($ip);
    $image->setNetwork($network);

    # Rename disk image
    $self->execute("mv $dir/*.vdi $dir/disk.vdi");
}

# Method: shutdownImage
#
#   Overriden method that shuts down a VBox running image.
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

    $self->execute($self->_controlVM($image,"poweroff"));
}

# Method: destroyImage
#
#   Overriden method that destroys a VBox running image.
#
# Parameters:
#
#   image - name of the image to destroy
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

    $self->execute("$VBOXCMD unregistervm $image --delete");
}

# Method: createVM
#
#   Overriden method that creates a VBox Virtual Machine.
#
# Parameters:
#
#   image - image of the VBox virtual machine
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createVM # (image, ip)
{
    my ($self, $image, $ip) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');
    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

    my $path = ANSTE::Config->instance()->imagePath();
    my $name = $image->name();
    $self->execute("$VBOXCMD createvm --name $name --register --basefolder $path");
    $self->execute("$VBOXCMD storagectl $name --name $IDE_CTL --add ide");
    $self->execute("$VBOXCMD storagectl $name --name $SATA_CTL --add sata");

    # Configure the new image
    $self->_configureImage($image, "$path/$name", $ip);

    $self->execute("$VBOXCMD startvm $name --type headless");
}

# Method: imageFile
#
#   Overriden method to get the path to a disk image.
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

    return "$path/$name/disk.vdi";
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

    $self->execute("$VBOXCMD clonevm $basename --name $newname --register --basefolder $path");

}

# Method: deleteImage
#
#   Overriden method that deletes the vbox image.
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
        my $xmlFile = "$path/anste-bridge$num.xml";
        open($FILE, '>', $xmlFile) or return 0;
        print $FILE $xml;
        close($FILE) or return 0;

        if (not $self->execute("virsh net-create $xmlFile")) {
            $self->execute("ifconfig ${BRIDGE_PREFIX}${num} down");
            $self->execute("brctl delbr ${BRIDGE_PREFIX}${num}");
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
        $self->execute("virsh net-destroy anste-bridge$num");
        unlink("$path/anste-bridge$num.xml");
    }
}

sub _configureImage # (image, path, ip) returns config string
{
    my ($self, $image, $path, $ip) = @_;

    my $config = ANSTE::Config->instance();
    my $name = $image->name();
    my $memory = $image->memory();
    my $arch = `arch`;
    chomp ($arch);

    $self->_modifyVM($name, 'memory', $memory);

    my $ostype;
    if ($arch eq "x86_64"){
        $ostype = "Ubuntu_64";
    } else {
        $ostype = "Ubuntu";
    }
    $self->_modifyVM($name, 'ostype', $ostype);

    $self->execute("$VBOXCMD storageattach $name --device 0 --port 0 --storagectl $IDE_CTL --type hdd --medium $path/disk.vdi");

    if ( not $image->network() ) {
        my $network = $self->_networkForBaseImage($ip);
        $image->setNetwork($network);
    }

    my $nic=1;
    foreach my $iface (@{$image->network()->interfaces()}) {
        my $bridge = $iface->bridge();
        my $mac = $iface->hwAddress();
        $self->_modifyVM($name, 'nic'.$nic, "bridged");
        $self->_modifyVM($name, 'bridgeadapter'.$nic, ${BRIDGE_PREFIX}.${bridge});
        $self->_modifyVM($name, 'macaddress'.$nic, $mac);
        $nic++;
    }

    return 1;
}

# FIXME: unhardcode this?
my $bridge_mac_prefix = '00:1F:3E:5D:C7';
my $mac_id = 80;

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
    $networkConfig .= "\t<name>anste-bridge$bridge</name>\n";
    if ($forward) {
        $networkConfig .= "\t<bridge name=\"${BRIDGE_PREFIX}${bridge}\" />\n";
        $networkConfig .= "\t<forward mode=\"nat\" />\n";
        $networkConfig .= "\t<ip address=\"$address\" netmask=\"$netmask\" />\n";
    } else {
        $networkConfig .= "\t<bridge name=\"${BRIDGE_PREFIX}${bridge}\" stp=\"on\" delay=\"0\" />\n";
        $networkConfig .= "\t<mac address=\"$bridge_mac_prefix:$mac_id\" />\n";
        $mac_id++;
    }
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
    my $name = $config->commIface();

    $iface->setName($name);
    $iface->setTypeStatic();
    $iface->setAddress($ip);
    $iface->setNetmask($netmask);
    $iface->setGateway($gateway);
    $iface->setBridge(1);
    $network->addInterface($iface);

    return $network;
}

# Method: createSnapshot
#
#   Creates a VM snapshot using libvirt
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#   description  - description of the snapshot
#
sub createSnapshot
{
    my ($self, $domain, $name, $description) = @_;

    $self->execute("virsh snapshot-create-as $domain $name '$description'");
}

# Method: revertSnapshot
#
#   Reverts a VM snapshot using libvirt
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub revertSnapshot
{
    my ($self, $domain, $name) = @_;

    $self->execute("virsh snapshot-revert $domain $name --force");
}

# Method: deleteSnapshot
#
#   Deletes a VM snapshot using libvirt
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub deleteSnapshot
{
    my ($self, $domain, $name) = @_;

    $self->execute("virsh snapshot-delete $domain $name");
}

sub _controlVM
{
     my ($self, $name, $command) = @_;

     return ("$VBOXCMD controlvm $name $command");
}

sub _modifyVM
{
    my ($self, $name, $setting, $value) = @_;

    print "$VBOXCMD modifyvm $name --$setting $value\n";
    $self->execute("$VBOXCMD modifyvm $name --$setting $value");
}

1;

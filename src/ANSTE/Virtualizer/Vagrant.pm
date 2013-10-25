# Copyright (C) 2013 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

package ANSTE::Virtualizer::Vagrant;

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

# Class: Vagrant
#
#   Implementation of the Virtualizer class that interacts
#   with Vagrant.
#

my $BRIDGE_PREFIX = 'anstebr';

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

    # FIXME: get vagrant box or create it using vagrant
    return;

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

    my $vm = 'kvm'; # TODO: Unhardcode this when supporting other virtualizers
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
    my $xml = $self->_createImageConfig($image, $dir);

    # Writes the qemu configuration file
    my $FILE;
    my $xmlFile = "$dir/domain.xml";
    open($FILE, '>', $xmlFile) or return 0;
    print $FILE $xml;
    close($FILE) or return 0;

    # Rename disk image
    $self->execute("mv $dir/*.qcow2 $dir/disk.qcow2");
}

# Method: shutdownImage
#
#   Overriden method that shuts down a Vagrant running image.
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

    $self->_vagrantCommand('halt', $image);
}

# Method: destroyImage
#
#   Overriden method that destroys a Vagrant running image.
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

    $self->_vagrantCommand('destroy', $image);
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

    $self->_vagrantCommand('up', $name);
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

    #FIXME
    return;

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

sub _createImageConfig # (image, path) returns config string
{
    my ($self, $image, $path) = @_;

    my $config = ANSTE::Config->instance();
    my $name = $image->name();
    my $memory = $image->memory() * 1024;
    my $arch = `arch`;
    chomp ($arch);

    my $imageConfig = "Vagrant.configure(2) do |config|\n";
    $imageConfig .= "\tconfigvm.define \"$name\" do |$name|\n";
    $imageConfig .= "\t\t$name.vm.box = \"base\"\n";
    my $num = 1;
    my %macs;
    foreach my $iface (@{$image->network()->interfaces()}) {
        my $bridge = $iface->bridge();
        $imageConfig .= "\t\t$name.vm.network :\"public_network\", :bridge => '${BRIDGE_PREFIX}${bridge}\n";
        $macs{$num} = $iface->hwAddress();
        $num++;
    }
    $imageConfig .= "\tend\n";
    $imageConfig .= "\tconfig.vm.provider \"virtualbox\" do |v|\n";
    $imageConfig .= "\t\tv.customize [\"modifyvm\", :id, \"--memory\", \"$memory\"]\n";
    foreach my $num (keys %macs) {
        $imageConfig .= "\t\tv.customize [\"modifyvm\", :id, \"--macaddress$num\", \"$macs{$num}\"]\n";
    }
    $imageConfig .= "end\n";

    return $imageConfig;
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

sub _vagrantCommand
{
    my ($self, $command, $image) = @_;

    my $path = ANSTE::Config->instance()->imagePath();
    $self->execute("cd $path/$image; vagrant $command");
}

1;

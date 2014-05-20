# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2014 Rubén Durán Balda <rduran@zentyal.com>
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

use threads;
use threads::shared;
use TryCatch::Lite;
use Attempt;

my $lockMount : shared;
my $lockCreate : shared;

# Class: Virt
#
#   Implementation of the Virtualizer class that interacts
#   with libvirt.
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
sub createBaseImage
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
#   Overriden method that shuts down a KVM running image.
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
sub shutdownImage
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
#   Overriden method that destroys a KVM running image.
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
sub destroyImage
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    $self->execute("virsh destroy $image");
}

# Method: preCreateVM
#
#   Overridden method to perform the necessary steps before the creation of
#   a KVM Virtual Machine.
#
# Parameters:
#
#   host - <ANSTE::Scenario::Host> object.
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub preCreateVM
{
    my ($self, $host, $image) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $hostname = $host->name();

    ANSTE::info("[$hostname] Creating a copy of the base image...");
    my $error = 0;
    try {
        my $baseimage = $host->baseImage();
        if (not $self->createImageCopy($baseimage, $image)) {
            ANSTE::info("[$hostname] Can't copy base image");
            $error = 1;
        }
    } catch (ANSTE::Exceptions::NotFound $e) {
        ANSTE::info("[$hostname] Base image not found, can't continue.");
        $error = 1;
    }

    unless($error) {
        # Critical section to prevent mount errors with loop device busy
        {
            lock($lockMount);

            ANSTE::info("[$hostname] Updating hostname on the new image...");
            try {
                my $ok = $self->_updateHostname($image);
                if (not $ok) {
                    ANSTE::info("[$hostname] Error copying host files.");
                    $error = 1;
                }
            } catch ($e) {
                ANSTE::info("[$hostname] ERROR: $e");
                $error = 1;
            }
        }
    }

    return not $error;
}

# FIXME: We should not use ANSTE::Image::Commands from within a virtualizer
sub _updateHostname
{
    my ($self, $image) = @_;

    my $ok = 0;
    my $cmd = new ANSTE::Image::Commands($image);

    attempt {
        try {
            $cmd->mount() or die "Can't mount image: $!";
        } catch {
            $cmd->deleteMountPoint();
            die "Can't mount image.";
        }
    } tries => 5, delay => 5;

    try {
        $cmd->copyHostFiles() or die "Can't copy files: $!";
        $ok = 1;
    } catch ($e) {
        $cmd->umount() or die "Can't unmount image: $!";
        $e->throw();
    }
    $cmd->umount() or die "Can't unmount image: $!";

    return $ok;
}

# Method: createVM
#
#   Overriden method that creates a KVM Virtual Machine.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createVM
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('$image');

    my $name = $image->{name};
    my $path = ANSTE::Config->instance()->imagePath();

    my $error = 0;
    # Critical section to prevent KVM crashes when trying to create
    # two machines at the same time
    {
        lock($lockCreate);

        $error = $self->execute("virsh create $path/$name/domain.xml") or
                    throw ANSTE::Exceptions::Error("Error creating domain $name");
    };

    return not $error;
}

# Method: defineVM
#
#   Overriden method that defines a KVM Virtual Machine.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub defineVM
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('$image');

    my $name = $image->{name};

    my $path = ANSTE::Config->instance()->imagePath();
    $self->execute("virsh define $path/$name/domain.xml") or
        throw ANSTE::Exceptions::Error("Error defining domain $name");
}

# Method: startVM
#
#   Overriden method that starts a KVM Virtual Machine.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub startVM
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('name');

    my $name = $image->{name};
    return $self->execute("virsh start $name");
}

# Method: removeVM
#
#   Overriden method that removes a Virtual Machine
#
# Parameters:
#
#   name - name of the libvirt domain
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub removeVM
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    $self->execute("virsh undefine $name --snapshots-metadata");
}

# Method: existsVM
#
#   Overriden method that tells if a VM exists
#
# Parameters:
#
#   name - name of the libvirt domain
#
# Returns:
#
#   boolean - indicates if the VM exists
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub existsVM
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    my $out = `virsh desc '$name' | grep -c 'failed to get domain'`;
    chomp($out);

    return $out;
}

# Method: listVMs
#
#   Overridden method to list all the existing KVM VMs
#
# Returns:
#
#   list - names of all the VMs
#
sub listVMs
{
    # TODO: Use the identifier to filter
    return `virsh list 2>/dev/null | tail -n +3 | head -n -1 | awk '{ print \$2 }'`;
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
sub imageFile
{
    my ($self, $path, $name) = @_;

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    return "$path/$name/disk.qcow2";
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
sub createImageCopy
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
    my $configFile = "$path/$newname/domain.xml";
    my $config;

    # Generate the configuration
    $config = $self->_createImageConfig($newimage, "$path/$newname");

    # Writes the configuration file
    my $FILE;
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
sub deleteImage
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
sub createNetwork
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
sub destroyNetwork
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
    my $id = ANSTE::Status->instance()->identifier();
    while (my ($net, $num) = each %bridges) {
        $self->execute("virsh net-destroy anste-bridge$id$num");
        unlink("$path/anste-bridge$num.xml");
    }
}

# TODO
sub cleanNetwork
{
    my ($self, $id) = @_;

    my @bridges;
    if ($id) {
        @bridges = `virsh net-list 2>/dev/null | grep anste | grep $id | awk '{ print \$1 }'`;
    } else {
        @bridges = `virsh net-list 2>/dev/null | grep anste | awk '{ print \$1 }'`;
    }
    chomp (@bridges);
    foreach my $br (@bridges) {
        print "Destroying network $br...\n";
        system ("virsh net-destroy $br");
    }

    my @pids;
    if ($id) {
        @pids = `ps ax | grep dnsmasq | grep anste | grep $id | awk '{ print \$1 }'`;
    } else {
        @pids = `ps ax | grep dnsmasq | grep anste | awk '{ print \$1 }'`;
    }
    foreach my $pid (@pids) {
        system ("kill -9 $pid");
    }
}

sub _createImageConfig
{
    my ($self, $image, $path) = @_;

    my $config = ANSTE::Config->instance();
    my $name = $image->name();
    my $memory = $image->memory() * 1024;
    my $arch = `arch`;
    chomp ($arch);

    my $id = ANSTE::Status->instance()->identifier();

    my $imageConfig = "<domain type='kvm'>\n";
    $imageConfig .= "\t<name>$name</name>\n";
    $imageConfig .= "\t<memory>$memory</memory>\n";
    $imageConfig .= "\t<vcpu>1</vcpu>\n";
    $imageConfig .= "\t<os><type arch='$arch'>hvm</type></os>\n";
    $imageConfig .= "\t<features><acpi/></features>\n";
    $imageConfig .= "\t<clock sync='localtime'/>\n";
    $imageConfig .= "\t<on_poweroff>destroy</on_poweroff>\n";
    $imageConfig .= "\t<on_reboot>restart</on_reboot>\n";
    $imageConfig .= "\t<on_crash>restart</on_crash>\n";
    $imageConfig .= "\t<devices>\n";
    $imageConfig .= "\t\t<emulator>/usr/bin/kvm</emulator>\n";
    $imageConfig .= "\t\t<disk type='file' device='disk'>\n";
    $imageConfig .= "\t\t\t<driver name='qemu' type='qcow2' cache='unsafe'/>\n";
    $imageConfig .= "\t\t\t<source file='$path/disk.qcow2'/>\n";
    $imageConfig .= "\t\t\t<target dev='vda' bus='virtio'/>\n";
    $imageConfig .= "\t\t</disk>\n";
    foreach my $iface (@{$image->network()->interfaces()}) {
        $imageConfig .= "\t\t<interface type='bridge'>\n";
        my $bridge = $iface->bridge();
        my $mac = $iface->hwAddress();
        $imageConfig .= "\t\t\t<source bridge='${BRIDGE_PREFIX}${id}${bridge}'/>\n";
        $imageConfig .= "\t\t\t<mac address='$mac'/>\n";
        # Gigabit ethernet card to improve performance
        $imageConfig .= "\t\t\t<model type='virtio'/>\n";
        $imageConfig .= "\t\t</interface>\n";
    }
    $imageConfig .= "\t\t<graphics type='vnc' port='-1' autoport='yes' keymap='es'/>\n";
    $imageConfig .= "\t</devices>\n";
    $imageConfig .= "</domain>\n";

    return $imageConfig;
}

# FIXME: unhardcode this?
my $bridge_mac_prefix = '00:1F:3E:5D:C7';
my $mac_id = 80;

sub _createNetworkConfig
{
    my ($self, $net, $bridge) = @_;

    my $config = ANSTE::Config->instance();
    my $status = ANSTE::Status->instance();

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

    my $id = $status->identifier();

    my $networkConfig = "<network>\n";
    $networkConfig .= "\t<name>anste-bridge$id$bridge</name>\n";
    if ($forward) {
        $networkConfig .= "\t<bridge name=\"${BRIDGE_PREFIX}${id}${bridge}\" />\n";
        $networkConfig .= "\t<forward mode=\"nat\" />\n";
        $networkConfig .= "\t<ip address=\"$address\" netmask=\"$netmask\" />\n";
    } else {
        $networkConfig .= "\t<bridge name=\"${BRIDGE_PREFIX}${id}${bridge}\" stp=\"on\" delay=\"0\" />\n";
        $networkConfig .= "\t<mac address=\"$bridge_mac_prefix:$mac_id\" />\n";
        $mac_id++;
    }
    $networkConfig .= "</network>\n";

    return $networkConfig;
}

sub _networkForBaseImage
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

    $self->execute("virsh snapshot-create-as $domain $name '$description'") or
        throw ANSTE::Exceptions::Error("Error creating snapshot $name in domain $domain");
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

    $self->execute("virsh snapshot-revert $domain $name --force") or
        throw ANSTE::Exceptions::Error("Error reverting snapshot $name in domain $domain");
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

     $self->execute("virsh snapshot-delete $domain $name") or
        throw ANSTE::Exceptions::Error("Error deleting snapshot $name in domain $domain");
}

# Method: existsSnapshot
#
#   Override this method to tell if a snapshot exists
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub existsSnapshot
{
    my ($self, $domain, $name) = @_;

    my $out = `virsh snapshot-list $domain | grep -c ' $name '`;
    chomp($out);

    return $out;
}

1;

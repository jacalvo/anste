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

package ANSTE::Virtualizer::OpenStack;

use base 'ANSTE::Virtualizer::Virtualizer';

use strict;
use warnings;

use threads;
use threads::shared;

use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::MissingConfig;
use ANSTE::ScriptGen::HostPreInstallOS;
use Net::OpenStack::Compute;
use Net::OpenStack::Networking;
use MIME::Base64;

use File::Temp qw(tempfile tempdir);
use File::Slurp;

my %imageID: shared;
my $lockImageID: shared;

sub getImageID
{
    my ($self, $image) = @_;

    my $id;
    {
        lock($lockImageID);
        $id = $imageID{$image};
    }

    return $id;
}

sub setImageID
{
    my ($self, $image, $id) = @_;

    {
        lock($lockImageID);
        $imageID{$image} = $id;
    }
}

my %cloudInitFile: shared;
my $lockCloudInitFile: shared;

sub getCloudInitFile
{
    my ($self, $image) = @_;

    my $file;
    {
        lock($lockCloudInitFile);
        $file = $cloudInitFile{$image};
    }

    return $file;
}

sub setCloudInitFile
{
    my ($self, $image, $file) = @_;

    {
        lock($lockCloudInitFile);
        $cloudInitFile{$image} = $file;
    }
}

# Class: OpenStack
#
#   Implementation of the Virtualizer class that interacts with OpenStack
#

# Constructor: new
#
#   Constructor for Virtualizer class and his derivated classes.
#
# Returns:
#
#   A recently created <ANSTE::Virtualizer::Virtualizer> object
#
sub new
{
    my ($class) = @_;

    my $self = $class->SUPER::new();

    $self->{config} = ANSTE::Config->instance();
    $self->{status} = ANSTE::Status->instance();

    my $user = $self->{config}->_getOption('virtualizer', 'user');
    unless (defined $user) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/user');
    }

    my $password = $self->{config}->_getOption('virtualizer', 'password');
    unless (defined $password) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/password');
    }

    my $url = $self->{config}->_getOption('virtualizer', 'url');
    unless (defined $url) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/url');
    }
    my $project_id = $self->{config}->_getOption('virtualizer', 'project_id');
    unless (defined $project_id) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/project_id');
    }

    $self->{os_networking} = Net::OpenStack::Networking->new(
                                auth_url    => $url,
                                user        => $user,
                                password    => $password,
                                project_id  => $project_id,
                            );
    $self->{os_compute} = Net::OpenStack::Compute->new(
                                auth_url    => $url,
                                user        => $user,
                                password    => $password,
                                project_id  => $project_id,
                            );

    # Suffix for the elements created in OpenStack
    $self->{suffix} = $self->{config}->_getOption('virtualizer', 'suffix');
    unless ($self->{suffix}) {
        $self->{suffix} = $user;
    }

    bless($self, $class);

    return $self;
}

# FIXME: Remove
sub skipImageCreation
{
    return 1;
}

sub shutdownImage
{
}

sub destroyImage
{
}

# Method: preCreateVM
#
#   Overridden method to perform the necessary steps before the creation of
#   the Virtual Machine with OpenStack
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


    print "[$hostname] Updating hostname on the new image...\n";
    my $gen = new ANSTE::ScriptGen::HostPreInstallOS($image);
    # Generates the installation script on a temporary file
    my ($fh, $filename) = tempfile() or die "Can't create temporary file: $!";
    print "[$hostname] $filename\n";
    $gen->writeScript($fh);
    close($fh) or die "Can't close temporary file: $!";

    $self->setCloudInitFile($image->{name}, $filename);

    return 1;
}


# Method: createVM
#
#   Overridden method to create the Virtual Machine with OpenStack
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
sub createVM
{
    my ($self, $image, $host) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $status = $self->{status}->virtualizerStatus();
    my $networks = $status->{networks};

    my @netConf = ();
    foreach my $iface (@{$image->network()->interfaces()}) {
        my $bridge = $iface->bridge();

        my $net = {uuid => $networks->{$bridge},
                   fixed_ip => $iface->address()};
        push(@netConf, $net);
    }
    my $imageName = $host->baseImage()->name();
    my $images = $self->{os_compute}->get_images();

    my ($imageRef) = grep { $_->{name} eq $imageName } @$images;

    unless ($imageRef) {
        die "No image found with the name '$imageName'\n";;
    }

    my $serverName = $image->{name} . "-" . $self->{suffix};

    my $userData = undef;
    my $fileName = $self->getCloudInitFile($image->{name});
    if (defined $fileName) {
        my $rawUserData = read_file($fileName);
        $userData = encode_base64($rawUserData);
    }
    my $ret = $self->{os_compute}->create_server({name => $serverName,
                                        flavorRef => '2',           # TODO:Unhardcode
                                        imageRef => $imageRef->{id},
                                        networks => \@netConf,
                                        user_data => $userData,
                                    });
    my $id = $ret->{id};

    # Wait for the creation to finish
    do {
        sleep(1);
        $ret = $self->{os_compute}->get_server($id);
    } while ($ret->{status} eq 'BUILD');

    # TODO: Throw exception if status != ACTIVE ??

    $self->setImageID($image->{name}, $id);

    return (defined $id);
}

# Method: finishImageCreation
#
#   Overridden method to perform the necessary steps after the creation of
#   the Virtual Machine with OpenStack
#
#   Note: Must be called from within the main thread
#
# Parameters:
#
#   name - String name of the VM
#
sub finishImageCreation
{
    my ($self, $name) = @_;

    my $status = $self->{status}->virtualizerStatus();
    $status->{images}->{$name} = $self->getImageID($name);
    $self->{status}->setVirtualizerStatus($status);
}

#sub defineVM
#{
#    my ($self, $image) = @_;
    # FIXME
#    $self->createVM($image);
#}


sub startVM
{
    my ($self, $image, $host) = @_;

    return $self->createVM($image, $host);
}

sub existsVM
{
    # TODO: Look for the VM??
    return 1;
}

# Method: listVMs
#
#   Overridden method to list all the existing VMs in OpenStack
#
# Returns:
#
#   list - names of all the VMs
#
sub listVMs
{
    my ($self) = @_;

    my @server_names = ();
    my $servers = $self->{os_compute}->get_servers();
    my $suffix = $self->{suffix};

    for my $server (@$servers) {
        if ($server->{name} =~ m/.*-$suffix$/) {
            push(@server_names, $server->{name});
        }
    }

    return @server_names;
}

sub imageFile
{
    return '/bin/true';
}

# TODO: Remove
sub createImageCopy
{
    return 1;
}

# TODO: Change name
# Method: deleteImage
#
#   Overridden method to delete an image on OpenStack
#
# Parameters:
#
#   image   - name of the image to be deleted
#
# Returns:
#
#   boolean -   indicates if the process has been successful
#
sub deleteImage
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    my $status = $self->{status}->virtualizerStatus();
    my $id = $status->{images}->{$name};

    if($id) {
        $self->{os_compute}->delete_server($id);

        # Wait for the deletion to finish
        do {
            sleep(1);
        } while ($self->{os_compute}->get_server($id));
    }
}

# Method: createNetwork
#
#   Overridden method to do the stuff needed to set up
#   the network for a scenario on OpenStack
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

    my $external_router_id = $self->{config}->_getOption('virtualizer', 'external_router_id');

    my $status = {'networks' => {}};

    my $suffix = $self->{suffix};
    my %bridges = %{$scenario->bridges()};
    while (my ($net, $num) = each %bridges) {
        # Create network
        my $network = $self->{os_networking}->create_network({'name' => "anste$num-$suffix"});

        # Get configuration
        my $net_config = $self->_genNetConfig($network->{id}, $net, $num);
        my $subnet = $self->{os_networking}->create_subnet($net_config);

        $status->{networks}->{$num} = $network->{id};

        # Only the first network is connected to the external network (ANSTE communication network)
        if ($num == 1 and defined $external_router_id) {
            $status->{port} = $self->{os_networking}->add_router_interface($external_router_id, $subnet->{id});
        } else {
            # TODO: Throw exception
        }
    }
    $self->{status}->setVirtualizerStatus($status);
    return 1;
}

# Method: destroyNetwork
#
#   Overridden method to do the stuff needed to destroy
#   the network of a scenario on OpenStack
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

    my $status = $self->{status}->virtualizerStatus();
    my $external_router_id = $self->{config}->_getOption('virtualizer', 'external_router_id');

    if(defined $external_router_id) {
        $self->{os_networking}->remove_router_interface($external_router_id, $status->{port});
    }

    for my $net (values $status->{networks}) {
        $self->{os_networking}->delete_network($net);
    }
}

sub _genNetConfig
{
    my ($self, $netID, $net, $bridge) = @_;

    my $address;
    if ($bridge == 1) {
        $address = $self->{config}->gateway();
    } else {
        # FIXME: $net does not always contains a network address (manual-bridging)
        $address = ANSTE::Validate::ip($net) ? $net : "$net.254";
    }

    # Generate cidr
    my @addr_split = split('\.', $address);
    # FIXME: Unharcode the /24
    my $cidr = join('.', @addr_split[0..2]) . '.0/24';

    my $suffix = $self->{suffix};
    my $networkConfig = {'name'       => "anste_subnet$bridge-$suffix",
                         'network_id' => $netID,
                         'ip_version' => 4,
                         'enable_dhcp'=> 0,
                         'cidr'       => $cidr,
                         'gateway_ip' => $address};

    return $networkConfig;
}

# TODO: Remove
sub revertSnapshot
{
}

sub existsSnapshot
{
    return 1;
}

1;


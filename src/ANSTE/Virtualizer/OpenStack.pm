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

use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Exceptions::NotImplemented;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::MissingConfig;
use Net::OpenStack::Networking;

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

    bless($self, $class);

    return $self;
}

sub createBaseImage
{
}

sub shutdownImage
{
}

sub destroyImage
{
}

sub createVM
{
}

sub defineVM
{
}

sub startVM
{
}

sub removeVM
{
}

sub existsVM
{
}

sub imageFile
{
    return '/bin/true';
}

sub createImageCopy
{
}

sub deleteImage
{
}

# Method: createNetwork
#
#   Overridden method that .........TODO........ for the network of the given scenario.
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

    my $external_network_id = $self->{config}->_getOption('virtualizer', 'external_network_id');

    my $status = {'networks' => []};

    my %bridges = %{$scenario->bridges()};
    while (my ($net, $num) = each %bridges) {
        # Create network
        my $network = $self->{os_networking}->create_network({'name' => "anste$num"});

        # Get configuration
        my $net_config = $self->_genNetConfig($network->{id}, $net, $num);
        my $subnet = $self->{os_networking}->create_subnet($net_config);

        push(@{$status->{networks}}, $network->{id});

        # Only the first network is connected to the external network (ANSTE communication network)
        if ($num == 1 and defined $external_network_id) {
            my $router_config = { name => 'anste_router',
                                  external_gateway_info => {network_id => $external_network_id}
                                };
            my $router = $self->{os_networking}->create_router($router_config);
            $status->{router} = $router->{id};
            $status->{port} = $self->{os_networking}->add_router_interface($router->{id}, $subnet->{id});
        }
    }
    $self->{status}->setVirtualizerStatus($status);
    return 1;
}

# Method: destroyNetwork
#
#   Overridden method that destroy previously created ....TODO.... for the network of the given scenario.
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

    if( defined $status->{router} ) {
        $self->{os_networking}->remove_router_interface($status->{router}, $status->{port});
        $self->{os_networking}->delete_router($status->{router});
    }

    for my $net (@{$status->{networks}}) {
        $self->{os_networking}->delete_network($net);
    }
}

sub _genNetConfig
{
    my ($self, $netID, $net, $bridge) = @_;

    my $address;
    if ($bridge == 1) {
        $address = $self->{config}->gateway();
    }
    else {
        $address = ANSTE::Validate::ip($net) ? $net : "$net.254";
    }

    # Generate cidr
    my @addr_split = split('\.', $address);
    # FIXME: Unharcode the /24
    my $cidr = join('.', @addr_split[0..2]) . '.0/24';

    my $networkConfig = {'name'       => "anste_subnet$bridge",
                         'network_id' => $netID,
                         'ip_version' => 4,
                         'cidr'       => $cidr,
                         'gateway_ip' => $address};

    return $networkConfig;
}

1;


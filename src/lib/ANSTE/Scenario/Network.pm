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

package ANSTE::Scenario::Network;

use strict;
use warnings;

use ANSTE::Scenario::NetworkInterface;
use ANSTE::Scenario::NetworkRoute;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: Network
#
#   Contains the lists of network interfaces and routes for a host.
#

# Constructor: new
#
#   Constructor for Network class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::Network> object.
#
sub new # returns new Network object
{
    my ($class) = @_;
    my $self = {};

    $self->{interfaces} = [];
    $self->{routes} = [];
    $self->{bridges} = [];

    bless($self, $class);

    return $self;
}

# Method: interfaces
#
#   Gets the list of interfaces.
#
# Returns:
#
#   ref - list of <ANSTE::Scenario::NetworkInterface> objects
#
sub interfaces # returns interfaces list reference
{
    my ($self) = @_;

    return $self->{interfaces};
}

# Method: addInterface
#
#   Adds an interface object to the list.
#
# Parameters:
#
#   interface - <ANSTE::Scenario::NetworkInterface> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub addInterface # (interface)
{
    my ($self, $interface) = @_;

    defined $interface or
        throw ANSTE::Exceptions::MissingArgument('interface');

    if (not $interface->isa('ANSTE::Scenario::NetworkInterface')) {
        throw ANSTE::Exceptions::InvalidType('interface',
             'ANSTE::Scenario::NetworkInterface');
    }

    my $bridge = $interface->bridge();
    if (defined ($bridge)) {
        push (@{$self->{bridges}}, $bridge);
    }

    push(@{$self->{interfaces}}, $interface);
}

# Method: routes
#
#   Gets the list of routes.
#
# Returns:
#
#   ref - list of <ANSTE::Scenario::NetworkRoute> objects
#
sub routes # returns routes list reference
{
    my ($self) = @_;

    return $self->{routes};
}

# Method: addRoute
#
#   Adds a network route object to the list.
#
# Parameters:
#
#   route - <ANSTE::Scenario::NetworkRoute> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub addRoute # (route)
{
    my ($self, $route) = @_;

    defined $route or
        throw ANSTE::Exceptions::MissingArgument('route');

    if (not $route->isa('ANSTE::Scenario::NetworkRoute')) {
        throw ANSTE::Exceptions::InvalidType('route',
             'ANSTE::Scenario::NetworkRoute');
    }

    push(@{$self->{routes}}, $route);
}

sub bridges
{
    my ($self) = @_;

    return $self->{bridges};
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the network configuration into this object.
#
# Parameters:
#
#   node - <XML::DOM::Element> object containing the test data.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidType> - throw if parameter has wrong type
#
sub load # (node)
{
    my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                                             'XML::DOM::Element');
    }

    foreach my $element ($node->getElementsByTagName('interface', 0)) {
        my $interface = new ANSTE::Scenario::NetworkInterface();
        $interface->load($element);
        $self->addInterface($interface);
    }

    foreach my $element ($node->getElementsByTagName('route', 0)) {
        my $route = new ANSTE::Scenario::NetworkRoute();
        $route->load($element);
        $self->addRoute($route);
    }
}

sub loadYAML
{
    my ($self, $network) = @_;

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    foreach my $iface (@{$network->{interfaces}}) {
        my $interface = new ANSTE::Scenario::NetworkInterface();
        $interface->loadYAML($iface);
        $self->addInterface($interface);
    }

#FIXME
#    foreach my $element ($node->getElementsByTagName('route', 0)) {
#        my $route = new ANSTE::Scenario::NetworkRoute();
#        $route->load($element);
#        $self->addRoute($route);
#    }
}

1;

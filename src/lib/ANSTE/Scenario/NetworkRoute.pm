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

package ANSTE::Scenario::NetworkRoute;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidData;
use ANSTE::Validate;

# Class: NetworkRoute
#
#   Contains the information of a network route.
#

# Constructor: new
#
#   Constructor for NetworkRoute class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::NetworkRoute> object.
#
sub new # returns new NetworkRoute object
{
	my ($class) = @_;
	my $self = {};
	
	$self->{destination} = '';
	$self->{gateway} = '';
	$self->{netmask} = '';
	$self->{iface} = '';

	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the route destination.
#
# Returns:
#
#   string - contains the route destination string
#
sub destination # returns route destination string
{
	my ($self) = @_;

	return $self->{destination};
}

# Method: setDestination
#
#   Sets the route destination.
#
# Parameters:
#
#   destination - String with the destination of the route
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setDestination # (destination) 
{
	my ($self, $destination) = @_;	
    
    defined $destination or
        throw ANSTE::Exceptions::MissingArgument('destination');

	$self->{destination} = $destination;
}

# Method: gateway
#
#   Gets the route gateway.
#
# Returns:
#
#   string - contains the gateway of the route
#
sub gateway # returns gateway string
{
	my ($self) = @_;

	return $self->{gateway};
}

# Method: setGateway
#
#   Sets the route gateway.
#
# Parameters:
#
#   gateway - String with the gateway of the route.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setGateway # gateway string
{
	my ($self, $gateway) = @_;	

    defined $gateway or
        throw ANSTE::Exceptions::MissingArgument('gateway');

	$self->{gateway} = $gateway;
}

# Method: netmask
#
#   Gets the route network mask.
#
# Returns:
#
#   string - contains the network mask of the route
#
sub netmask # returns netmask string
{
	my ($self) = @_;

	return $self->{netmask};
}

# Method: setNetmask
#
#   Sets the route network mask.
#
# Parameters:
#
#   netmask - String with the network mask of the route.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setNetmask # netmask string
{
	my ($self, $netmask) = @_;	

    defined $netmask or
        throw ANSTE::Exceptions::MissingArgument('netmask');

    if (not ANSTE::Validate::ip($netmask)) {
        throw ANSTE::Exceptions::InvalidData('netmask', $netmask);
    }

	$self->{netmask} = $netmask;
}

# Method: iface
#
#   Gets the name of the outgoing network interface for the route.
#
# Returns:
#
#   string - contains the name of the interface
#
sub iface # returns iface string
{
	my ($self) = @_;

	return $self->{iface};
}

# Method: setIface
#
#   Sets the name of the outgoing network interface for the route.
#
# Parameters:
#
#   iface - String with the interface name.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setIface # iface string
{
	my ($self, $iface) = @_;	

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');

	$self->{iface} = $iface;
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the network route into this object.
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
        throw ANSTE::Exceptions::InvalidType('node', 'XML::DOM::Element');
    }

    my $destinationNode = 
        $node->getElementsByTagName('destination', 0)->item(0);
    my $destination = $destinationNode->getFirstChild()->getNodeValue();
    $self->setDestination($destination);

    my $gatewayNode = $node->getElementsByTagName('gateway', 0)->item(0);
    my $gateway = $gatewayNode->getFirstChild()->getNodeValue();
    $self->setGateway($gateway);

    my $netmaskNode = $node->getElementsByTagName('netmask', 0)->item(0);
    if ($netmaskNode) {
        my $netmask = $netmaskNode->getFirstChild()->getNodeValue();
        $self->setNetmask($netmask);
    }

    my $ifaceNode = $node->getElementsByTagName('iface', 0)->item(0);
    my $iface = $ifaceNode->getFirstChild()->getNodeValue();
    $self->setIface($iface);
}

1;

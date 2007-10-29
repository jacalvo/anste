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

package ANSTE::Scenario::NetworkInterface;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidData;
use ANSTE::Validate;

# Class: NetworkInterface
#
#   Contains the information of a network interface.
#

# Constant: IFACE_TYPE_STATIC
#   
#   Constant for the network interface type that indicates static
#   configuration.
#
use constant IFACE_TYPE_STATIC => 0;

# Constant: IFACE_TYPE_DHCP
#   
#   Constant for the network interface type that indicates dynamic
#   configuration.
#
use constant IFACE_TYPE_DHCP => 1;

# Constructor: new
#
#   Constructor for NetworkInterface class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::NetworkInterface> object.
#
sub new # returns new NetworkInterface object
{
	my ($class) = @_;
	my $self = {};
	
	$self->{type} = IFACE_TYPE_STATIC;
	$self->{name} = '';
	$self->{address} = '';
	$self->{hwAddress} = '';
	$self->{netmask} = '';
	$self->{gateway} = '';

	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the interface name.
#
# Returns:
#
#   string - contains the name of the interface
#
sub name # returns interface name string
{
	my ($self) = @_;

	return $self->{name};
}

# Method: setName
#
#   Sets the interface name.
#
# Parameters:
#
#   name - String with the name of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setName # (name) 
{
	my ($self, $name) = @_;	
    
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

# Method: type
#
#   Gets the interface type.
#
# Returns:
#
#   constant - IFACE_TYPE_STATIC or IFACE_TYPE_DHCP
#
sub type # returns interface type
{
	my ($self) = @_;

	return $self->{type};
}

# Method: setTypeStatic
#
#   Sets the interface type to static.
#
sub setTypeStatic
{
	my ($self) = @_;

	$self->{type} = IFACE_TYPE_STATIC;
}

# Method: setTypeDHCP
#
#   Sets the interface type to DHCP.
#
sub setTypeDHCP
{
	my ($self) = @_;

	$self->{type} = IFACE_TYPE_DHCP;
}

# Method: address
#
#   Gets the interface address.
#
# Returns:
#
#   string - the interface IP address
#
sub address # returns address string
{
	my ($self) = @_;

	return $self->{address};
}

# Method: setAddress
#
#   Sets the interface address.
#
# Parameters:
#
#   address - String with the IP address of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setAddress # address string
{
	my ($self, $address) = @_;	

    defined $address or
        throw ANSTE::Exceptions::MissingArgument('address');

    if (not ANSTE::Validate::ip($address)) {
        throw ANSTE::Exceptions::InvalidData('address', $address);
    }

	$self->{address} = $address;
}

# Method: hwAddress
#
#   Gets the interface hardware address.
#
# Returns:
#
#   string - the interface hardware address
#
sub hwAddress # returns address string
{
	my ($self) = @_;

	return $self->{hwAddress};
}

# Method: setHwAddress
#
#   Sets the interface hardware address.
#
# Parameters:
#
#   hwAddress - String with the hardware address of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setHwAddress # hardware address string
{
	my ($self, $hwAddress) = @_;	

    defined $hwAddress or
        throw ANSTE::Exceptions::MissingArgument('hwAddress');

    if (not ANSTE::Validate::mac($hwAddress)) {
        throw ANSTE::Exceptions::InvalidData('hwAddress', $hwAddress);
    }

	$self->{hwAddress} = $hwAddress;
}


# Method: netmask
#
#   Gets the interface network mask.
#
# Returns:
#
#   string - contains the network mask of the interface
#
sub netmask # returns netmask string
{
	my ($self) = @_;

	return $self->{netmask};
}

# Method: setNetmask
#
#   Sets the interface network mask.
#
# Parameters:
#
#   netmask - String with the network mask of the interface.
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

# Method: gateway
#
#   Gets the interface gateway.
#
# Returns:
#
#   string - contains the gateway of the interface
#
sub gateway # returns gateway string
{
	my ($self) = @_;

	return $self->{gateway};
}

# Method: setGateway
#
#   Sets the interface gateway.
#
# Parameters:
#
#   gateway - String with the gateway of the interface.
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

    if (not ANSTE::Validate::ip($gateway)) {
        throw ANSTE::Exceptions::InvalidData('gateway', $gateway);
    }

	$self->{gateway} = $gateway;
}

# Method: removeGateway
#
#   Remove the interface gateway.
#
sub removeGateway
{
    my ($self) = @_;

    $self->{gateway} = '';
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the network interface into this object.
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

	my $type = $node->getAttribute('type');
    my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
    my $name = $nameNode->getFirstChild()->getNodeValue();
    $self->setName($name);
	if ($type eq 'static') {
		$self->setTypeStatic();
		my $addressNode = $node->getElementsByTagName('address', 0)->item(0);
		my $address = $addressNode->getFirstChild()->getNodeValue();
		$self->setAddress($address);
		my $netmaskNode = $node->getElementsByTagName('netmask', 0)->item(0);
		my $netmask = $netmaskNode->getFirstChild()->getNodeValue();
		$self->setNetmask($netmask);
		my $gatewayNode = $node->getElementsByTagName('gateway', 0)->item(0);
        if ($gatewayNode) {
    		my $gateway = $gatewayNode->getFirstChild()->getNodeValue();
            $self->setGateway($gateway);
        }
		my $hwAddrNode = $node->getElementsByTagName('hw-addr', 0)->item(0);
        if ($hwAddrNode) {
    		my $hwAddress = $hwAddrNode->getFirstChild()->getNodeValue();
	    	$self->setHwAddress($hwAddress);
        }            
	} elsif ($type eq 'dhcp') {
		$self->setTypeDHCP();
	}
}

1;

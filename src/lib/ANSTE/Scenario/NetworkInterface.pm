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

# Constants 
use constant IFACE_TYPE_STATIC => 0;
use constant IFACE_TYPE_DHCP => 1;

# Constructor: new
# 
#       Construct a new NetworkInterface class.
# 
# Returns:
#
#       A recently created Scenario::NetworkInterface object
#
sub new # returns new NetworkInterface object
{
	my ($class) = @_;
	my $self = {};
	
	$self->{type} = IFACE_TYPE_STATIC;
	$self->{name} = '';
	$self->{address} = '';
	$self->{netmask} = '';
	$self->{gateway} = '';

	bless($self, $class);

	return $self;
}

sub name # returns interface name string
{
	my ($self) = @_;

	return $self->{name};
}

sub setName # (name) 
{
	my ($self, $name) = @_;	
    
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

sub type # returns interface type
{
	my ($self) = @_;

	return $self->{type};
}

sub setTypeStatic
{
	my ($self) = @_;

	$self->{type} = IFACE_TYPE_STATIC;
}

sub setTypeDHCP
{
	my ($self) = @_;

	$self->{type} = IFACE_TYPE_DHCP;
}

# Method: address
#
#   Get the interface address
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
#   Sets the interface address
#
# Parameters:
#
#   address - IP address
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

sub netmask # returns netmask string
{
	my ($self) = @_;

	return $self->{netmask};
}

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

sub gateway # returns gateway string
{
	my ($self) = @_;

	return $self->{gateway};
}

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

sub removeGateway
{
    my ($self) = @_;

    $self->{gateway} = '';
}

sub load # (node)
{
	my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                                             'XML::DOM::Element');
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
	} elsif ($type eq 'dhcp') {
		$self->setTypeDHCP();
	}
}

1;

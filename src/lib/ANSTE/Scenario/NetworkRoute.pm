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

# Constructor: new
# 
#       Construct a new NetworkRoute class.
# 
# Returns:
#
#       A recently created Scenario::NetworkRoute object
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

sub destination # returns interface destination string
{
	my ($self) = @_;

	return $self->{destination};
}

sub setDestination # (destination) 
{
	my ($self, $destination) = @_;	
    
    defined $destination or
        throw ANSTE::Exceptions::MissingArgument('destination');

	$self->{destination} = $destination;
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

	$self->{gateway} = $gateway;
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

sub iface # returns iface string
{
	my ($self) = @_;

	return $self->{iface};
}

sub setIface # iface string
{
	my ($self, $iface) = @_;	

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');

	$self->{iface} = $iface;
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

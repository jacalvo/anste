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

package ANSTE::Image::Image;

use base 'ANSTE::Scenario::BaseImage';

use strict;
use warnings;

use ANSTE::Scenario::Network;
use ANSTE::Scenario::NetworkInterface;
use ANSTE::Exceptions::MissingArgument;

# Class: Image
#
#   Extended <ANSTE::Scenario::BaseImage> adding information needed
#   for deployment like real hostname, ip address and memory size.
#

# Constructor: new
#
#   Constructor for Image class.
#
# Parameters:
#
#   name   - *optional* String with the image hostname.
#   ip     - *optional* String with the image IP address.
#   memory - *optional* String with the image memory size.
#
# Returns:
#
#   A recently created <ANSTE::Image::Image> object.
#
sub new # returns new Image object
{
	my ($class, %params) = @_;

	my $self = $class->SUPER::new();

    if (exists $params{name}) {
    	$self->{name} = $params{name};
    }
    if (exists $params{ip}) {
	    $self->{ip} = $params{ip};
    }
    if (exists $params{memory}) {
    	$self->{memory} = $params{memory}; 
    }

    $self->{network} = undef;

	bless($self, $class);

	return $self;
}

# Method: ip
#
#   Gets the image IP address.
#
# Returns:
#
#   string - contains the ip address
#
sub ip # returns ip string
{
	my ($self) = @_;

	return $self->{ip};
}

# Method: setIp
#
#   Sets the image IP address.
#
# Parameters:
#
#   ip - String with the image IP address.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setIp # ip string
{
	my ($self, $ip) = @_;

    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

	$self->{ip} = $ip;
}

# Method: memory
#
#   Gets the memory size string.
#
# Returns:
#
#   string - contains the memory size
#
sub memory # returns memory string 
{
	my ($self) = shift;

	return $self->{memory};
}

# Method: setMemory
#
#   Sets the memory size string.
#
# Parameters:
#
#   memory - String with the memory size.    
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setMemory # (memory)
{
	my ($self, $memory) = @_;

    defined $memory or
        throw ANSTE::Exceptions::MissingArgument('memory');

	$self->{memory} = $memory;
}

# Method: network
#
#   Returns the object with the network configuration of the image.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Network> object.
#
sub network # returns Network object
{
	my ($self) = @_;

	return $self->{network};
}

# Method: setNetwork
#
#   Sets the object with the network configuration of the image
#
# Parameters:
#
#   network - <ANSTE::Scenario::Network> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setNetwork # (network)
{
	my ($self, $network) = @_;	

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    if (not $network->isa('ANSTE::Scenario::Network')) {
        throw ANSTE::Exceptions::InvalidType('network',
                                             'ANSTE::Scenario::Network');
    }

	$self->{network} = $network;
}

# Method: commInterface
#
#   Returns the object representing the communication interface of the image.
#
# Returns:
#
#   ref - <ANSTE::Scenario::NetworkInterface> object.
#
sub commInterface 
{
    my ($self) = @_;
   
    my $ip = $self->{ip};

    my $iface = new ANSTE::Scenario::NetworkInterface();

    $iface->setName('eth0');
    $iface->setAddress($ip);
    $iface->setNetmask('255.255.255.0');
    my $gateway = ANSTE::Config->instance()->gateway();
    $iface->setGateway($gateway);

    return $iface;
}

1;

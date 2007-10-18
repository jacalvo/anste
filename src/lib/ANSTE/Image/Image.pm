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

# Constructor: new
#
#   Constructor for Image class.
#
# Parameters:
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub ip # returns ip string
{
	my ($self) = @_;

	return $self->{ip};
}

# Method: setIp
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub memory # returns memory string 
{
	my ($self) = shift;

	return $self->{memory};
}

# Method: setMemory
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub network # returns Network object
{
	my ($self) = @_;

	return $self->{network};
}

sub setNetwork # (network)
{
	my ($self, $network) = @_;	

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

	$self->{network} = $network;
}

# Method: commInterface
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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

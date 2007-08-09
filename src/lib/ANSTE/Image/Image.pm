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

use ANSTE::Exceptions::MissingArgument;

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

	bless($self, $class);

	return $self;
}

sub ip # returns ip string
{
	my ($self) = @_;

	return $self->{ip};
}

sub setIp # ip string
{
	my ($self, $ip) = @_;

    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

	$self->{ip} = $ip;
}

sub memory # returns memory string 
{
	my ($self) = shift;

	return $self->{memory};
}

sub setMemory # (memory)
{
	my ($self, $memory) = @_;

    defined $memory or
        throw ANSTE::Exceptions::MissingArgument('memory');

	$self->{memory} = $memory;
}

1;

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

package ANSTE::Deploy::Image;

use base 'ANSTE::Scenario::BaseImage';

use strict;
use warnings;

sub new # returns new Image object
{
	my ($class, %params) = @_;
	my $self = {};
	
	$self->{name} = $params{name};
	$self->{ip} = $params{ip};
	$self->{memory} = $params{memory}; 

	bless($self, $class);

	return $self;
}

sub ip # returns ip string
{
	my $self = shift;

	return $self->{ip};
}

sub setIp # ip string
{
	my $self = shift;	
	my $ip = shift;

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

	$self->{memory} = $memory;
}

1;

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

package ANSTE::Manager::Job;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;

sub new # (user, test) returns new Job object
{
	my ($class, $user, $test) = @_;
	my $self = {};
	
	$self->{test} = $test;

	bless($self, $class);

	return $self;
}

sub user # returns user string
{
	my ($self) = @_;

	return $self->{user};
}

sub setUser # user string
{
	my ($self, $user) = @_;	

    defined $user or
        throw ANSTE::Exceptions::MissingArgument('user');

	$self->{user} = $user;
}

sub test # returns test string
{
	my ($self) = @_;

	return $self->{test};
}

sub setTest # test string
{
	my ($self, $test) = @_;	

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

	$self->{test} = $test;
}

1;

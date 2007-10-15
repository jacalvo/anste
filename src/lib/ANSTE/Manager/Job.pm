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

use constant DEFAULT_PATH => 'anste';

my $id = 0;

sub new # (user, test) returns new Job object
{
	my ($class, $user, $test) = @_;
	my $self = {};
	
    $self->{id} = undef;
	$self->{user} = $user;
	$self->{test} = $test;
    $self->{path} = DEFAULT_PATH;
    $self->{failed} = 0;

    $self->{id} = ++$id;

	bless($self, $class);

	return $self;
}

sub id # returns id
{
	my ($self) = @_;

	return $self->{id};
}

sub user # returns user string
{
	my ($self) = @_;

	return $self->{user};
}

sub setUser # (user)
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

sub email # returns email string
{
	my ($self) = @_;

	return $self->{email};
}

sub setEmail # email string
{
	my ($self, $email) = @_;	

    defined $email or
        throw ANSTE::Exceptions::MissingArgument('email');

	$self->{email} = $email;
}

sub path # returns path string
{
	my ($self) = @_;

	return $self->{path};
}

sub setPath # path string
{
	my ($self, $path) = @_;	

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');

	$self->{path} = $path;
}

sub failed # returns boolean
{
	my ($self) = @_;

	return $self->{failed};
}

sub setFailed
{
	my ($self) = @_;	

	$self->{failed} = 1 
}

sub toStr # returns string
{
    my ($self) = @_;
	
    my $user = $self->{user};
	my $test = $self->{test};
	my $email = $self->{email};
	my $path = $self->{path};

    my $str = "$user";

    if ($email) {
        $str .= " ($email)";
    }

    $str .= ": $path/tests/$test";

    return $str;
}

1;

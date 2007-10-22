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

# Class: Job
#
#   Contains the information of a job.
#

use constant DEFAULT_PATH => 'anste';

my $id = 0;

# Constructor: new
#
#   Constructor for Job class.
#
# Parameters:
#
#   user - String with the user name.
#   test - String with the test name.
#
# Returns:
#
#   A recently created <ANSTE::Manager::Job> object.
#
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

# Method: id
#
#   Gets the job identificator.
#
# Returns:
#
#   string - contains the job identificator
#
sub id # returns id
{
	my ($self) = @_;

	return $self->{id};
}

# Method: user
#
#   Gets the user who sent the job.
#
# Returns:
#
#   string - contains the user name
#
sub user # returns user string
{
	my ($self) = @_;

	return $self->{user};
}

# Method: setUser
#
#   Sets the user who sent the job.
#
# Parameters:
#
#   user - String with the name of the user.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setUser # (user)
{
	my ($self, $user) = @_;	

    defined $user or
        throw ANSTE::Exceptions::MissingArgument('user');

	$self->{user} = $user;
}

# Method: test
#
#   Gets the name of the test that have to be executed.
#
# Returns:
#
#   string - contains the test name
#
sub test # returns test string
{
	my ($self) = @_;

	return $self->{test};
}

# Method: setTest
#
#   Sets the name of the test that have to be executed.
#
# Parameters:
#
#   test - String with the name of the test.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setTest # test string
{
	my ($self, $test) = @_;	

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

	$self->{test} = $test;
}

# Method: email
#
#   Gets the email where the user who sent the job wants to be notified.
#
# Returns:
#
#   string - contains the email address
#
sub email # returns email string
{
	my ($self) = @_;

	return $self->{email};
}

# Method: setEmail
#
#   Sets the email where the user who sent the job wants to be notified.
#
# Parameters:
#
#   email - String with the email address of the user.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setEmail # email string
{
	my ($self, $email) = @_;	

    defined $email or
        throw ANSTE::Exceptions::MissingArgument('email');

	$self->{email} = $email;
}

# Method: path
#
#   Gets the path of the user data (tests, scenarios, scripts, etc).
#
# Returns:
#
#   string - contains the path
#
sub path # returns path string
{
	my ($self) = @_;

	return $self->{path};
}

# Method: setPath
#
#   Sets the path of the user data (tests, scenarios, scripts, etc).
#
# Parameters:
#
#   path - String with the path of the user data, relative to his home.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setPath # path string
{
	my ($self, $path) = @_;	

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');

	$self->{path} = $path;
}

# Method: failed
#
#   Checks if the test has failed.
#
# Returns:
#
#   boolean - true if the test has failed, false if not
#
sub failed # returns boolean
{
	my ($self) = @_;

	return $self->{failed};
}

# Method: setFailed
#
#   Sets the test status as failed.
#
sub setFailed
{
	my ($self) = @_;	

	$self->{failed} = 1 
}

# Method: toStr
#
#   Gets the string representation of the job.
#
# Returns:
#
#   string - contains the user, test, and email
#
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

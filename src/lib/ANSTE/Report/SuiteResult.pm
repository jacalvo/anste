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

package ANSTE::Report::SuiteResult;

use strict;
use warnings;

use ANSTE::Test::Suite;
use ANSTE::Report::TestResult;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: SuiteResult
#
#   Contains the test results of a suite.
#

# Constructor: new
#
#   Constructor for SuiteResult class.
#
# Returns:
#
#   A recently created <ANSTE::Report::SuiteResult> object.
#
sub new # returns new SuiteResult object
{
	my ($class) = @_;
	my $self = {};

    $self->{suite} = '';
    $self->{tests} = [];

	bless($self, $class);

	return $self;
}

# Method: suite
#
#   Returns the suite object with the information of the test suite.
#
# Returns:
#
#   ref - <ANSTE::Test::Suite> object.
#
sub suite # returns suite string
{
	my ($self) = @_;

	return $self->{suite};
}

# Method: setSuite
#
#   Sets the suite object with the information of the test suite.
#
# Parameters:
#
#   suite - <ANSTE::Report::SuiteResult> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setSuite # (suite)
{
	my ($self, $suite) = @_;	

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    if (not $suite->isa('ANSTE::Test::Suite')) {
        throw ANSTE::Exceptions::InvalidType('suite',
                                             'ANSTE::Test::Suite');
    }

	$self->{suite} = $suite;
}

# Method: add
#
#   Add a test result to the suite result.
#
# Parameters:
#
#   test - <ANSTE::Report::TestResult> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub add # (test)
{
    my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    if (not $test->isa('ANSTE::Report::TestResult')) {
        throw ANSTE::Exceptions::InvalidType('test',
                                             'ANSTE::Report::TestResult');
    }

    push(@{$self->{tests}}, $test);
}

# Method: tests
#
#   Returns the list of test results.
#
# Returns:
#
#   ref - Reference to the list of <ANSTE::Report::TestResult>.
#
sub tests # returns list ref 
{
    my ($self) = @_;

    return $self->{tests};
}

# Method: value
#
#   Gets the value of the test suite (sumatory of test result values).
#
# Returns:
#
#   integer - result value
#
sub value # returns value
{
    my ($self) = @_;

    my $total = 0;

    foreach my $result (@{$self->{tests}}) {
        $total += $result->value();
    }

    return $total;
}

1;

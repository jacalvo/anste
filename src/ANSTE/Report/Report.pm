# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

package ANSTE::Report::Report;

use strict;
use warnings;

use ANSTE::Report::SuiteResult;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: Report
#
#   Contains the results of a set of test suites.
#

# Constructor: new
#
#   Constructor for Report class.
#
# Returns:
#
#   A recently created <ANSTE::Report::Report> object.
#
sub new # returns new Report object
{
	my ($class) = @_;
	my $self = {};

    $self->{suites} = [];
    $self->{time} = '';

	bless($self, $class);

	return $self;
}

# Method: add
#
#   Adds a suite result to the report.
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
sub add # (suite)
{
    my ($self, $suite) = @_;

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    if (not $suite->isa('ANSTE::Report::SuiteResult')) {
        throw ANSTE::Exceptions::InvalidType('suite',
                                             'ANSTE::Report::SuiteResult');
    }

    push(@{$self->{suites}}, $suite);
}

# Method: suites
#
#   Returns the list of suite results.
#
# Returns:
#
#   ref - Reference to the list of <ANSTE::Report::SuiteResult>.
#
sub suites # returns list ref
{
    my ($self) = @_;

    return $self->{suites};
}

# Method: time
#
#   Returns the time when the report was generated.
#
# Returns:
#
#   string - contains the date/time representation of the report generation
#
sub time # returns time
{
    my ($self) = @_;

    return $self->{time};
}

# Method: setTime
#
#   Sets the time when the report was generated.
#
# Parameters:
#
#   time - String with the date/time representation of the report generation.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setTime # (time)
{
    my ($self, $time) = @_;

    defined $time or
        throw ANSTE::Exceptions::MissingArgument('time');

    $self->{time} = $time;        
}

1;

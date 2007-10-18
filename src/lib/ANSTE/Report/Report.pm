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

package ANSTE::Report::Report;

use strict;
use warnings;

use ANSTE::Report::SuiteResult;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Constructor: new
#
#   Constructor for Report class.
#
# Parameters:
#
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

	bless($self, $class);

	return $self;
}

# Method: add
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
sub suites # returns list ref
{
    my ($self) = @_;

    return $self->{suites};
}

1;

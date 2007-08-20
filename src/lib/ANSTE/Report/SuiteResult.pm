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

use ANSTE::Report::TestResult;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

sub new # returns new SuiteResult object
{
	my ($class) = @_;
	my $self = {};

    $self->{name} = '';
    $self->{tests} = [];

	bless($self, $class);

	return $self;
}

sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

sub setName # name string
{
	my ($self, $name) = @_;	

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

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

sub tests # returns list ref 
{
    my ($self) = @_;

    return $self->{tests};
}

1;

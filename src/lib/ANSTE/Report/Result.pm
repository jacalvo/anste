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

package ANSTE::Report::Result;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;

sub new # returns new Result object
{
	my ($class) = @_;
	my $self = {};

    $self->{result} = {};

	bless($self, $class);

	return $self;
}

sub add # (suite, test, result)
{
    my ($self, $suite, $test, $result) = @_;

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');
    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');
    defined $result or
        throw ANSTE::Exceptions::MissingArgument('result');

    $self->{result}->{$suite}{$test} = $result;        
}

sub get # returns hash ref {suite}{test} = result
{
    my ($self) = @_;

    return $self->{result};
}

1;

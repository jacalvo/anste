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

package ANSTE::Report::TextWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::NotImplemented;

# TODO: Copy NaturalDocs comments from HTMLWriter :)

sub writeHeader 
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "Beginning test report\n\n";
}    

sub writeEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "Ending test report\n";
}    

sub writeSuiteHeader # (suite)
{
    my ($self, $suite) = @_;

    my $file = $self->{file};

    print $file "\t$suite\n";
}    

sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "\n";
}    

# Parameters: 
# name
# value
sub writeTestResult # (%params)
{
    my ($self, %params) = @_;

    my $name = $params{name};
    my $result = $params{value};

    my $file = $self->{file};

    my $resultStr = $result == 0 ? 'OK' : 'ERROR';

    print $file "\t\t$name: $resultStr\n";
}    

1;

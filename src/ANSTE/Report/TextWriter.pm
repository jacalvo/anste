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

package ANSTE::Report::TextWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

# Class: TextWriter
#
#   Implementation of class Writer for writing reports in plain text format.
#

# Method: writeHeader
#
#   Overriden method that writes the header of the report.
#
sub writeHeader 
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "Beginning test report\n\n";
}    

# Method: writeEnd
#
#   Overriden method that writes the end of the report.
#
sub writeEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "Ending test report\n";
}    

# Method: writeSuiteHeader
#
#   Overriden method that writes the header of a suite result.
#
# Parameters:
#
#   name - String with the suite name.
#
sub writeSuiteHeader # (name)
{
    my ($self, $name) = @_;

    my $file = $self->{file};

    print $file "\t$name\n";
}    

# Method: writeSuiteEnd
#
#   Overriden method that writes the end of a suite result.
#
sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "\n";
}    

# Method: writeTestResult
#
#   Overriden method that writes a test result.
#
# Parameters:
#
#   name  - String with the test name.
#   value - String with the test result value.
#
sub writeTestResult # (%params)
{
    my ($self, %params) = @_;

    my $name = $params{name};
    my $result = $params{value};

    my $file = $self->{file};

    my $resultStr = $result == 0 ? 'OK' : 'ERROR';

    print $file "\t\t$name: $resultStr\n";
}    

# Method: filename
#
#   Overriden method that returns the name of the file for the text report.
#
# Returns:
#
#   string - contains the name of the file
#
sub filename
{
    my ($self) = @_;

    return 'anste-report.txt';
}    

1;

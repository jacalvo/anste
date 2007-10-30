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

package ANSTE::Report::XMLWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

# Class: XMLWriter
#
#   Implementation of class Writer for writing reports in XML format.
#

# Method: writeHeader
#
#   Overriden method that writes the header of the report in XML.
#
sub writeHeader 
{
    my ($self) = @_;

    my $file = $self->{file};
    my $time = $self->{report}->time();

    print $file "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print $file "<report>\n";
    print $file "<title>ANSTE Test report</title>\n";
    print $file "<time>$time</time>\n";
}    

# Method: writeEnd
#
#   Overriden method that writes the end of the report in XML.
#
sub writeEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</title>\n";
}    

# Method: writeSuiteHeader
#
#   Overriden method that writes the header of a suite result in XML.
#
# Parameters:
#
#   name - String with the suite name.
#   desc - String with the suite description.
#
sub writeSuiteHeader # (name, desc)
{
    my ($self, $name, $desc) = @_;

    my $file = $self->{file};

    print $file "<suite>\n";
    print $file "<name>$name</name>\n";
    print $file "<desc>$desc</desc>\n";
}    

# Method: writeSuiteEnd
#
#   Overriden method that writes the end of a suite result in XML.
#
sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</suite>\n";
}    

# Method: writeTestResult
#
#   Overriden method that writes a test result in XML.
#
# Parameters:
#
#   name  - String with the test name.
#   value - String with the test result value.
#   desc  - *optional* String with the test description.
#   log   - *optional* String with the log path.
#   video - *optional* String with the video path.
#
sub writeTestResult # (%params)
{
    my ($self, %params) = @_;

    my $name = $params{name};
    my $desc = $params{desc};
    my $result = $params{value};
    my $file = $params{log};
    my $video = $params{video};

    my $filehandle = $self->{file};

    print $filehandle "<test>\n";

    print $filehandle "<name>$name</name>\n";

    if ($desc) {
        print $filehandle "<desc>$desc</desc>\n";
    }        

    my $resultStr = $result == 0 ? 'OK' : 'ERROR';
    print $filehandle "<result>$resultStr</result>\n";

    if ($file) {
        print $filehandle "<log>$file</log>\n";
    }        

    if ($video) {
        print $filehandle "<video>$video</video>\n";
    }

    print $filehandle "</test>\n";
}    

# Method: filename
#
#   Overriden method that returns the name of the file for the XML report.
#
# Returns:
#
#   string - contains the name of the file
#
sub filename
{
    my ($self) = @_;

    return 'report.xml';
}    

1;

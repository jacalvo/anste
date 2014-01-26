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

package ANSTE::Report::SimpleHTMLWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

# Class: SimpleHTMLWriter
#
#   Implementation of class Writer for writing reports in HTML format.
#

# Method: writeHeader
#
#   Overriden method that writes the header of the report in HTML.
#
sub writeHeader
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "<html>\n";
    print $file "<head>\n";
    print $file "<title>ANSTE Test report</title>\n";
    print $file "</head>\n";
    print $file "<body>\n";
    print $file "<h1>ANSTE Test report</h1>\n";
}

# Method: writeEnd
#
#   Overriden method that writes the end of the report in HTML.
#
sub writeEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    my $time = $self->{report}->time();

    print $file "<p><i>Report generated at $time</i></p>\n";
    my $user = getlogin() || getpwuid($<);
    print $file "<p><i>User: $user</i></p>\n";

    print $file "</body>\n";
    print $file "</html>\n";
}

# Method: writeSuiteHeader
#
#   Overriden method that writes the header of a suite result in HTML.
#
# Parameters:
#
#   name - String with the suite name.
#   desc - String with the suite description.
#
sub writeSuiteHeader
{
    my ($self, $name, $desc) = @_;

    my $file = $self->{file};

    print $file "<h2>$name</h2>\n";
    print $file "<h3>$desc</h3>\n";
    print $file "<table border='1' width='100%'>\n";
    print $file "<th><tr>\n";
    print $file "<td>Test</td>\n";
    print $file "<td>Description</td>\n";
    print $file "<td>Result</td>\n";
    print $file "</tr></th>\n";
}

# Method: writeSuiteEnd
#
#   Overriden method that writes the end of a suite result in HTML.
#
sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</table>\n";
}

# Method: writeTestResult
#
#   Overriden method that writes a test result in HTML.
#
# Parameters:
#
#   name   - String with the test name.
#   value  - String with the test result value.
#   desc   - *optional* String with the test description.
#   log    - *optional* String with the log path.
#   video  - *optional* String with the video path.
#   script - *optional* String with the script path.
#
sub writeTestResult
{
    my ($self, %params) = @_;

    my $name = $params{name};
    my $desc = $params{desc};
    my $result = $params{value};
    my $file = $params{log};
    my $video = $params{video};
    my $script = $params{script};

    my $filehandle = $self->{file};

    my $resultStr = $result == 0 ? "<font color='#00FF00'>OK</font>" :
                                   "<font color='#FF0000'>ERROR</font>";
    if ($file) {
        $resultStr = "<a href=\"$file\">" . $resultStr . "</a>";
    }

    if ($video) {
        $resultStr .= " (<a href=\"$video\">video</a>)";
    }
    if ($script) {
        $resultStr .= " (<a href=\"$script\">script</a>)";
    }

    if (not $desc) {
        $desc = '&nbsp;';
    }

    print $filehandle "<tr>\n" .
                      "<td>$name</td>\n" .
                      "<td>$desc</td>\n" .
                      "<td>$resultStr</td>\n" .
                      "</tr>\n";
}

# Method: filename
#
#   Overriden method that returns the name of the file for the HTML report.
#
# Returns:
#
#   string - contains the name of the file
#
sub filename
{
    my ($self) = @_;

    return 'index.html';
}

1;

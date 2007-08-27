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

package ANSTE::Report::HTMLWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::NotImplemented;

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

sub writeEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</body>\n";
    print $file "</html>\n";
}    

sub writeSuiteHeader # (name, desc)
{
    my ($self, $name, $desc) = @_;

    my $file = $self->{file};

    print $file "<h2>$name</h2>\n";
    print $file "<h3>$desc</h3>\n";
    print $file "<table border='1'>\n";
    print $file "<th><tr>\n";
    print $file "<td>Test</td>\n";
    print $file "<td>Description</td>\n";
    print $file "<td>Result</td>\n";
    print $file "</tr></th>\n";
}    

sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</table>\n";
}    

# TODO: named parameters
# Parameters:
# name
# desc
# value
# log
# video
sub writeTestResult # (%params)
{
    my ($self, %params) = @_;

    my $name = $params{name};
    my $desc = $params{desc};
    my $result = $params{value};
    my $file = $params{log};
    my $video = $params{video};

    my $filehandle = $self->{file};

    my $resultStr = $result == 0 ? "<font color='#00FF00'>OK</font>" : 
                                   "<font color='#FF0000'>ERROR</font>";
    if ($file) {
        $resultStr = "<a href=\"$file\">" . $resultStr . "</a>";
    }        

    if ($video) {
        $resultStr .= " (<a href=\"$video\">video</a>)";
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

1;

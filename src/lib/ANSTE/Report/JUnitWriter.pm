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

package ANSTE::Report::JUnitWriter;

use base 'ANSTE::Report::Writer';

use strict;
use warnings;

use File::Basename;

# Class: JUnitWriter
#
#   Implementation of class Writer for writing reports in JUnit format.
#

# Method: write
#
#   Overriden method that writes a report index to the given file and
#   a set of aditional files for each test suite.
#
# Parameters:
#
#   filename - In this case is not a file but a directory.
#
sub write # (file) 
{
    my ($self, $dir) = @_;

    my $report = $self->{report};
    foreach my $suite (@{$report->suites()}) {
        my $name = $suite->suite()->dir();
        $name =~ s{/}{-}g;
        my $reportFile = "$dir/$name.xml";
        $self->_writeSuiteFile($suite, $reportFile);
    }
}

# Method: writeSuiteHeader
#
#   Overriden method that writes the header of a suite result in JUnit XML.
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

    print $file "<testsuite name=\"$name\">\n";
    print $file "<desc>$desc</desc>\n";
}    

# Method: writeSuiteEnd
#
#   Overriden method that writes the end of a suite result in JUnit XML.
#
sub writeSuiteEnd
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "</testsuite>\n";
}    

sub _writeSuiteFile # (suite, file)
{
    my ($self, $suite, $file) = @_;

    my $FILE;
    open($FILE, '>', $file)
        or die "Can't write file $file: $!";

    $self->{file} = $FILE;

    my $name = $suite->suite()->name();
    my $desc = $suite->suite()->desc();
    $self->writeSuiteHeader($name, $desc);
    foreach my $test (@{$suite->tests()}) {
        $name = $test->test()->name();
        $desc = $test->test()->desc();
        my $video = $test->video();
        if ($video) {
            $video = 'video/' . basename($video);
        }
        $self->writeTestResult(name => $name,
                desc => $desc,
                value => $test->value(),
                log => basename($test->log()),
                video => $video);
    }
    $self->writeSuiteEnd();

    close($FILE);
}

# Method: writeTestResult
#
#   Overriden method that writes a test result in JUnit XML.
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

    print $filehandle "<testcase classname=\"$name\">\n";

#    if ($desc) {
#        print $filehandle "<desc>$desc</desc>\n";
#    }        

    if ($result != 0) {
        print $filehandle "<failure/>\n";
    }        

#    if ($file) {
#        print $filehandle "<log>$file</log>\n";
#    }        

#    if ($video) {
#        print $filehandle "<video>$video</video>\n";
#    }

    print $filehandle "</testcase>\n";
}    

# Method: filename
#
#   Overriden method that returns the name of the file for the XML report.
#
# Returns:
#
#   string - contains the name of the file (unused)
#
sub filename
{
    my ($self) = @_;

    return '';
}    

1;

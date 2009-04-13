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

use base 'ANSTE::Report::SimpleHTMLWriter';

use strict;
use warnings;

use File::Basename;

# Class: HTMLWriter
#
#   Implementation of class Writer for writing reports in HTML format.
#

# Method: write
#
#   Overriden method that writes a report index to the given file and
#   a set of aditional files for each test suite.
#
# Parameters:
#
#   file - String with the file name.
#
sub write # (file) 
{
    my ($self, $file) = @_;

    if (ref($file)) {
        die "HTML reports couldn't be written to a file descriptor";
    }

    my $FILE;
    open($FILE, '>', $file);
    $self->{file} = $FILE;

    $self->writeHeader();
    $self->_writeReportHeader();

    my $report = $self->{report};
    foreach my $suite (@{$report->suites()}) {
        my $dir = dirname($file);
        my $suiteDir = $suite->suite()->dir();
        my $reportFile = "$dir/$suiteDir/index.html";

        $self->_writeSuiteFile($suite, $reportFile);

        $self->{file} = $FILE;
        $self->_writeSuiteLink($suite);
    }

    $self->writeSuiteEnd();
    $self->writeEnd();

    close($FILE);
}

sub _writeSuiteFile # (suite, file)
{
    my ($self, $suite, $file) = @_;

    my $FILE;
    open($FILE, '>', $file);

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
        my $script = $test->script();
        if ($script) {
            $script = 'script/' . basename($script);
        }
        $self->writeTestResult(name => $name,
                desc => $desc,
                value => $test->value(),
                log => basename($test->log()),
                script => $script,
                video => $video);
    }
    $self->writeSuiteEnd();

    close($FILE);
}

sub _writeReportHeader
{
    my ($self) = @_;

    my $file = $self->{file};

    print $file "<table border='1' width='100%'>\n";
    print $file "<th><tr>\n";
    print $file "<td>Suite</td>\n";
    print $file "<td>Description</td>\n";
    print $file "<td>Result</td>\n";
    print $file "</tr></th>\n";
}    

sub _writeSuiteLink # (suite)
{
    my ($self, $suite) = @_;

    my $name = $suite->suite()->name();
    my $desc = $suite->suite()->desc();
    my $result = $suite->value();
    my $file = $suite->suite()->dir() . '/index.html';

    my $filehandle = $self->{file};

    my $resultStr = $result == 0 ? "<font color='#00FF00'>OK</font>" : 
                                   "<font color='#FF0000'>ERROR</font>";
    my $linkStr = "<a href=\"$file\">" . $name . "</a>";

    if (not $desc) {
        $desc = '&nbsp;';
    }

    print $filehandle "<tr>\n" . 
                      "<td>$linkStr</td>\n" .
                      "<td>$desc</td>\n" .
                      "<td>$resultStr</td>\n" .
                      "</tr>\n";
}    

1;

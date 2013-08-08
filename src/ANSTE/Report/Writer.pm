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

package ANSTE::Report::Writer;

use strict;
use warnings;

use ANSTE::Report::Report;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::NotImplemented;

# Class: Writer
#
#   Abstract class for writing reports in different formats.
#

# Constructor: new
#
#   Constructor for Writer class.
#
# Parameters:
#   
#   report - <ANSTE::Report::Report> object.
#
# Returns:
#
#   A recently created <ANSTE::Report::Writer> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub new # (report) returns new Write object
{
	my ($class, $report) = @_;
	my $self = {};

    defined $report or
        throw ANSTE::Exceptions::MissingArgument('report');

    $self->{report} = $report;
    $self->{file} = undef;

	bless($self, $class);

	return $self;
}

# Method: write
#
#   Writes the report to the given file.
#
# Parameters:
#
#   file - String with the file name or an opened file descriptor.
#
sub write # (file) 
{
    my ($self, $file) = @_;

    my $needClose = 0;

    if (ref($file)) {
        $self->{file} = $file;
    }
    else {
        $needClose = 1;
        open($self->{file}, '>', $file);
    }

    $self->writeHeader();

    my $report = $self->{report};

    foreach my $suite (@{$report->suites()}) {
        my $name = $suite->suite()->name();
        my $desc = $suite->suite()->desc();
        $self->writeSuiteHeader($name, $desc);
        foreach my $test (@{$suite->tests()}) {
            $name = $test->test()->name();
            $desc = $test->test()->desc();
            $self->writeTestResult(name => $name,
                                   desc => $desc,
                                   value => $test->value(),
                                   log => $test->log(),
                                   video => $test->video());
        }
        $self->writeSuiteEnd();
    }

    $self->writeEnd();

    if ($needClose) {
        close($self->{file});
    }
}

# Method: writeHeader
#
#   Override this method to write the header of the report.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub writeHeader
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Method: writeEnd
#
#   Override this method to write the end of the report.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub writeEnd
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Method: writeSuiteHeader
#
#   Override this method to write the header of a suite result.
#
# Parameters:
#
#   name - String with the suite name.
#   desc - *optional* String with the suite description.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub writeSuiteHeader # (name, desc)
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Method: writeSuiteEnd
#
#   Override this method to write the end of a suite result.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub writeSuiteEnd
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Method: writeTestResult
#
#   Override this method to write a test result.
#
# Parameters:
#
#   name  - String with the test name.
#   value - String with the test result value.
#   desc  - *optional* String with the test description.
#   log   - *optional* String with the log path.
#   video - *optional* String with the video path.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub writeTestResult # (%params)
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Method: filename
#
#   Override this method to return the name of the file to be used.
#
# Exceptions:
#
#   throw <ANSTE::Exceptions::NotImplemented>
#
sub filename
{
    throw ANSTE::Exceptions::NotImplemented();
}    

1;

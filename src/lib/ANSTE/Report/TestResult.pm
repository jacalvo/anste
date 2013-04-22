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

package ANSTE::Report::TestResult;

use strict;
use warnings;

use ANSTE::Test::Test;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: TestResult
#
#   Contains the result of a test.
#

# Constructor: new
#
#   Constructor for TestResult class.
#
# Returns:
#
#   A recently created <ANSTE::Report::TestResult> object.
#
sub new # returns new TestResult object
{
	my ($class) = @_;
	my $self = {};

    $self->{test} = undef;
    $self->{value} = undef;
    $self->{log} = undef;
    $self->{video} = undef;
    $self->{script} = undef;
    $self->{startTime} = undef;
    $self->{endTime} = undef;
    $self->{duration} = undef;

	bless($self, $class);

	return $self;
}

# Method: test
#
#   Returns the test object with the information of the test.
#
# Returns:
#
#   ref - <ANSTE::Test::Test> object.
#
sub test # returns test string
{
	my ($self) = @_;

	return $self->{test};
}

# Method: setTest
#
#   Sets the test object with the information of the test.
#
# Parameters:
#
#   test - <ANSTE::Test::Test> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setTest # test string
{
	my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    if (not $test->isa('ANSTE::Test::Test')) {
        throw ANSTE::Exceptions::InvalidType('test',
                                             'ANSTE::Test::Test');
    }

	$self->{test} = $test;
}

# Method: value
#
#   Gets the value of the test result.
#
# Returns:
#
#   integer - result value
#
sub value # returns value
{
    my ($self) = @_;

    return $self->{value};
}

# Method: setValue
#
#   Sets the value of the test result.
#
# Parameters:
#
#   value - Integer with the result value.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setValue # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    $self->{value} = $value;
}

# Method: log
#
#   Returns the path of the execution log for the test.
#
# Returns:
#
#   string - contains the path of the execution log
#
sub log # returns log
{
    my ($self) = @_;

    return $self->{log};
}

# Method: setLog
#
#   Sets the path of the execution log for the test.
#
# Parameters:
#
#   log - String with the path of the execution log.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setLog # (log)
{
    my ($self, $log) = @_;

    defined $log or
        throw ANSTE::Exceptions::MissingArgument('log');

    $self->{log} = $log;
}

# Method: script
#
#   Returns the path of the execution script for the test.
#
# Returns:
#
#   string - contains the path of the execution script
#
sub script # returns script
{
    my ($self) = @_;

    return $self->{script};
}

# Method: setScript
#
#   Sets the path of the script executed for the test.
#
# Parameters:
#
#   script - String with the path of the script executed.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setScript # (script)
{
    my ($self, $script) = @_;

    defined $script or
        throw ANSTE::Exceptions::MissingArgument('script');

    $self->{script} = $script;
}

# Method: video
#
#   Returns the path of the video record of the test execution.
#
# Returns:
#
#   string - contains the path of the video record
#
sub video # returns video
{
    my ($self) = @_;

    return $self->{video};
}

# Method: setVideo
#
#   Sets the path of the video record of the test execution.
#
# Parameters:
#
#   video - String with the path of the video record.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setVideo # (video)
{
    my ($self, $video) = @_;

    defined $video or
        throw ANSTE::Exceptions::MissingArgument('video');

    $self->{video} = $video;
}

# Method: startTime
#
#   Returns the time when the test started.
#
# Returns:
#
#   string - contains the date/time representation of the test start
#
sub startTime # returns startTime
{
    my ($self) = @_;

    return $self->{startTime};
}

# Method: setStartTime
#
#   Sets the time when the test started.
#
# Parameters:
#
#   startTime - String with the date/time representation of the test start.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setStartTime # (startTime)
{
    my ($self, $startTime) = @_;

    defined $startTime or
        throw ANSTE::Exceptions::MissingArgument('startTime');

    $self->{startTime} = $startTime;
}

# Method: endTime
#
#   Returns the time when the test ended.
#
# Returns:
#
#   string - contains the date/time representation of the test end
#
sub endTime # returns endTime
{
    my ($self) = @_;

    return $self->{endTime};
}

# Method: setEndTime
#
#   Sets the time when the test ended.
#
# Parameters:
#
#   endTime - String with the date/time representation of the test end.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setEndTime # (endTime)
{
    my ($self, $endTime) = @_;

    defined $endTime or
        throw ANSTE::Exceptions::MissingArgument('endTime');

    $self->{endTime} = $endTime;
}

# Method: duration
#
#   Returns the duration of the test
#
# Returns:
#
#   float - duration in seconds
#
sub duration
{
    my ($self) = @_;

    return $self->{duration};
}

# Method: setDuration
#
#   Sets the duration of the test
#
# Parameters:
#
#   duration - float in seconds.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub setDuration
{
    my ($self, $duration) = @_;

    defined $duration or
        throw ANSTE::Exceptions::MissingArgument('duration');

    $self->{duration} = $duration;
}

1;

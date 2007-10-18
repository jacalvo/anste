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

package ANSTE::Report::TestResult;

use strict;
use warnings;

use ANSTE::Test::Test;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Constructor: new
#
#   Constructor for TestResult class.
#
# Parameters:
#
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

	bless($self, $class);

	return $self;
}

# Method: test
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub test # returns test string
{
	my ($self) = @_;

	return $self->{test};
}

# Method: setTest
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub value # returns value
{
    my ($self) = @_;

    return $self->{value};
}

# Method: setValue
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub log # returns log
{
    my ($self) = @_;

    return $self->{log};
}

# Method: setLog
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub setLog # (log)
{
    my ($self, $log) = @_;

    defined $log or
        throw ANSTE::Exceptions::MissingArgument('log');

    $self->{log} = $log;        
}

# Method: video
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub video # returns video
{
    my ($self) = @_;

    return $self->{video};
}

# Method: setVideo
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub setVideo # (video)
{
    my ($self, $video) = @_;

    defined $video or
        throw ANSTE::Exceptions::MissingArgument('video');

    $self->{video} = $video;        
}

1;

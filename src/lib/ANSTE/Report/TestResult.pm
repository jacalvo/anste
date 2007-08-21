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

use ANSTE::Exceptions::MissingArgument;

sub new # returns new TestResult object
{
	my ($class) = @_;
	my $self = {};

    $self->{name} = '';
    $self->{value} = undef;
    $self->{log} = undef;
    $self->{video} = undef;

	bless($self, $class);

	return $self;
}

sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

sub setName # name string
{
	my ($self, $name) = @_;	

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

sub value # returns value
{
    my ($self) = @_;

    return $self->{value};
}

sub setValue # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    $self->{value} = $value;        
}

sub log # returns log
{
    my ($self) = @_;

    return $self->{log};
}

sub setLog # (log)
{
    my ($self, $log) = @_;

    defined $log or
        throw ANSTE::Exceptions::MissingArgument('log');

    $self->{log} = $log;        
}

sub video # returns video
{
    my ($self) = @_;

    return $self->{video};
}

sub setVideo # (video)
{
    my ($self, $video) = @_;

    defined $video or
        throw ANSTE::Exceptions::MissingArgument('video');

    $self->{video} = $video;        
}

1;

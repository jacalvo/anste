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

package ANSTE::Manager::Queue;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;

sub new # () returns new Queue object
{
	my ($class) = @_;
	my $self = {};
	
	$self->{list} = [];

	bless($self, $class);

	return $self;
}

# Extracts the new job from the queue
sub nextJob # returns job
{
	my ($self) = @_;

    my $job = shift @{$self->{list}};

	return $job;
}

sub addJob # (job)
{
	my ($self, $job) = @_;	

    defined $user or
        throw ANSTE::Exceptions::MissingArgument('job');

	push(@{$self->{list}}, $job);
}

1;

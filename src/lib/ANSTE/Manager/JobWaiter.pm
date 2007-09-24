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

package ANSTE::Manager::JobWaiter;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Exceptions::MissingArgument;

use threads;
use threads::shared;
use FreezeThaw qw(freeze thaw);

# Class: JobWaiter

my $singleton;

my $lock : shared;
my @queue : shared;

sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        #$self->{queue} = new Thread::Queue();

        $singleton = bless($self, $class);
    }

    return $singleton;
}

sub jobReceived # (job)
{
    my ($self, $job) = @_; 

    defined $job or
        throw ANSTE::Exceptions::MissingArgument('job');

    my $queue = $self->{queue};

    lock($lock);
    my $str = freeze($job);
    push(@queue, $str);
    cond_signal($lock);
}

sub waitForJob # returns job
{
    my ($self) = @_;

    my $queue = $self->{queue};

    if (not @queue) {
        lock($lock);
        cond_wait($lock);
    } 

    # thaw returns array so we return the object inside
    my @job = thaw(shift(@queue)); 
    return($job[0]);
}

1;

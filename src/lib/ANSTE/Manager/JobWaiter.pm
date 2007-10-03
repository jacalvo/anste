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
my $current : shared;
my $id : shared;

sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        $id = 0;

        $singleton = bless($self, $class);
    }

    return $singleton;
}

sub jobReceived # (job)
{
    my ($self, $job) = @_; 

    defined $job or
        throw ANSTE::Exceptions::MissingArgument('job');

    lock($lock);
    $id++;
    $job->setId($id);
    my $str = freeze($job);
    push(@queue, $str);
    cond_signal($lock);
}

sub deleteJob # (id) returns boolean
{
    my ($self, $id) = @_;

    if ($current and (_getJobId($current) == $id)) {
        # TODO: Delete the current running job
        return 0;
    }
    if (not @queue) {
        return 0;
    }
    foreach my $i (0 .. $#queue) {
        my $fjob = $queue[$i];
        if (_getJobId($fjob) == $id) {
            delete $queue[$id];
            return 1;
        }
    }
    return 0;
}

sub _getJobId # (fjob) frozen job
{
    my ($fjob) = @_;

    my @job = thaw($fjob); 

    return($job[0]->id());
}

sub waitForJob # returns job
{
    my ($self) = @_;

    $current = undef;

    if (not @queue) {
        lock($lock);
        cond_wait($lock);
    } 

    do { # skip the undefs (deleted jobs)
        $current = shift(@queue);
    } while (not $current);
    # thaw returns array so we return the object inside
    my @job = thaw($current); 

    return($job[0]);
}

sub current # returns current job
{
    my ($self) = @_;

    return $current;
}

sub queue # returns list ref
{
    my ($self) = @_;

    return \@queue;
}

1;

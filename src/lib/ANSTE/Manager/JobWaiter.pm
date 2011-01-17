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

package ANSTE::Manager::JobWaiter;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Exceptions::MissingArgument;

use threads;
use threads::shared;
use FreezeThaw qw(freeze thaw);

# Class: JobWaiter
#
#   Handles the job received messages and manages the job queue.
#

my $singleton;

my $lock : shared;
my @queue : shared;
my $current : shared;

# Method: instance
#
#   Returns a reference to the singleton object of this class.
#
# Returns:
#
#   ref - the class unique instance of type <ANSTE::Manager::JobWaiter>.
#
sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        $singleton = bless($self, $class);
    }

    return $singleton;
}

# Method: jobReceived
#
#   Notifies the reception of a job.
#
# Parameters:
#
#   job - <ANSTE::Manager::Job> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub jobReceived # (job)
{
    my ($self, $job) = @_; 

    defined $job or
        throw ANSTE::Exceptions::MissingArgument('job');

    lock($lock);
    my $str = freeze($job);
    push(@queue, $str);
    cond_signal($lock);
}

# Method: waitForJob
#
#   Waits until a job is received.
#
# Returns:
#
#   ref - <ANSTE::Manager::Job> object
#
sub waitForJob # returns job
{
    my ($self) = @_;

    $current = undef;

    if (not @queue) {
        lock($lock);
        cond_wait($lock);
    } 

    $current = shift(@queue);
    # thaw returns array so we return the object inside
    my @job = thaw($current); 

    return($job[0]);
}

# Method: deleteJob
#
#   Deletes the given job from the queue.
#
# Parameters:
#
#   jobID - String with the job identificator.
#
# Returns:
#
#   boolean - true if deleted correctly, false if not
#
sub deleteJob # (jobID) returns boolean
{
    my ($self, $jobID) = @_;

    if ($current and (_getJobId($current) == $jobID)) {
        # TODO: Delete the current running job
    }
    if (not @queue) {
        return 0;
    }
    for my $i (0 .. $#queue) {
        my $fjob = $queue[$i];
        my $fjobid = _getJobId($fjob);
        if (_getJobId($fjob) == $jobID) {
            _delete($i);
           return 1;
        }
    }
    return 0;
}

# Method: current
#
#   Gets the current running job.
#
# Returns:
#
#   string - contains a frozen <ANSTE::Manager::Job> object
#
sub current # returns current job
{
    my ($self) = @_;

    return $current;
}

# Method: queue
#
#   Gets the job queue.
#
# Returns:
#
#   ref - reference to list that contains frozen <ANSTE::Manager::Job> objects
#
sub queue # returns list ref
{
    my ($self) = @_;

    lock($lock);
    return \@queue;
}

sub _delete # (index)
{
    my ($index) = @_;

    lock($lock);
    if ($index == $#queue) {
        pop(@queue);
    }
    else {
        delete $queue[$index];
        for my $i ($index .. ($#queue - 1)) {
            $queue[$i] = $queue[$i+1];
        }
        pop(@queue);
    }        
}

sub _getJobId # (fjob) frozen job
{
    my ($fjob) = @_;

    my @job = thaw($fjob); 

    return($job[0]->id());
}


1;

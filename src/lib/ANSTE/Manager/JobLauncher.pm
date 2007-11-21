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

package ANSTE::Manager::JobLauncher;

use strict;
use warnings;

use ANSTE::Manager::JobWaiter;
use ANSTE::Manager::MailNotifier;
use ANSTE::Manager::RSSWriter;
use ANSTE::Manager::Config;
use ANSTE::Exceptions::MissingArgument;

# Class: JobLauncher
#
#   Launches the jobs of the queue.
#

# Constructor: new
#
#   Constructor for JobLauncher class.
#
# Returns:
#
#   A recently created <ANSTE::Manager::JobLauncher> object.
#
sub new # () returns new JobLauncher object
{
	my ($class) = @_;
	my $self = {};

	bless($self, $class);

	return $self;
}

# Method: waitAndLaunch
#
#   Waits until there is a job in the queue and launches it.
#
sub waitAndLaunch
{
	my ($self) = @_;

    print "Waiting for jobs...\n";
    my $waiter = ANSTE::Manager::JobWaiter->instance();

    my $job;
    while ($job = $waiter->waitForJob()) {
        $self->_launch($job); 
    }
}

sub _launch # (job)
{
	my ($self, $job) = @_;	
    
    my $test = $job->test();
    my $user = $job->user();
    my $path = "/home/$user/" . $job->path();


    my $WWWDIR = ANSTE::Manager::Config->instance()->wwwDir(); 

    my $testlog = "$test-results";
    $testlog =~ tr{/}{-};
   
    my $logpath = "$WWWDIR/$user/$testlog";

    print "Running test '$test' from user '$user'...\n";
    my $command = "anste -t $test -o $logpath -p $path";
    my $ret = $self->_executeSavingLog($command, "$logpath/out.log");
    if ($ret == 0) {
        print "Execution of test '$test' from user '$user' finished.\n";
    } else {
        print "Execution of test '$test' from user '$user' failed.\n";
        $job->setFailed();
    }

    if ($job->email()) {
        my $mail = new ANSTE::Manager::MailNotifier();
        $mail->sendNotify($job, $testlog);
    }        

    my $rss = new ANSTE::Manager::RSSWriter();
    $rss->writeItem($job, $testlog);
}

sub _executeSavingLog # (command, log) # returns exit code
{
    my ($self, $command, $log) = @_;

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif ($pid == 0) {
        # Redirect stdout and stderr
        open(STDOUT, '>', $log)     or return 1;
        open(STDERR, '>&STDOUT')   or return 1;

        exec($command);
    }
    else {
        waitpid($pid, 0);
        return $?;
    }
}

1;

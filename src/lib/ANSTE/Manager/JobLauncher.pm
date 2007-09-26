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
use ANSTE::Manager::Config;
use ANSTE::Exceptions::MissingArgument;

sub new # () returns new JobLauncher object
{
	my ($class) = @_;
	my $self = {};

	bless($self, $class);

	return $self;
}

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


    my $EXDIR = ANSTE::Manager::Config->instance()->executionLog(); 
    my $WWWDIR = ANSTE::Manager::Config->instance()->wwwDir(); 

    if (not -d $EXDIR) {
        mkdir($EXDIR) or die "Can't mkdir: $!";
    }
    my $execlog = "$test.log";
    $execlog =~ tr{/}{-};

    my $userdir = "$WWWDIR/$user";

    if (not -d $userdir) {
        mkdir($userdir) or die "Can't mkdir: $!";
    }
    my $testlog = "$test-results";
    $testlog =~ tr{/}{-};
   
    print "Running test '$test' from user '$user'...\n";
    my $command = "bin/anste -t $test -o $userdir/$testlog";
    $self->_executeSavingLog($command, "$EXDIR/$execlog");
    print "Execution of test '$test' from user '$user' finished.\n";

    if ($job->email()) {
        my $mail = new ANSTE::Manager::MailNotifier();
        $mail->sendNotify($job);
    }        
}

sub _executeSavingLog # (command, log)
{
    my ($self, $command, $log) = @_;

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif ($pid == 0) {
        # Redirect stdout and stderr
        open(STDOUT, "> $log")     or return 1;
        open(STDERR, '>&STDOUT')   or return 1;

        exec($command);
    }
    else {
        waitpid($pid, 0);
    }
}

1;

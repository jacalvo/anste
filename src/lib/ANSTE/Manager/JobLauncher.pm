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

    print "STARTING JOB LAUNCHER\n";
    my $waiter = ANSTE::Manager::JobWaiter->instance();

    my $job;
    print "WAITING FOR A BLOWJOB\n";
    while ($job = $waiter->waitForJob()) {
        print "LAUNCHING $job\n";
        $self->_launch($job); 
    }
}

sub _launch # (job)
{
	my ($self, $job) = @_;	

    my $test = $job->test();

    my $DIR = '/tmp/anste-out';

    mkdir $DIR;
    mkdir "$DIR/$test";

    $self->_executeSavingLog("anste -t $test", "$DIR/$test.log");
}

sub _execute # (command)
{
    my ($self, $command) = @_;

    return system($command);
}

sub _executeSavingLog # (command, log)
{
    my ($self, $command, $log) = @_;
    print "EXECUTING $command\n";

    # Take copies of the file descriptors
    open(OLDOUT, '>&STDOUT')   or return 1;
    open(OLDERR, '>&STDERR')   or return 1;

    # Redirect stdout and stderr
    open(STDOUT, "> $log")     or return 1;
    open(STDERR, '>&STDOUT')   or return 1;

    my $ret = system($command);

    # Close the redirected filehandles
    close(STDOUT)              or return 1;
    close(STDERR)              or return 1;

    # Restore stdout and stderr
    open(STDERR, '>&OLDERR')   or return 1;
    open(STDOUT, '>&OLDOUT')   or return 1;

    # Avoid leaks by closing the independent copies
    close(OLDOUT)              or return 1;
    close(OLDERR)              or return 1;

    return $ret;
}

1;

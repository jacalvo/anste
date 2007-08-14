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

package ANSTE::Test::Runner;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::ScenarioDeployer;
use ANSTE::Test::Suite;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::HostWaiter;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use Error qw(:try);

sub new # (suite) returns new Runner object
{
	my ($class, $suite) = @_;
	my $self = {};

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    $self->{suite} = $suite;
	
	bless($self, $class);

	return $self;
}

sub run
{
    my ($self) = @_;

    my $suite = $self->{suite};

    my $scenario = $suite->scenario();

    $self->{hostIP} = $self->_deploy($scenario);

    $self->_runSuite();
}

sub _deploy # (file)
{
    my ($self, $file) = @_;

    my $scenario = new ANSTE::Scenario::Scenario();
    try {
        $scenario->loadFromFile($file);
    } catch ANSTE::Exceptions::InvalidFile with {
        print STDERR "Can't load scenario $file.\n";
        exit(1);
    };

    my $deployer = new ANSTE::Deploy::ScenarioDeployer($scenario);
    $deployer->deploy();
}

sub _runSuite
{
    my ($self) = @_;

    my $suite = $self->{suite};

    my $name = $suite->name();

    print "\n\nRunning test suite: $name\n\n";

    foreach my $test (@{$suite->tests()}) {
        $name = $test->name();
        print "Running test: $name\n";
        my $ret = $self->_runTest($test);
        print "Result: $ret\n\n";
    }
}

sub _runTest # (test)
{
    my ($self, $test) = @_;

    my $hostname = $test->host();

    my $path = ANSTE::Config->instance()->testPath();
    my $suiteDir = $self->{suite}->dir();
    my $testDir = $test->dir();

    my $testScript = "$path/$suiteDir/$testDir/test";
    
    $self->_runScript($hostname, $testScript);
}

sub _runScript # (hostname, script)
{
    my ($self, $hostname, $script) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $port = ANSTE::Config->instance()->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($script);
    $client->exec($script);
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    my $ret = $waiter->waitForExecution($hostname);
    $client->del($script);
    
    return $ret;
}

1;

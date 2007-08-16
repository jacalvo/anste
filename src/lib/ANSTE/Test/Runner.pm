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

sub new # returns new Runner object
{
	my ($class, $suite) = @_;
	my $self = {};

    $self->{suite} = undef;

	bless($self, $class);

	return $self;
}

sub runDir # (dir)
{
    my ($self, $dir) = @_;

    # FIXME: Not implemented
}

sub runSuite # (suite)
{
    my ($self, $suite) = @_;

    $self->{suite} = $suite;

    my $scenarioFile = $suite->scenario();

    my $scenario = $self->_loadScenario($scenarioFile);

    my $deployer = new ANSTE::Deploy::ScenarioDeployer($scenario);
    $self->{hostIP} = $deployer->deploy();

    $self->_runTests();

    $deployer->shutdown();
}

sub _loadScenario # (file)
{
    my ($self, $file) = @_;

    my $scenario = new ANSTE::Scenario::Scenario();
    try {
        $scenario->loadFromFile($file);
    } catch ANSTE::Exceptions::InvalidFile with {
        print STDERR "Can't load scenario $file.\n";
        exit(1);
    };
    
    return $scenario;
}

sub _runTests
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

    my $suitePath = ANSTE::Config->instance()->testPath();
    my $suiteDir = $self->{suite}->dir();
    my $testDir = $test->dir();

    my $path = "$suitePath/$suiteDir/$testDir";

    # Run pre-test script if exists
    if (-r "$path/pre") {
        $self->_runScript($hostname, "$path/pre");
    }
    
    # Run the test itself
    if (not -r "$path/test") {
        throw ANSTE::Exceptions::NotFound('Test script',
                                          "$suiteDir/$testDir/test");
    }
    my $ret = $self->_runScript($hostname, "$path/test");

    # Run pre-test script if exists
    if (-r "$path/post") {
        $self->_runScript($hostname, "$path/post");
    }

    return $ret;
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

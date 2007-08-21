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
use ANSTE::Report::Report;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use Error qw(:try);

sub new # (suite) returns new Runner object
{
	my ($class, $suite) = @_;
	my $self = {};

    $self->{suite} = undef;
    $self->{report} = new ANSTE::Report::Report();
    my $system = ANSTE::Config->instance()->system();

    eval("use ANSTE::System::$system");
    die "Can't load package $system: $@" if $@;

    $self->{system} = "ANSTE::System::$system"->new();

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

#FIXME:    $deployer->shutdown();
}

sub report # returns report object
{
    my ($self) = @_;

    return $self->{report};
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

    my $suiteName = $suite->name();

    my $report = $self->{report};

    print "\n\nRunning test suite: $suiteName\n\n";

    my $suiteResult = new ANSTE::Report::SuiteResult();
    $suiteResult->setName($suiteName);

    foreach my $test (@{$suite->tests()}) {
        my $testName = $test->name();
        print "Running test: $testName\n";
        my $testResult = $self->_runTest($test);
        my $ret = $testResult->value();
        print "Result: $ret\n\n";

        # Adds the test report
        $suiteResult->add($testResult);
    }

    $report->add($suiteResult);
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

    my $logPath = ANSTE::Config->instance()->logPath();
    
    # Create logs directory
    mkdir $logPath;
    mkdir "$logPath/selenium";
    mkdir "$logPath/out";

    my $name = $test->name();

    my ($log, $ret);

    # Run the test itself either it's a selenium one or a normal one 
    if ($test->selenium()) {
        $log = "$logPath/selenium/$name.html";
        $ret = $self->_runSeleniumRC($hostname, "$path/suite.html", $log);
    }
    else {
        if (not -r "$path/test") {
            throw ANSTE::Exceptions::NotFound('Test script',
                                              "$suiteDir/$testDir/test");
        }
        $log = "$logPath/out/$name.txt";
        $ret = $self->_runScript($hostname, "$path/test", $log);
    }

    # Run pre-test script if exists
    if (-r "$path/post") {
        $self->_runScript($hostname, "$path/post");
    }

    my $testResult = new ANSTE::Report::TestResult();
    $testResult->setName($test->name());
    $testResult->setValue($ret);
    $testResult->setFile($log);

    return $testResult;
}

sub _runScript # (hostname, script, log?)
{
    my ($self, $hostname, $script, $log) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $port = ANSTE::Config->instance()->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($script);
    if (defined $log) {
        $client->exec($script, $log);
    }
    else {
        $client->exec($script);
    }
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    my $ret = $waiter->waitForExecution($hostname);
    $client->del($script);

    if (defined $log) {
        $client->get($log);
#TODO:        $client->del($log);
    }
    
    return $ret;
}

sub _runSeleniumRC # (hostname, file, log) returns result 
{
    my ($self, $hostname, $file, $log) = @_;

    my $system = $self->{system};

    # TODO: Include the URL of the test in XMLs
    my $ip = $self->{hostIP}->{$hostname};
    my $url = "http://$ip";

    my $config = ANSTE::Config->instance();

    my $jar = $config->seleniumRCjar();
    my $browser = $config->seleniumBrowser();

    $system->executeSelenium(jar => $jar,
                             browser => $browser, 
                             url => $url, 
                             testFile => $file, 
                             resultFile => $log);

    return $self->_seleniumResult($log);
}

sub _seleniumResult # (logfile)
{
    my ($self, $logfile) = @_;

    my $LOG;
    open($LOG, '<', $logfile);
    foreach my $line (<$LOG>) {
        if ($line =~ /^<td>passed/) {
            close($LOG);
            return 0;
        }
        elsif ($line =~ /^<td>failed/) {
            close($LOG);
            return 1;
        }
    }
    close($LOG);

    return 2;
}

1;

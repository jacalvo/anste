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
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use Error qw(:try);

# Class: Runner
#
#   Class used to run separate test suites or entire directories
#   containing several suites.
#

# Constructor: new
#
#   Constructor for Runner class.
#
# Returns:
#
#   A recently created <ANSTE::Test::Runner> object.
#
sub new # returns new Runner object
{
	my ($class) = @_;
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

# Method: runDir
#
#   Runs all the suites of the given directory.
#
# Parameters:
#
#   suites - String with the directory that contains the suites.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub runDir # (suites)
{
    my ($self, $suites) = @_;

	defined $suites or
		throw ANSTE::Exceptions::MissingArgument('suites');
	

    my $dir = ANSTE::Config->instance()->testFile($suites); 

    my $DIR;
    opendir($DIR, $dir) or die "Can't open directory $suites";
    my @dirs = readdir($DIR);
    closedir($DIR);

#   FIXME: Throw an exception instead of dying??
    if (@dirs == 0) {
        die "There isn't any test suite in $suites";
    }

    foreach my $dir (@dirs) {
        # Skip all directorys beginning with dot.
        next if $dir =~ /^\./;
        my $suite = new ANSTE::Test::Suite;
        my $suiteDir = "$suites/$dir";
        $suite->loadFromDir($suiteDir);
        $self->runSuite($suite);
    }
}

# Method: runSuite
#
#   Runs a given suite of tests.
#
# Parameters:
#
#   suite - <ANSTE::Test::Suite> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub runSuite # (suite)
{
    my ($self, $suite) = @_;

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    if (not $suite->isa('ANSTE::Test::Suite')) {
        throw ANSTE::Exception::InvalidType('suite',
                                            'ANSTE::Test::Suite');
    }

    $self->{suite} = $suite;

    my $scenarioFile = $suite->scenario();

    my $scenario = $self->_loadScenario($scenarioFile);

    my $sceName = $scenario->name();
    my $suiteName = $suite->name();
    print "Deploying scenario '$sceName' for suite '$suiteName'...\n";

    my $deployer = new ANSTE::Deploy::ScenarioDeployer($scenario);
    try {
        $self->{hostIP} = $deployer->deploy();

        print "Finished deployment of scenario '$sceName'.\n";

        $self->_runTests();
    } finally {
        $deployer->shutdown();
    };
    print "Finished testing of suite '$suiteName'.\n\n";

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    my $time = "$mday-$mon-$year $hour:$min:$sec";
    $self->{report}->setTime($time);
}

# Method: report
#
#   Gets the object containing the test results report.
#
# Returns:
#
#   ref - <ANSTE::Report::Report> object.
#
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
    $suiteResult->setSuite($suite);

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

    my $system = $self->{system};
    my $hostname = $test->host();

    my $config = ANSTE::Config->instance();

    my $suiteDir = $self->{suite}->dir();
    my $testDir = $test->dir();

    my $path = $config->testFile("$suiteDir/$testDir");

    # Run pre-test script if exists
    if (-r "$path/pre") {
        $self->_runScript($hostname, "$path/pre");
    }

    my $logPath = $config->logPath();
    
    # Create directories
    mkdir $logPath;
    mkdir "$logPath/selenium";
    mkdir "$logPath/out";
    mkdir "$logPath/video" if $config->seleniumVideo();

    my $name = $test->name();

    my ($log, $ret);

    my $testResult = new ANSTE::Report::TestResult();
    $testResult->setTest($test);

    my $verbose = $config->verbose();

    # Store start time
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    my $time = "$mday-$mon-$year $hour:$min:$sec";
    $testResult->setStartTime($time);

    # Run the test itself either it's a selenium one or a normal one 
    if ($test->selenium()) {
        my $video;
        if ($config->seleniumVideo()) {
            $video = "$logPath/video/$name.ogg";
            print "Starting video recording for test $name...\n" if $verbose;
            $system->startVideoRecording($video);
        }

        $log = "$logPath/selenium/$name.html";
        $ret = $self->_runSeleniumRC($hostname, "$path/suite.html", $log);

        if ($config->seleniumVideo()) {
            print "Ending video recording for test $name... " if $verbose;
            $system->stopVideoRecording();
            print "Done.\n" if $verbose; 

            # If test was correct and record all videos option
            # is not activated, delete the video
            if (!$config->seleniumRecordAll() && $ret == 0) {
                unlink($video);
            } 
            else {
                $testResult->setVideo("video/$name.ogg");
            }
        }            
        $testResult->setLog("selenium/$name.html");
    }
    else {
        if (not -r "$path/test") {
            throw ANSTE::Exceptions::NotFound('Test script',
                                              "$suiteDir/$testDir/test");
        }
        $log = "$logPath/out/$name.txt";
        $ret = $self->_runScript($hostname, "$path/test", $log);
        $testResult->setLog("out/$name.txt");
    }

    # Run pre-test script if exists
    if (-r "$path/post") {
        $self->_runScript($hostname, "$path/post");
    }

    $testResult->setValue($ret);

    # Store end time
    ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    $time = "$mday-$mon-$year $hour:$min:$sec";
    $testResult->setEndTime($time);

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
        $client->del($log);
    }
    
    return $ret;
}

sub _runSeleniumRC # (hostname, file, log) returns result 
{
    my ($self, $hostname, $file, $log) = @_;

    my $system = $self->{system};

    my $ip = $self->{hostIP}->{$hostname};
    my $url = "http://$ip";

    my $config = ANSTE::Config->instance();

    my $jar = $config->seleniumRCjar();
    my $browser = $config->seleniumBrowser();

    try {
        $system->executeSelenium(jar => $jar,
                                 browser => $browser, 
                                 url => $url, 
                                 testFile => $file, 
                                 resultFile => $log);
    } catch ANSTE::Exceptions::Error with {
        throw ANSTE::Exceptions::Error("Can't execute Selenium or Java. " .
                                       "Ensure that everything is ok.");
    };

    return $self->_seleniumResult($log);
}

sub _seleniumResult # (logfile)
{
    my ($self, $logfile) = @_;

    my $LOG;
    open($LOG, '<', $logfile) or
        throw ANSTE::Exceptions::Error("Selenium results not found. " . 
                                       "Check if it's working properly.");
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

    return -1;
}

1;

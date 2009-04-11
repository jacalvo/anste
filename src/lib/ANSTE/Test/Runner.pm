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
use ANSTE::Test::Validator;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::HostWaiter;
use ANSTE::Report::Report;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;
use ANSTE::Exceptions::NotFound;

use Cwd;
use File::Temp qw(tempdir);
use Text::Template;
use Safe;
use Perl6::Slurp;
use Error qw(:try);

use constant DEFAULT_SELENIUM_PORT => 1666;

my $SUITE_FILE = 'suite.html';
my $SUITE_LIST_FILE = 'suites.list';

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

    my $config = ANSTE::Config->instance();

    $self->{suite} = undef;
    $self->{report} = new ANSTE::Report::Report();
    my $system = $config->system();

    eval "use ANSTE::System::$system";
    die "Can't load package $system: $@" if $@;

    $self->{system} = "ANSTE::System::$system"->new();

    my $format = $config->format();
    my $writerPackage = "ANSTE::Report::$format" . 'Writer';
    eval "use $writerPackage";
    die "Can't load package $writerPackage: $@" if $@;

    $self->{writer} = $writerPackage->new($self->{report});

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

    my @dirs;

    if (not -r "$dir/$SUITE_LIST_FILE") {
        throw ANSTE::Exceptions::Error("There isn't any test suite in $suites");
    }
    my $SUITES_FH;
    open($SUITES_FH, '<', "$dir/$SUITE_LIST_FILE");
    @dirs = <$SUITES_FH>;
    chomp(@dirs);
    close($SUITES_FH);

    foreach my $subdir (@dirs) {
        # If the dir contains more suites, descend on it
        if (-r "$dir/$subdir/$SUITE_LIST_FILE") {
            $self->runDir("$suites/$subdir");
        }
        elsif (-r "$dir/$subdir/suite.xml") {
            # If the dir contains a single suit, run it
            my $suite = new ANSTE::Test::Suite;
            my $suiteDir = "$suites/$subdir";
            $suite->loadFromDir($suiteDir);
            $self->runSuite($suite);
        }
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

    my $validator = new ANSTE::Test::Validator;
    $validator->validateSuite($suite);

    $self->{suite} = $suite;
    my $suiteName = $suite->name();

    my $scenarioFile = $suite->scenario();

    my $scenario = $self->_loadScenario($scenarioFile, $suiteName);

    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();

    my $sceName = $scenario->name();
    print "Deploying scenario '$sceName' for suite '$suiteName'...\n"
        if not $reuse;

    my $deployer = new ANSTE::Deploy::ScenarioDeployer($scenario);
    try {
        $self->{hostIP} = $deployer->deploy();

        print "Finished deployment of scenario '$sceName'.\n"
            if not $reuse;

        $self->_runTests();
    } catch ANSTE::Exceptions::Error with {
        my $ex = shift;
        my $msg = $ex->message();
        print "ERROR: $msg\n";
    } catch Error with {
        my $ex = shift;
        my $msg = $ex->stringify();
        print "ERROR: $msg\n";
    } finally {
        if ($config->wait()) {
            print "Waiting for testing on the scenario. " .
                  "Press any key to shutdown it and continue.\n";
            my $key;
            read(STDIN, $key, 1);
        }
        $deployer->destroy()
            if not $reuse;
    };
    print "Finished testing of suite '$suiteName'.\n\n";

    $self->{report}->setTime($self->_time());
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

sub _loadScenario # (file, suite)
{
    my ($self, $file, $suite) = @_;

    my $scenario = new ANSTE::Scenario::Scenario();
    try {
        $scenario->loadFromFile($file);
    } catch ANSTE::Exceptions::InvalidFile with {
        my $ex = shift;
        my $filename = $ex->file();
        print STDERR "Can't load scenario $file for suite $suite.\n";
        print STDERR "Reason: Can't open file $filename.\n";
        exit(1);
    };

    return $scenario;
}

sub _runTests
{
    my ($self) = @_;

    my $config = ANSTE::Config->instance();
    my $suite = $self->{suite};
    my $suiteName = $suite->name();
    my $report = $self->{report};

    print "\n\nRunning test suite: $suiteName\n\n";

    my $suiteResult = new ANSTE::Report::SuiteResult();
    $suiteResult->setSuite($suite);

    $report->add($suiteResult);

    foreach my $test (@{$suite->tests()}) {
        my $testName = $test->name();
        print "Running test: $testName\n";
        my ($testResult, $ret);
        try {
            $testResult = $self->_runTest($test);
            $ret = $testResult->value();
        } catch ANSTE::Exceptions::NotFound with {
            my $ex = shift;
            my $what = $ex->what();
            my $value = $ex->value();
            print STDERR "Error running test $testName.\n";
            print STDERR "Reason: $what $value not found.\n";
            $ret = -1;
        };
        print "Result: $ret\n\n";

        # Adds the test report
        if ($testResult) {
            $suiteResult->add($testResult);

            # Write test reports
            my $writer = $self->{writer};
            my $logPath = $config->logPath();
            $writer->write("$logPath/" . $writer->filename());
        }

        # Wait user input if there is a breakpoint in the test
        # and not in non-stop mode, or wait always if we are
        # in step by step mode.
        if (($test->stop() && !$config->nonStop) ||
            ($config->waitFail() && $ret != 0) || $config->step()) {
            print "Stop requested after this test. " .
                  "Press any key to continue.\n";
            my $key;
            read(STDIN, $key, 1);
        }
    }
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

    if (not -x $path) {
        throw ANSTE::Exceptions::NotFound('Test', $path);
    }

    my $logPath = $config->logPath();

    # Create directories
    use File::Path;
    mkpath "$logPath/$suiteDir";
    mkdir "$logPath/$suiteDir/video" if $config->seleniumVideo();

    my $name = $test->name();

    my ($logfile, $ret);

    my $testResult = new ANSTE::Report::TestResult();
    $testResult->setTest($test);

    my $verbose = $config->verbose();

    # Store start time
    $testResult->setStartTime($self->_time());

    # Create a temp directory for this test
    my $newPath = tempdir(CLEANUP => 1)
        or die "Can't create temp directory: $!";

    # Run pre-test script if exists
    if (-r "$path/pre") {
        my $script = "$newPath/$name.pre";
        system("cp $path/pre $script");
        $self->_runScript($hostname, $script);
    }

    # TODO: separate this in two functions runSeleniumTest and runShellTest ??

    # Run the test itself either it's a selenium one or a normal one
    if ($test->selenium()) {
        my $suiteFile = "$path/$SUITE_FILE";
        if (not -r $suiteFile) {
            throw ANSTE::Exceptions::NotFound('Suite file', $suiteFile);
        }
        my $video;
        if ($config->seleniumVideo()) {
            $video = "$logPath/$suiteDir/video/$name.ogg";
            print "Starting video recording for test $name...\n" if $verbose;
            $system->startVideoRecording($video);
        }

        my $variables = $test->variables();
        if (%{$variables}) {
            # Fill template in another directory
            my $cwd = getcwd();
            chdir($path);
            my @templateFiles = <*.html>;
            chdir($cwd);
            foreach my $file (@templateFiles) {
                system("cp $path/$file $newPath/$file");
            }
            $suiteFile = "$newPath/$SUITE_FILE";

            foreach my $file (@templateFiles) {
                # Skip suite.html
                next if $file eq $SUITE_FILE;

                my $template = new Text::Template(SOURCE => "$newPath/$file")
                    or die "Couldn't construct template: $Text::Template::ERROR";
                my $text = $template->fill_in(HASH => $variables, SAFE => new Safe)
                    or die "Couldn't fill in the template: $Text::Template::ERROR";

                # Write the filled file.
                my $FH;
                open($FH, '>', "$newPath/$file");
                print $FH $text;
                close($FH);
            }
        }

        $logfile = "$logPath/$suiteDir/$name.html";
        my $port = $test->port();
        $ret = $self->_runSeleniumRC($hostname, $suiteFile, $logfile, $port);

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
                $testResult->setVideo("$suiteDir/video/$name.ogg");
            }
        }
        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);
        $testResult->setLog("$suiteDir/$name.html");
    }
    else {
        if (not -r "$path/test") {
            throw ANSTE::Exceptions::NotFound('Test script',
                                              "$suiteDir/$testDir/test");
        }

        $logfile = "$logPath/$suiteDir/$name.txt";

        # Copy to temp directory and rename it to test name
        system("cp $path/test $newPath/$name");

        $ret = $self->_runScript($hostname, "$newPath/$name", $logfile,
                                 $test->env(), $test->params());
        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);

        # Editing the log to write the starting and ending times.
        my $contents = slurp "<$logfile";
        my $LOG;
        open($LOG, '>', $logfile);
        my $startTime = $testResult->startTime();
        print $LOG "Starting test '$name' at $startTime.\n\n";
        print $LOG $contents;
        print $LOG "\nTest finished at $endTime.\n";
        close($LOG);

        $testResult->setLog("$suiteDir/$name.txt");
    }

    # Run post-test script if exists
    if (-r "$path/post") {
        my $script = "$newPath/$name.post";
        system("cp $path/post $script");
        $self->_runScript($hostname, $script);
    }

    # Invert the result of the test when checking for fail
    if ($test->assert() eq 'failed') {
        $ret = ($ret != 0) ? 0 : 1;
    }
    $testResult->setValue($ret);


    return $testResult;
}

sub _time
{
    my ($self) = @_;

    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $year += 1900;
    my $str = sprintf("%02d-%02d-%02d %02d:%02d:%02d",
                      $mday, $mon, $year % 100, $hour, $min, $sec);
    return $str;
}

sub _runScript # (hostname, script, log?, env?, params?)
{
    my ($self, $hostname, $script, $log, $env, $params) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $port = ANSTE::Config->instance()->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($script);
    if (defined $log) {
        $client->exec($script, $log, $env, $params);
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

sub _runSeleniumRC # (hostname, file, log, port?) returns result
{
    my ($self, $hostname, $file, $log, $port) = @_;

    my $system = $self->{system};

    my $ip = $self->{hostIP}->{$hostname};

    unless (defined ($port)) {
        $port = DEFAULT_SELENIUM_PORT;
    }
    my $url = "http://$ip:$port";

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

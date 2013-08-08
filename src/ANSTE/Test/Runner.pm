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

package ANSTE::Test::Runner;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::ScenarioDeployer;
use ANSTE::Test::Suite;
use ANSTE::Test::Validator;
use ANSTE::Test::ScenarioLoader;
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
    $self->{writers} = [];

    foreach my $format (@{$config->formats()}) {
        my $writerPackage = "ANSTE::Report::$format" . 'Writer';
        eval "use $writerPackage";
        die "Can't load package $writerPackage: $@" if $@;

        push (@{$self->{writers}}, $writerPackage->new($self->{report}));
    }

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
        # remove comments and ignore blank lines
        $subdir =~ s/#.*$//;
        $subdir =~ s/^\s+//;
        $subdir =~ s/\s+$//;
        if (not $subdir) {
            next;
        }

        my $path = "$dir/$subdir";
        # If the dir contains more suites, descend on it
        if (-r "$path/$SUITE_LIST_FILE") {
            $self->runDir("$suites/$subdir");
        }
        elsif ((-r "$path/suite.xml") or (-r "$path/suite.yaml")) {
            # If the dir contains a single suit, run it
            my $suite = new ANSTE::Test::Suite;
            my $suiteDir = "$suites/$subdir";
            $suite->loadFromDir($suiteDir);
            $self->runSuite($suite);
        } else {
            throw ANSTE::Exceptions::Error("There isn't any test in $subdir (from $dir/$SUITE_LIST_FILE)");
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

    my $scenario = $self->_loadScenario($scenarioFile, $suite);

    my $config = ANSTE::Config->instance();
    $config->setCurrentScenario($scenarioFile);
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
        $ex->throw();
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

    my $scenario;
    try {
        $scenario = ANSTE::Test::ScenarioLoader->loadScenario($file,$suite);
    } catch ANSTE::Exceptions::InvalidFile with {
        my $ex = shift;
        my $filename = $ex->file();
        print STDERR "Can't load scenario $file for suite $suite->name().\n";
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
        my $testResult = $self->_runOneTest($test);
        my $ret;

        # Adds the test report
        if ($testResult) {
            $suiteResult->add($testResult);

            # Write test reports
            my $logPath = $config->logPath();
            foreach my $writer (@{$self->{writers}}) {
                $writer->write("$logPath/" . $writer->filename());
            }
            $report->setTime($self->_time());
            $ret = $testResult->value();
        } else {
            $ret = -1;
        }

        # Wait user input if the user has set a breakpoint, or
        # if there was an error and we are in wait on fail mode,
        # or always if we are in step by step mode.

        my $msg;
        my $stop = 0;
        my $critical = 0;

        if ($config->breakpoint($test->name())) {
            $stop = 1;
            $msg = "Breakpoint requested after this test.";
        }
        if ($config->waitFail() && $ret != 0) {
            $stop = 1;
            $msg = "Test failed and wait on failure was requested.";
        }
        if ($config->step()) {
            $stop = 1;
            $msg = "Step by step execution.";
        }

        # Stop executing tests if a critical one fails
        if (($ret != 0) and $test->critical()) {
            if ($config->waitFail()) {
                $stop = 1;
                $msg = "Critical test failed and wait on failure was requested.";
            }

            $critical = 1;
        }

        if ($stop) {
            while (1) {
                print "$msg " .
                    "Press 'r' to run the test again or 'c' to continue.\n";
                my $key;
                read(STDIN, $key, 1);
                if ($key eq 'r') {
                    my $testResult = $self->_runOneTest($test);
                    if ($testResult and ($testResult->value() == 0)) {
                        last;
                    }
                } if ($key eq 'c') {
                    last;
                }
            }
        }

        if ($critical) {
            last;
        }
    }
}

sub _runOneTest # (test)
{
    my ($self, $test) = @_;

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
    return $testResult;
}

sub _runTest # (test)
{
    my ($self, $test) = @_;

    my $system = $self->{system};
    my $name = $test->name();
    my $hostname = $test->host();

    my $config = ANSTE::Config->instance();
    my $verbose = $config->verbose();

    my $suiteDir = $self->{suite}->dir();
    my $testDir = $test->dir();

    my $path = $config->testFile("$suiteDir/$testDir");
    if (not $path) {
        throw ANSTE::Exceptions::NotFound(
            "In test '$name', directory '$testDir'"
        )
    }

    my $logPath = $config->logPath();

    # Create directories
    use File::Path;
    mkpath "$logPath/$suiteDir";
    mkdir "$logPath/$suiteDir/video" if $config->seleniumVideo();
    mkdir "$logPath/$suiteDir/script";

    my ($logfile, $ret);

    my $testResult = new ANSTE::Report::TestResult();
    $testResult->setTest($test);

    # Store start time
    $testResult->setStartTime($self->_time());

    # Create a temp directory for this test
    my $newPath = tempdir(CLEANUP => 1)
        or die "Can't create temp directory: $!";

    # Run pre-test script if exists
    if (-r "$path/pre") {
        my $script = "$newPath/$name.pre";
        system("cp $path/pre $script");
        $self->_runScriptOnHost($hostname, $script);
    }

    # TODO: separate this in two functions runSeleniumTest and runShellTest ??

    # Run the test itself either it's a selenium one or a normal one
    if ($test->type() eq 'selenium') {
        if (not -x $path) {
            throw ANSTE::Exceptions::NotFound('Test', $path);
        }

        my $suiteFile = "$path/$SUITE_FILE";
        if (not -r $suiteFile) {
            throw ANSTE::Exceptions::NotFound('Suite file', $suiteFile);
        }
        my $video;
        if ($config->seleniumVideo()) {
            $video = "$logPath/$suiteDir/video/$name.ogv";
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
        my $protocol = $test->protocol();
        $ret = $self->_runSeleniumRC(hostname => $hostname,
                                     file => $suiteFile,
                                     log => $logfile,
                                     port => $port,
                                     protocl => $protocol);

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
                $testResult->setVideo("$suiteDir/video/$name.ogv");
            }
        }
        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);
        $testResult->setLog("$suiteDir/$name.html");
    } elsif ($test->type() eq 'reboot') {
        $ret = $self->_reboot($hostname);

        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);
    } else {
        if (not -r "$path/test") {
            $path = $config->scriptFile($testDir);
            if (not -r "$path/test") {
                throw ANSTE::Exceptions::NotFound('Test script',
                                              "$suiteDir/$testDir/test");
            }
        }

        $logfile = "$logPath/$suiteDir/$name.txt";
        my $scriptfile = "$logPath/$suiteDir/script/$name.txt";

        # Copy to temp directory dereferencing links and rename to test name
        system("cp -rL $path/* $newPath/");
        system("mv $newPath/test $newPath/$name");
        system("chmod +x $newPath/$name");

        my $env = $test->env();
        my $params = $test->params();

        # Copy the script to the results adding env and params
        my $SCRIPT;
        open ($SCRIPT, '>', $scriptfile);

        if ($env) {
            my $envStr = "# Environment passed to the test:\n";
            $envStr .= "# $env\n";
            print $SCRIPT $envStr;
        }
        if ($params) {
            my $paramsStr = "# Arguments passed to the test: $params\n";
            print $SCRIPT $paramsStr;
        }
        my $scriptContent = slurp "<$path/test";
        print $SCRIPT "# Test script executed:\n";
        print $SCRIPT $scriptContent;
        close ($SCRIPT);

        my $initialTime = time();

        if ($test->type() eq 'host') {
            $ret = $self->{system}->runTest("$newPath/$name",
                                             $logfile, $env, $params);
        } elsif ($test->type() eq 'web') {
            $ret = $self->_runWebTest($test, "$newPath/$name", $logfile);
        } else {
            $ret = $self->_runScriptOnHost($hostname, "$newPath/$name",
                                           $logfile, $env, $params);
        }

        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);
        $testResult->setDuration(time() - $initialTime);

        # Editing the log to write the starting and ending times.
        my $contents = slurp "<$logfile";
        my $LOG;
        open($LOG, '>', $logfile);
        my $startTime = $testResult->startTime();
        print $LOG "Starting test '$name' at $startTime.\n\n";
        print $LOG $contents;
        print $LOG "\nTest finished at $endTime.\n";
        close($LOG);

        $testResult->setLog("$logfile");
        $testResult->setScript("$suiteDir/script/$name.txt");
    }

    # Run post-test script if exists
    if (-r "$path/post") {
        my $script = "$newPath/$name.post";
        system("cp $path/post $script");
        $self->_runScriptOnHost($hostname, $script);
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

sub _reboot # (hostname, log?)
{
    my ($self, $hostname, $log) = @_;

    my $client = new ANSTE::Comm::MasterClient();
    my $port = ANSTE::Config->instance()->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};
    $client->connect("http://$ip:$port");

    my $waiter = ANSTE::Comm::HostWaiter->instance();

    $client->reboot();
    $waiter->hostReady($hostname, 0);
    $waiter->waitForReady($hostname);

    $client->exec('wait-start-apache.sh');
    my $ret = $waiter->waitForExecution($hostname);

    return $ret;
}

sub _runScriptOnHost # (hostname, script, log?, env?, params?)
{
    my ($self, $hostname, $script, $log, $env, $params) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $port = ANSTE::Config->instance()->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($script);
    if (defined $log) {
        my $config = ANSTE::Config->instance();
        my $verbose = $config->verbose();
        if ($verbose) {
            print "Executing $env $script $params > $log\n";
        }
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

sub _runWebTest
{
    my ($self, $test, $script, $logfile) = @_;

    my $hostname = $test->host();
    my $port = $test->port();
    my $protocol = $test->protocol();

    if (not exists $self->{hostIP}->{$hostname}) {
       throw ANSTE::Exceptions::Error("Inexistent hostname $hostname");
    }

    my $ip = $self->{hostIP}->{$hostname};
    if (not $ip) {
       throw ANSTE::Exceptions::Error("Hostname $hostname has not IP! " .
                                       Dumper( $self->{hostIP}->{$hostname}));
    }

    my $config = ANSTE::Config->instance();
    unless ($protocol) {
        $protocol = $config->seleniumProtocol();
    }

    my $url = "$protocol://$ip";
    if (defined ($port)) {
        $url .= ":$port";
    }

    $test->setVariable('BASE_URL', $url);
    my $env = $test->env();

    return $self->{system}->runTest($script, $logfile, $env, '');
}

# Method: _runSeleniumRC
#
#   Executes Selenium remote control
#
# Parameters:
#
#   hostname - hostname
#   file     - suite file
#   log      - log file
#   port     - *optional* port value
#   protocol - *optional* protocol (http/https)
#
# Returns:
#
#   boolean - test result
#
sub _runSeleniumRC
{
    my ($self, %args) = @_;

    my $hostname = $args{hostname};
    my $file = $args{file};
    my $log = $args{log};
    my $port = $args{port};
    my $protocol = $args{protocol};

    my $system = $self->{system};

    my $ip = $self->{hostIP}->{$hostname};

    my $config = ANSTE::Config->instance();

    unless ($protocol) {
        $protocol = $config->seleniumProtocol();
    }

    my $url = "$protocol://$ip";
    if (defined ($port)) {
        $url .= ":$port";
    }

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

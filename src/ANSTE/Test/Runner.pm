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

use ANSTE;
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
use ANSTE::System::System;
use ANSTE::Virtualizer::Virtualizer;
use ANSTE::Util;

use Cwd;
use Text::Template;
use Safe;
use File::Basename;
use File::Slurp;
use File::Temp qw(tempfile tempdir);
use TryCatch;

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
sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{config} = ANSTE::Config->instance();
    $self->{suite} = undef;
    $self->{report} = new ANSTE::Report::Report();
    $self->{system} = ANSTE::System::System->instance();
    $self->{writers} = [];
    $self->{errors} = 0;
    $self->{retest} = 0;

    foreach my $format (@{$self->{config}->formats()}) {
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
sub runDir
{
    my ($self, $suites) = @_;

    defined $suites or
        throw ANSTE::Exceptions::MissingArgument('suites');

    my $config = ANSTE::Config->instance();
    my $dir = $config->testFile($suites);

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
        } elsif (-r "$path/suite.yaml") {
            # If the dir contains a single suit, run it
            my $suite = new ANSTE::Test::Suite;
            my $suiteDir = "$suites/$subdir";
            $suite->loadFromDir($suiteDir);
            $self->runSuite($suite);
            last if ($config->abortOnFail() and $self->errors());
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
sub runSuite
{
    my ($self, $suite) = @_;

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    if (not $suite->isa('ANSTE::Test::Suite')) {
        throw ANSTE::Exception::InvalidType('suite',
                                            'ANSTE::Test::Suite');
    }

    my $scenarioFile = $suite->scenario();
    my $scenario = $self->_loadScenario($scenarioFile, $suite);

    my $validator = new ANSTE::Test::Validator;
    $validator->validateSuite($suite, $scenario);

    $self->{suite} = $suite;
    my $suiteName = $suite->name();

    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();
    my $jump = $config->jump();

    my $sceName = $scenario->name();
    print "Deploying scenario '$sceName' for suite '$suiteName'...\n"
        if not $reuse;

    my $deployer = new ANSTE::Deploy::ScenarioDeployer($scenario);
    try {
        $self->{hostIP} = $deployer->deploy();

        print "Finished deployment of scenario '$sceName'.\n"
            if not $reuse;

        $self->_runTests($reuse, $jump);
    } catch (ANSTE::Exceptions::Error $e) {
        my $msg = $e->message();
        print "ERROR: $msg\n";
        $self->_destroy($deployer, $reuse);
        $e->throw();
    } catch ($e) {
        print "ERROR: $e\n";
    }
    $self->_destroy($deployer, $reuse);
    print "Finished testing of suite '$suiteName'.\n\n";

    $self->{report}->setTime($self->_time());
}

sub _destroy
{
    my ($self, $deployer, $reuse) = @_;

    my $config = ANSTE::Config->instance();
    if ($config->wait()) {
        print "Waiting for testing on the scenario. " .
              "Press any key to shutdown it and continue.\n";
        my $line = <STDIN>;
    }
    $deployer->destroy() if not $reuse;
}

# Method: report
#
#   Gets the object containing the test results report.
#
# Returns:
#
#   ref - <ANSTE::Report::Report> object.
#
sub report
{
    my ($self) = @_;

    return $self->{report};
}

# Method: errors
#
#   Gets the number of errors in the executed tests.
#
# Returns:
#
#   int - number of errors
#
sub errors
{
    my ($self) = @_;

    return $self->{errors};
}

sub _loadScenario
{
    my ($self, $file, $suite) = @_;

    my $scenario;
    try {
        $scenario = ANSTE::Test::ScenarioLoader->loadScenario($file,$suite);
    } catch (ANSTE::Exceptions::InvalidFile $e) {
        my $filename = $e->file();
        print STDERR "Can't load scenario $file for suite $suite->name().\n";
        print STDERR "Reason: Can't open file $filename.\n";
        exit(1);
    }

    return $scenario;
}

sub _runTests
{
    my ($self, $reuse, $jump) = @_;

    my $config = ANSTE::Config->instance();
    my $suite = $self->{suite};
    my $suiteName = $suite->name();
    my $report = $self->{report};

    print "\n\nRunning test suite: $suiteName\n\n";

    my $suiteResult = new ANSTE::Report::SuiteResult();
    $suiteResult->setSuite($suite);

    $report->add($suiteResult);
    my $executeOnlyForcedTests = 0;

    my @suiteTests = @{$suite->tests()};
    my $testNumber = 0;
    my $testTotalNumber = scalar (@suiteTests);
    my $skipBeforeJump = $jump;
    foreach my $test (@suiteTests) {
        $testNumber++;
        next if ($reuse and $test->critical() and not $jump);
        next if ($test->reuseOnly() and (not $reuse or $jump));
        next if ($executeOnlyForcedTests and not $test->executeAlways());
        if ($skipBeforeJump and ($test->name() eq $jump)) {
            $skipBeforeJump = 0;
        }
        next if ($skipBeforeJump);
        my $host = $test->host();

        my $stopBefore = ($config->step() or $config->breakpoint($test->name()));

        my $skip = 0;
        if ($stopBefore) {
            if ($config->autoSnapshot()) {
                ANSTE::info("Taking snapshot of $host...");
                $self->_virt()->createSnapshot($host, ANSTE::snapshotName(), 'auto-snapshot');
                ANSTE::info('Snapshot done');
            }
            my $key;
            while (1) {
                my $testName = $test->name();
                my $msg = $config->step() ? 'Step by step execution' : 'Breakpoint requested';
                print "$msg. Test $testName. " .
                      "Press 'e' to execute or 's' to skip.\n";
                $key = ANSTE::Util::readChar();
                if ($key eq 'e') {
                    last;
                }
                if ($key eq 's') {
                    $skip = 1;
                    last;
                }
            }
        }
        next if ($skip);

        my $testResult = $self->_runOneTest($test, $testNumber, $testTotalNumber);
        my $ret;

        # Adds the test report
        if ($testResult) {
            $self->_addResultToReport($report, $suiteResult, $testResult);
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
        if ($ret != 0) {
            if ($config->waitFail() or $config->autoSnapshot()) {
                $stop = 1;
                $msg = "Test failed and wait on failure was requested.";
            } elsif ($test->critical()) {
                $critical = 1;
            }
        }

        if ($stop) {
            while (1) {
                if ($stopBefore and $config->autoSnapshot() and ANSTE::askForRevert()) {
                    ANSTE::info("Reverting snapshot of $host...");
                    $self->_virt()->revertSnapshot($host, ANSTE::snapshotName());
                    ANSTE::info('Snapshot reverted');
                }
                if (ANSTE::askForRepeat($msg) == 0) {
                    last;
                } else {
                    $self->{retest} = 1;
                    my $testResult = $self->_runOneTest($test, $testNumber, $testTotalNumber);
                    if ($testResult) {
                        $self->_addResultToReport($report, $suiteResult, $testResult);
                        last if ($testResult->value() == 0);
                    }
                }
            }
        }

        if ($critical) {
            $executeOnlyForcedTests = 1;
        }
    }

    if ($config->step()) {
        my $key;
        while (1) {
            print "Press 'd' to destroy scenario.\n";
            $key = ANSTE::Util::readChar();
            if ($key eq 'd') {
                last;
            }
        }
    }
}

sub _runOneTest
{
    my ($self, $test, $idx, $total) = @_;

    if ($self->{retest}) {
        $test->reloadVars();
    }

    my $testName = $test->name();
    my $testHost = $test->host();
    my $testType = $test->type();
    if ($testType eq '') {
        $testType = 'script';
    } elsif ($testType eq 'web') {
        $testType = $self->{config}->browser();
    }
    print "Running $testType test ($idx/$total): $testName in host $testHost\n";
    my ($testResult, $ret);
    try {
        my $tries = $test->tries();
        while ($tries) {
            if ($test->tries() > 1){
                ANSTE::info("Number of tries left $tries...")
            }
            $testResult = $self->_runTest($test);
            $ret = $testResult->value();
            last if ($ret == 0);
            $tries--;
        }
        if ($ret != 0) {
            $self->{errors}++;
        }
    } catch (ANSTE::Exceptions::NotFound $e) {
        my $what = $e->what();
        my $value = $e->value();
        print STDERR "Error running test $testName.\n";
        print STDERR "Reason: $what $value not found.\n";
        $ret = -1;
    }
    print "Result: $ret\n\n";
    return $testResult;
}

sub _runTest
{
    my ($self, $test) = @_;

    my $system = $self->{system};
    my $name = $test->name();
    my $hostname = $test->host();
    my $type = $test->type();

    my $config = ANSTE::Config->instance();
    my $verbose = $config->verbose();
    my $video = $config->webVideo();

    my $suiteDir = $self->{suite}->dir();
    my $testScript = $test->script();

    my $path;
    if ($testScript) {
        if ($testScript =~ m{/}) {
            $path = "tests/$testScript";
        } else {
            $path = $config->testFile("$suiteDir/$testScript");
        }
        unless ($path) {
            throw ANSTE::Exceptions::NotFound("In test '$name', script '$testScript'");
        }
    } else {
        my $cmd = $test->shellcmd();
        if ($cmd) {
            my ($fh, $filename) = tempfile() or die "Can't create temporary script file: $!";
            $path = $filename;
            print $fh "#!/bin/bash\n";
            print $fh "$cmd\n";
            close($fh) or die "Can't close temporary script file: $!";
        }
    }

    my $logPath = $config->logPath();

    # Create directories
    use File::Path;
    mkpath "$logPath/$suiteDir";
    mkdir "$logPath/$suiteDir/video" if $config->webVideo();
    mkdir "$logPath/$suiteDir/script";

    my ($logfile, $ret);

    my $testResult = new ANSTE::Report::TestResult();
    $testResult->setTest($test);

    # Store start time
    $testResult->setStartTime($self->_time());

    # Create a temp directory for this test
    my $id = $config->identifier();
    my $newPath = "/var/tmp/anste-tests/$id/$name";
    system ("rm -rf $newPath");
    system ("mkdir -p $newPath");

    if ($type eq 'reboot') {
        $ret = $self->_reboot($hostname);

        # Store end time
        my $endTime = $self->_time();
        $testResult->setEndTime($endTime);
    } elsif ($type eq 'sikuli') {
        if (not -d $path) {
            throw ANSTE::Exceptions::NotFound('Test dir', $path);
        }

        $logfile = "$logPath/$suiteDir/$name.txt";
        my $scriptfile = "$logPath/$suiteDir/script/$name.txt";

        my $execScript = $self->_prepareSikuliScript($path, $newPath, $test, $scriptfile);

        my $initialTime = time();

        $ret = $self->_runScriptOnHost($hostname, $execScript, $logfile);

        $self->_finalizeLog($logfile, $test, $testResult, $initialTime, $ret, $verbose);
        $self->_takeScreenshot($test,"$logPath/$suiteDir/$name.ppm",$ret);
    } else {
        if (not -r $path) {
            $path = $config->scriptFile($testScript);
            if (not -r $path) {
                throw ANSTE::Exceptions::NotFound('Test script',
                                              "$suiteDir/$testScript");
            }
        }

        $logfile = "$logPath/$suiteDir/$name.txt";
        my $scriptfile = "$logPath/$suiteDir/script/$name.txt";

        # Copy to temp directory dereferencing links and rename to test name
        my $execScript = "$newPath/$name";
        system("cp $path $execScript");
        system("cp -r lib/* $newPath/") if (-d 'lib');
        system("chmod +x $execScript");

        my $env = $test->env();
        my $params = $test->params();

        # Copy the script to the results adding env and params
        my $SCRIPT;
        open ($SCRIPT, '>', $scriptfile);
        binmode ($SCRIPT, ':utf8');

        if ($env) {
            my $envStr = "# Environment passed to the test:\n";
            $envStr .= "# $env\n";
            print $SCRIPT $envStr;
        }
        if ($params) {
            my $paramsStr = "# Arguments passed to the test: $params\n";
            print $SCRIPT $paramsStr;
        }
        my $scriptContent = read_file($path);
        print $SCRIPT "# Test script executed:\n";
        print $SCRIPT $scriptContent;
        close ($SCRIPT);

        my $initialTime = time();

        if ($type eq 'host') {
            $ret = $self->{system}->runTest($execScript,
                                             $logfile, $env, $params);
        } elsif ($type eq 'web') {
            my $videofile;
            if ($video) {
                $videofile = "$logPath/$suiteDir/video/$name.ogv";
                print "Starting video recording for test $name...\n" if $verbose;
                $system->startVideoRecording($videofile);
            }

            $ret = $self->_runWebTest($test, $execScript, $logfile);

            if ($video) {
                print "Ending video recording for test $name... " if $verbose;
                $system->stopVideoRecording();
                print "Done.\n" if $verbose;

                # If test was correct and record all videos option
                # is not activated, delete the video
                if (($ret == 0) and not $config->webRecordAll()) {
                    unlink ($videofile);
                } else {
                    $testResult->setVideo("$suiteDir/video/$name.ogv");
                }
            }
        } else {
            $ret = $self->_runScriptOnHost($hostname, $execScript,
                                           $logfile, $env, $params);
        }

        $self->_finalizeLog($logfile, $test, $testResult, $initialTime, $ret, $verbose);
    }

    # Invert the result of the test when checking for fail
    my $assertFailed = $test->assert() eq 'failed';
    if ($assertFailed) {
        $ret = ($ret != 0) ? 0 : 1;
    }
    $testResult->setValue($ret);

    return $testResult;
}

sub _addResultToReport
{
    my ($self, $report, $suiteResult, $testResult) = @_;

    my $config = ANSTE::Config->instance();
    my $logPath = $config->logPath();

    $suiteResult->add($testResult);
    my $name = $testResult->test()->name();
    my $dir = $suiteResult->suite()->dir();
    my $dest = "$logPath/$dir/$name.png";

    if (-f 'fail.png') {
        system ("mv fail.png $dest");
    }

    # Write test reports
    foreach my $writer (@{$self->{writers}}) {
        $writer->write("$logPath/" . $writer->filename());
    }
    $report->setTime($self->_time());
}

sub _finalizeLog
{
    my ($self, $logfile, $test, $testResult, $initialTime, $ret, $verbose) = @_;

    my $name = $test->name();
    my $assertFailed = $test->assert() eq 'failed';

    # Store end time
    my $endTime = $self->_time();
    $testResult->setEndTime($endTime);
    $testResult->setDuration(time() - $initialTime);

    if (ANSTE::Config->instance()->verbose()) {
        if (($assertFailed and ($ret == 0)) or
            (not $assertFailed) and ($ret != 0)) {
            system ("cat $logfile");
        }
    }

    # Editing the log to write the starting and ending times.
    my $contents = read_file($logfile);
    my $LOG;
    open($LOG, '>', $logfile);
    my $startTime = $testResult->startTime();
    print $LOG "Starting test '$name' at $startTime.\n\n";
    print $LOG $contents;
    print $LOG "\nTest finished at $endTime.\n";
    close($LOG);

    $testResult->setLog("$logfile");
    my $suiteDir = $self->{suite}->dir();
    $testResult->setScript("$suiteDir/script/$name.txt");
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

sub _reboot
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

sub _uploadFileToHost
{
    my ($self, $hostname, $file) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($file);
}

sub _runScriptOnHost
{
    my ($self, $hostname, $script, $log, $env, $params) = @_;

    my $client = new ANSTE::Comm::MasterClient();

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->{hostIP}->{$hostname};

    $client->connect("http://$ip:$port");

    $client->put($script);
    if (defined $log) {
        $client->exec($script, $log, $env, $params);
    } else {
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
    my $relativeURL = $test->relativeURL();
    my $externalHost = $test->externalHost();

    my $host;
    if ($externalHost) {
        $host = $hostname;
    } else {
        if (not exists $self->{hostIP}->{$hostname}) {
            throw ANSTE::Exceptions::Error("Inexistent hostname $hostname");
        }

        my $ip = $self->{hostIP}->{$hostname};
        if (not $ip) {
            throw ANSTE::Exceptions::Error("Hostname $hostname has not IP! " .
                                           Dumper( $self->{hostIP}->{$hostname}));
        }
        $host = $ip;
    }

    my $config = ANSTE::Config->instance();

    unless ($port) {
        $port = $config->webPort();
    }

    unless ($protocol) {
        $protocol = $config->webProtocol();
    }

    my $url = "$protocol://$host";
    if (defined ($port)) {
        $url .= ":$port";
    }
    if (defined ($relativeURL)) {
        $url .= "/$relativeURL";
    }

    $test->setVariable('BASE_URL', $url);
    $test->setVariable('LC_ALL', 'C');
    my $env = $test->env("\n");

    return $self->{system}->runTest($script, $logfile, $env, '');
}

sub _prepareSikuliScript
{
    my ($self, $path, $newPath, $test, $scriptfile) = @_;

    my $basename = basename($path);
    my $logPath = ANSTE::Config->instance()->logPath();
    my $name = $test->name();
    my $hostname = $test->host();

    # Copy to temp directory dereferencing links and rename to test name
    system ("cp -r $path $newPath");
    system ("cp -r sikuli-lib/* $newPath/$basename") if (-d 'sikuli-lib');

    # Generate and upload test zip
    my $zipFile = "$newPath/$name.zip";
    unless (system("cd $newPath && zip -qr $zipFile $basename") == 0) {
        ANSTE::Exceptions::Error("Could not generate zip file '$zipFile'");
    }
    $self->_uploadFileToHost($hostname, $zipFile);

    my $env = $test->env();
    my $variables = $test->variables();

    # Generate test script
    my $execScript = "$newPath/$name.cmd";
    my @scriptContent;
    push (@scriptContent, "cd ../anste-bin/\n");
    push (@scriptContent, "\"C:\\Program Files\\7-Zip\\7z.exe\" x -y $name.zip\n");
    push (@scriptContent, "set current=\%cd\%\n");
    push (@scriptContent, "c: & cd c:\\sikuli\n");
    push (@scriptContent, "echo \%errorlevel\%\n");
    while (my ($name, $value) = each(%{$variables})) {
        push (@scriptContent, "set $name=$value\n");
    }
    push (@scriptContent, "call runIDE.cmd -r \"\%current\%\\$basename\"\n");
    write_file($execScript, @scriptContent);

    # Copy the script to the results
    my $SCRIPT;
    open ($SCRIPT, '>', $scriptfile);
    binmode ($SCRIPT, ':utf8');

    if ($env) {
        my $envStr = "# Environment passed to the test:\n";
        $envStr .= "# $env\n";
        print $SCRIPT $envStr;
    }

    my $scriptContent = read_file($execScript);
    print $SCRIPT "# Test script executed:\n";
    print $SCRIPT $scriptContent;
    close ($SCRIPT);

    return $execScript
}

sub _virt
{
    my ($self) = @_;

    unless ($self->{virt}) {
        $self->{virt} = ANSTE::Virtualizer::Virtualizer->instance();
    }

    return $self->{virt};
}

sub _takeScreenshot
{
    my ($self, $test, $file, $ret) = @_;

    my $assertFailed = $test->assert() eq 'failed';
    my $hostname = $test->host();

    if (($assertFailed and ($ret == 0)) or
        (not $assertFailed) and ($ret != 0)) {
        $self->_virt()->takeScreenshot($hostname, $file);
    }

}

1;

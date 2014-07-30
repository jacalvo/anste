# Copyright (C) 2009 José Antonio Calvo Fernández <jacalvo@ebox-platform.com>
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

package ANSTE::Test::Validator;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Test::Suite;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;
use ANSTE::Exceptions::NotFound;

use Cwd;
use File::Temp qw(tempdir);
use TryCatch::Lite;
use File::Slurp;

my $SUITE_FILE = 'suite.html';

# Class: Validator
#
#   Class used to run separate test suites or entire directories
#   containing several suites.
#

# Constructor: new
#
#   Constructor for Validator class.
#
# Returns:
#
#   A recently created <ANSTE::Test::Validator> object.
#
sub new
{
    my ($class) = @_;
    my $self = {};

    bless($self, $class);

    return $self;
}

# Method: validateSuite
#
#   Validates a given suite of tests.
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
sub validateSuite
{
    my ($self, $suite, $scenario) = @_;

    defined $suite or
        throw ANSTE::Exceptions::MissingArgument('suite');

    if (not $suite->isa('ANSTE::Test::Suite')) {
        throw ANSTE::Exception::InvalidType('suite',
                                            'ANSTE::Test::Suite');
    }

    my $config = ANSTE::Config->instance();

    my %validHosts = map { $_->name() => 1 } @{$scenario->hosts()};

    foreach my $test (@{$suite->tests()}) {
        my $suiteDir = $suite->dir();
        my $testScript = $test->script();
        my $testHost = $test->host();
        my $testName = $test->name();
        my $externalHost = $test->externalHost();

        if ($testHost and not $externalHost and (not exists $validHosts{$testHost})) {
            throw ANSTE::Exceptions::Error("Host $testHost from test $testName not defined in scenario");
        }

        my $path;
        if ($testScript =~ m{/}) {
            $path = "tests/$testScript";
        } else {
            $path = $config->testFile("$suiteDir/$testScript");
        }

        unless ((-r $path) or ($test->type() eq 'reboot') or $test->{postScript}) {
            throw ANSTE::Exceptions::NotFound('Test script', "$path");
        }
    }
}

1;

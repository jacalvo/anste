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

package ANSTE::Test::Suite;

use strict;
use warnings;

use ANSTE::Test::Test;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::Error;

use Text::Template;
use Safe;
use YAML::XS;

# Class: Suite
#
#   Contains the information of a test suite.
#

# Constructor: new
#
#   Constructor for Suite class.
#
# Returns:
#
#   A recently created <ANSTE::Test::Suite> object.
#
sub new
{
    my ($class, $dir) = @_;
    my $self = {};

    $self->{name} = '';
    $self->{desc} = '';
    $self->{dir} = '';
    $self->{scenario} = '';
    $self->{tests} = [];

    bless($self, $class);

    return $self;
}

# Method: name
#
#   Gets the name of the test suite.
#
# Returns:
#
#   string - Name of the test suite.
#
sub name
{
    my ($self) = @_;

    return $self->{name};
}

# Method: setName
#
#   Sets the name for this test suite object to the given value.
#
# Parameters:
#
#   name - String with the name for the test suite.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setName
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    $self->{name} = $name;
}

# Method: desc
#
#   Gets the description of the test suite.
#
# Returns:
#
#   string - Description of the test suite.
#
sub desc
{
    my ($self) = @_;

    return $self->{desc};
}

# Method: setDesc
#
#   Sets the description for this test suite object to the given value.
#
# Parameters:
#
#   name - String with the description for the test suite.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setDesc
{
    my ($self, $desc) = @_;

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

    $self->{desc} = $desc;
}

# Method: dir
#
#   Gets the directory of the test suite
#
# Returns:
#
#   string - Name of the directory of the test suite.
#
sub dir
{
    my ($self) = @_;

    return $self->{dir};
}

# Method: setDir
#
#   Sets the directory for this test suite object to the given value.
#
# Parameters:
#
#   name - String with the directory of the test suite.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setDir
{
    my ($self, $dir) = @_;

    defined $dir or
        throw ANSTE::Exceptions::MissingArgument('dir');

    $self->{dir} = $dir;
}

# Method: scenario
#
#   Gets the scenario of this suite, where the tests have to be executed.
#
# Returns:
#
#   string - String with the name of the scenario.
#
sub scenario
{
    my ($self) = @_;

    return $self->{scenario};
}

# Method: setScenario
#
#   Sets the scenario name of this suite to the given value.
#
# Parameters:
#
#   scenario - String with the name of the scenario.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setScenario
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    $self->{scenario} = $scenario;
}

# Method: tests
#
#   Gets the list of all tests of the suite.
#
# Returns:
#
#   list ref - Reference to the list of tests.
#
sub tests
{
    my ($self) = @_;

    $self->{tests};
}

# Method: addTest
#
#   Adds a given test to the suite.
#
# Parameters:
#
#   test - <ANSTE::Test::Test> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub addTest
{
    my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    push(@{$self->{tests}}, $test);
}

# Method: loadFromDir
#
#   Loads the information of the test suite at the given directory.
#
# Parameters:
#
#   dirname - String with the name of the directory that contains a file
#             called suite.yaml with the data of the suite.
#
#   varfile - *optional* path of the YAML file containing the new var values
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidFile> - throw if parameter is not a valid suite
#
sub loadFromDir
{
    my ($self, $dirname, $varfile) = @_;

    defined $dirname or
        throw ANSTE::Exceptions::MissingArgument('dirname');

    $self->setDir($dirname);

    my $config = ANSTE::Config->instance();
    my $file = $config->testFile("$dirname/suite.yaml");
    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('dirname', $file);
    }
    $self->{file} = $file;

    my $template = new Text::Template(SOURCE => $file)
        or die "Couldn't construct template: $Text::Template::ERROR";
    my $variables = $config->variables();
    my $text = $template->fill_in(HASH => $variables, SAFE => new Safe)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    my ($suite) = YAML::XS::Load($text);

    # Read name and description of the suite
    my $name = $suite->{name};
    $self->setName($name);
    my $desc = $suite->{desc};
    $self->setDesc($desc);

    # Read the scenario filename
    my $scenario = $suite->{scenario};
    $self->setScenario($scenario);

    # Check for duplicated tests
    my %seenTests;

    my $global = $suite->{global};
    my $newGlobal = undef;
    my $varTests = {};

    if ($varfile) {
        my ($vars) = YAML::XS::LoadFile($varfile);
        $newGlobal = $vars->{global};
        foreach my $element (@{$vars->{tests}}) {
            $varTests->{$element->{name}} = $element->{vars};
        }
        $self->{varfile} = $varfile;
    }

    foreach my $element (@{$suite->{tests}}) {
        my $test = new ANSTE::Test::Test($self);
        $test->addVariables($global);
        $test->addVariables($newGlobal) if $newGlobal;
        $test->loadYAML($element);

        my $name = $test->name();
        if ($seenTests{$name}) {
            throw ANSTE::Exceptions::Error("Duplicated test found: $name");
        }
        $seenTests{$name} = 1;

        if (exists $varTests->{$name}) {
            $test->addVariables($varTests->{$name});
        }

        if ($test->precondition()) {
            $self->addTest($test);
        }
    }
}

1;

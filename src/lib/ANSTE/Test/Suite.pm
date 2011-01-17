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

use Text::Template;
use Safe;
use XML::DOM;

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
sub new # returns new TestSuite object
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
sub name # returns name string
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
sub setName # name string
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
sub desc # returns desc string
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
sub setDesc # desc string
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
sub dir # returns dir string
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
sub setDir # dir string
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
sub scenario # returns scenario string
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
sub setScenario # scenario string
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
sub tests # return tests list ref
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
sub addTest # (test)
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
#             called suite.xml with the data of the suite.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidFile> - throw if parameter is not a valid suite
#
sub loadFromDir # (dirname)
{
	my ($self, $dirname) = @_;

    defined $dirname or
        throw ANSTE::Exceptions::MissingArgument('dirname');

    $self->setDir($dirname);

    my $file = ANSTE::Config->instance()->testFile("$dirname/suite.xml");

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('dirname', $file);
    }

    my $template = new Text::Template(SOURCE => $file)
        or die "Couldn't construct template: $Text::Template::ERROR";
    my $variables = ANSTE::Config->instance()->variables();
    my $text = $template->fill_in(HASH => $variables, SAFE => new Safe)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

	my $parser = new XML::DOM::Parser;
    my $doc;
    eval {
        $doc = $parser->parse($text);
    };
    if ($@) {
        throw ANSTE::Exceptions::Error("Error parsing $file: $@");
    }

	my $suite = $doc->getDocumentElement();

	# Read name and description of the suite
	my $nameNode = $suite->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);
	my $descNode = $suite->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

    # Read the scenario filename
	my $scenarioNode = $suite->getElementsByTagName('scenario', 0)->item(0);
	my $scenario = $scenarioNode->getFirstChild()->getNodeValue();
	$self->setScenario($scenario);

	# Read the <test> elements
	foreach my $element ($suite->getElementsByTagName('test', 0)) {
		my $test = new ANSTE::Test::Test();
		$test->load($element);
        if ($test->precondition()) {
		    $self->addTest($test);
        }
	}

	$doc->dispose();
}

1;

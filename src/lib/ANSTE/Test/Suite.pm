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

package ANSTE::Test::Suite;

use strict;
use warnings;

use ANSTE::Test::Test;
use ANSTE::Exceptions::MissingArgument;

use XML::DOM;

sub new # (dir) returns new TestSuite object
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

sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

sub setName # name string
{
	my ($self, $name) = @_;	

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

sub desc # returns desc string
{
	my ($self) = @_;

	return $self->{desc};
}

sub setDesc # desc string
{
	my ($self, $desc) = @_;	

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

	$self->{desc} = $desc;
}

sub dir # returns dir string
{
	my ($self) = @_;

	return $self->{dir};
}

sub setDir # dir string
{
	my ($self, $dir) = @_;	

    defined $dir or
        throw ANSTE::Exceptions::MissingArgument('dir');

	$self->{dir} = $dir;
}

sub scenario # returns scenario string
{
	my ($self) = @_;

	return $self->{scenario};
}

sub setScenario # scenario string
{
	my ($self, $scenario) = @_;	

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

	$self->{scenario} = $scenario;
}

sub tests # return tests list ref
{
    my ($self) = @_;

    $self->{tests};
}

sub addTest # (test)
{
    my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    push(@{$self->{tests}}, $test);
}

sub loadFromDir # (dirname)
{
	my ($self, $dirname) = @_;

    defined $dirname or
        throw ANSTE::Exceptions::MissingArgument('dirname');

    $self->setDir($dirname);

    my $file = ANSTE::Config->instance()->testFile("$dirname/suite.xml");

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile($file);
    }

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($file);

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
		$self->addTest($test);
	}

	$doc->dispose();
}

1;

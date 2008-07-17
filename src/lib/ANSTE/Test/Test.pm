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

package ANSTE::Test::Test;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;

use XML::DOM;

# Class: Test
#
#   Contains the information of a test.
#

# Constructor: new
#
#   Constructor for Test class.
#
# Returns:
#
#   A recently created <ANSTE::Test::Test> object.
#
sub new # returns new Test object
{
	my ($class) = @_;
	my $self = {};

    $self->{name} = '';
    $self->{desc} = '';
    $self->{dir} = '';
    $self->{assert} = 'passed';
    $self->{selenium} = 0;
	
	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the name of the test.
#
# Returns:
#
#   string - Name of the test.
#
sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

# Method: setName
#
#   Sets the name for this test object to the given value.
#
# Parameters:
#
#   name - String with the name for the test.
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
#   Gets the description of the test.
#
# Returns:
#
#   string - Description of the test.
#
sub desc # returns desc string
{
	my ($self) = @_;

	return $self->{desc};
}

# Method: setDesc
#
#   Sets the description for this test object to the given value.
#
# Parameters:
#
#   name - String with the description for the test.
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

# Method: assert
#
#   Gets the assertion type of the test.
#
# Returns:
#
#   string - Name of the assertectory of this test.
#
sub assert # returns assert string
{
	my ($self) = @_;

	return $self->{assert};
}

# Method: setAssert
#
#   Sets the assertion type of the test.
#
# Parameters:
#
#   assert - String with 'passed' or 'failed'.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setAssert # assert string
{
	my ($self, $assert) = @_;

    defined $assert or
        throw ANSTE::Exceptions::MissingArgument('assert');

	$self->{assert} = $assert;
}

# Method: host
#
#   Gets the host where the test have to be executed.
#
# Returns:
#
#   string - Hostname where execute the test.
#
sub host # returns host string
{
	my ($self) = @_;

	return $self->{host};
}

# Method: setHost
#
#   Sets the execution host for this test object to the given value.
#
# Parameters:
#
#   name - String with the hostname where the test have to be executed.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setHost # host string
{
	my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

	$self->{host} = $host;
}

# Method: dir
#
#   Gets the directory of the test scripts.
#
# Returns:
#
#   string - Name of the directory of this test.
#
sub dir # returns dir string
{
	my ($self) = @_;

	return $self->{dir};
}

# Method: setDir
#
#   Sets the directory for this test object to the given value.
#
# Parameters:
#
#   name - String with the relative path of the test directory.
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

# Method: selenium
#
#   Gets if this is a selenium test.
#
# Returns:
#
#   boolean - true if it's a selenium test, false if not
#
sub selenium # returns boolean
{
    my ($self) = @_;

    return $self->{selenium};
}

# Method: setSelenium
#
#   Specifies that this test is a Selenium one. 
#
sub setSelenium
{
    my ($self) = @_;

    $self->{selenium} = 1;
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the test into this object.
#
# Parameters:
#
#   node - <XML::DOM::Element> object containing the test data.    
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidType> - throw if parameter has wrong type
#
sub load # (node)
{
	my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                                             'XML::DOM::Element');
    }

	my $type = $node->getAttribute('type');
    if ($type eq 'selenium') {
        $self->setSelenium();
    }

	my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);

	my $descNode = $node->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	my $hostNode = $node->getElementsByTagName('host', 0)->item(0);
	my $host = $hostNode->getFirstChild()->getNodeValue();
    $self->setHost($host);

	my $dirNode = $node->getElementsByTagName('dir', 0)->item(0);
	my $dir = $dirNode->getFirstChild()->getNodeValue();
    $self->setDir($dir);

	my $assertNode = $node->getElementsByTagName('assert', 0)->item(0);
    if ($assertNode) {
    	my $assert = $assertNode->getFirstChild()->getNodeValue();
        $self->setAssert($assert);
    }
}

1;

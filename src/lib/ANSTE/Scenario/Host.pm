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

package ANSTE::Scenario::Host;

use strict;
use warnings;

use ANSTE::Scenario::BaseImage;
use ANSTE::Scenario::Network;
use ANSTE::Scenario::Packages;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use XML::DOM;

# Class: Host
#
#   Contains the information for a host of a scenario. 
#

# Constructor: new
#
#   Constructor for Host class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::Host> object.
#
sub new # returns new Host object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
    $self->{baseImage} = new ANSTE::Scenario::BaseImage;
	$self->{network} = new ANSTE::Scenario::Network;
	$self->{packages} = new ANSTE::Scenario::Packages;
    $self->{'pre-scripts'} = [];
    $self->{'post-scripts'} = [];

	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the name of the host.
#
# Returns:
#
#   string - contains the host name
#
sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

# Method: setName
#
#   Sets the name of the host.
#
# Parameters:
#
#   name - String with the name of the host.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
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
#   Gets the description of the host.
#
# Returns:
#
#   string - contains the host description
#
sub desc # returns desc string
{
	my ($self) = @_;
	return $self->{desc};
}

# Method: setDesc
#
#   Sets the description of the host.
#
# Parameters:
#
#   desc - String with the description of the host.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setDesc # desc string
{
	my ($self, $desc) = @_;	

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

	$self->{desc} = $desc;
}

# Method: memory
#
#   Gets the memory size string.
#
# Returns:
#
#   string - contains the memory size
#
sub memory # returns memory string 
{
	my ($self) = shift;

	return $self->{memory};
}

# Method: setMemory
#
#   Sets the memory size string.
#
# Parameters:
#
#   memory - String with the memory size.    
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setMemory # (memory)
{
	my ($self, $memory) = @_;

    defined $memory or
        throw ANSTE::Exceptions::MissingArgument('memory');

	$self->{memory} = $memory;
}

# Method: baseImage
#
#   Gets the object with the information of the base image of the host.
#
# Returns:
#
#   ref - <ANSTE::Scenario::BaseImage> object.
#
sub baseImage # returns BaseImage object
{
	my ($self) = @_;

	return $self->{baseImage};
}

# Method: setBaseImage
#
#   Sets the object with the information of the base image of the host.
#
# Parameters:
#
#   baseImage - <ANSTE::Scenario::BaseImage> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setBaseImage # (baseImage)
{
	my ($self, $baseImage) = @_;	

    defined $baseImage or
        throw ANSTE::Exceptions::MissingArgument('baseImage');

    if (not $baseImage->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exceptions::InvalidType('baseImage',
                                             'ANSTE::Scenario::BaseImage');
    }

	$self->{baseImage} = $baseImage;
}

# Method: network
#
#   Gets the object with the network configuration for the host.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Network> object.
#
sub network # returns Network object
{
	my ($self) = @_;

	return $self->{network};
}

# Method: setNetwork
#
#   Sets the object with the network configuration for the host.
#
# Parameters:
#
#   network - <ANSTE::Scenario::Network> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setNetwork # (network)
{
	my ($self, $network) = @_;	

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    if (not $network->isa('ANSTE::Scenario::Network')) {
        throw ANSTE::Exceptions::InvalidType('network',
                                             'ANSTE::Scenario::Network');
    }

	$self->{network} = $network;
}

# Method: packages
#
#   Gets the object with the information of packages to be installed.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Packages> object.
#
sub packages # returns Packages object
{
	my ($self) = @_;

	return $self->{packages};
}

# Method: setPackages
#
#   Sets the object with the information of packages to be installed.
#
# Parameters:
#
#   packages - <ANSTE::Scenario::Packages> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setPackages # (packages)
{
	my ($self, $packages) = @_;

    defined $packages or
        throw ANSTE::Exceptions::MissingArgument('packages');

    if (not $packages->isa('ANSTE::Scenario::Packages')) {
        throw ANSTE::Exceptions::InvalidType('packages',
                                             'ANSTE::Scenario::Packages');
    }

	$self->{packages} = $packages;
}

# Method: preScripts
#
#   Gets the list of scripts that have to be executed before the setup.
#
# Returns:
#
#   ref - reference to the list of script names
#
sub preScripts # returns list
{
    my ($self) = @_;

    return $self->{'pre-scripts'};
}

# Method: postScripts
#
#   Gets the list of scripts that have to be executed after the setup.
#
# Returns:
#
#   ref - reference to the list of script names
#
sub postScripts # returns list
{
    my ($self) = @_;

    return $self->{'post-scripts'};
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the host configuration into this object.
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

	my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);

	my $descNode = $node->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	my $memoryNode = $node->getElementsByTagName('memory', 0)->item(0);
    if ($memoryNode) {
    	my $memory = $memoryNode->getFirstChild()->getNodeValue();
	    $self->setMemory($memory);
    }        

	my $baseimageNode = $node->getElementsByTagName('baseimage', 0)->item(0);
	my $baseimage = $baseimageNode->getFirstChild()->getNodeValue();
	$self->baseImage()->loadFromFile("$baseimage.xml");

	my $networkNode = $node->getElementsByTagName('network', 0)->item(0);
	if($networkNode){
		$self->network()->load($networkNode);
	}

	my $packagesNode = $node->getElementsByTagName('packages', 0)->item(0);
	if($packagesNode){
		$self->packages()->load($packagesNode);
	}

	my $preNode = $node->getElementsByTagName('pre-install', 0)->item(0);
	if($preNode){
        $self->_addScripts('pre-scripts', $preNode);
	}

	my $postNode = $node->getElementsByTagName('post-install', 0)->item(0);
	if($postNode){
        $self->_addScripts('post-scripts', $postNode);
	}
}

sub _addScripts # (list, node)
{
    my ($self, $list, $node) = @_;

	foreach my $scriptNode ($node->getElementsByTagName('script', 0)) {
        my $script = $scriptNode->getFirstChild()->getNodeValue();
    	push(@{$self->{$list}}, $script);
    }
}


1;

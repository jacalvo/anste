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

package ANSTE::Scenario::BaseImage;

use strict;
use warnings;

use ANSTE::Scenario::Packages;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use XML::DOM;

# Class: BaseImage
#
#   Contains the information to build a system base image.
#

# Constructor: new
#
#   Constructor for BaseImage class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::BaseImage> object.
#
sub new # returns new BaseImage object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
	$self->{memory} = '';
	$self->{size} = '';
	$self->{swap} = '';
	$self->{installMethod} = '';
	$self->{installSource} = '';
	$self->{packages} = new ANSTE::Scenario::Packages();
    $self->{'pre-scripts'} = [];
    $self->{'post-scripts'} = [];

	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the name of the image.
#
# Returns:
#
#   string - contains the image name
#
sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

# Method: setName
#
#   Sets the name of the image.
#
# Parameters:
#
#   name - String with the name of the image.
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
#   Gets the description of the image.
#
# Returns:
#
#   string - contains the image description
#
sub desc # returns desc string
{
	my ($self) = @_;

	return $self->{desc};
}

# Method: setDesc
#
#   Sets the description of the image.
#
# Parameters:
#
#   desc - String with the description of the image.
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

# Method: size
#
#   Gets the size of the image.
#
# Returns:
#
#   string - contains the size of the image
#
sub size # returns size string
{
	my ($self) = @_;

	return $self->{size};
}

# Method: setSize
#
#
#   Sets the size of the image.
#
# Parameters:
#
#   size - String with the size of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setSize # size string
{
	my ($self, $size) = @_;	

    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

	$self->{size} = $size;
}

# Method: swap
#
#   Gets the size of the swap partition.
#
# Returns:
#
#   string - contains the size of the image
#
sub swap # returns size string
{
	my ($self) = @_;

	return $self->{swap};
}

# Method: setSwap
#
#
#   Sets the size of the swap partition.
#
# Parameters:
#
#   size - String with the size of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setSwap # returns string
{
	my ($self, $size) = @_;	

    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

	$self->{swap} = $size;
}

# Method: installMethod
#
#   Gets the installation method to be used.
#
# Returns:
#
#   string - contains the  name of the installation method
#
sub installMethod # returns string
{
	my ($self) = @_;

	return $self->{installMethod};
}

# Method: setInstallMethod
#
#
#   Sets the installMethod of the installMethod partition.
#
# Parameters:
#
#   installMethod - String with the installMethod of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setInstallMethod # installMethod string
{
	my ($self, $installMethod) = @_;	

    defined $installMethod or
        throw ANSTE::Exceptions::MissingArgument('installMethod');

	$self->{installMethod} = $installMethod;
}

# Source: installSource
#
#   Gets the installation method to be used.
#
# Returns:
#
#   string - contains the  name of the installation method
#
sub installSource # returns string
{
	my ($self) = @_;

	return $self->{installSource};
}

# Source: setInstallSource
#
#
#   Sets the installSource of the installSource partition.
#
# Parameters:
#
#   installSource - String with the installSource of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setInstallSource # installSource string
{
	my ($self, $installSource) = @_;	

    defined $installSource or
        throw ANSTE::Exceptions::MissingArgument('installSource');

	$self->{installSource} = $installSource;
}

# Dist: installDist
#
#   Sets the distribution to be installed.
#
# Returns:
#
#   string - contains the name of the distribution
#
sub installDist # returns string
{
	my ($self) = @_;

	return $self->{installDist};
}

# Dist: setInstallDist
#
#
#   Sets the distribution to be installed.
#
# Parameters:
#
#   installDist - String with the name of the distribution
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setInstallDist # installDist string
{
	my ($self, $installDist) = @_;	

    defined $installDist or
        throw ANSTE::Exceptions::MissingArgument('installDist');

	$self->{installDist} = $installDist;
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
sub preScripts # returns list ref
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
sub postScripts # returns list ref
{
    my ($self) = @_;

    return $self->{'post-scripts'};
}

# Method: loadFromFile
#
#   Loads the base image data from a XML file.
#
# Parameters:
#
#   filename - String with the name of the file.
#
# Returns:
#
#   boolean - true if loaded correctly 
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidFile> - throw if argument is not a file
#
sub loadFromFile # (filename)
{
	my ($self, $filename) = @_;

    defined $filename or
        throw ANSTE::Exceptions::MissingArgument('filename');

    my $file = ANSTE::Config->instance()->imageTypeFile($filename);

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('filename');
    }

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($file);

	my $image = $doc->getDocumentElement();

	my $nameNode = $image->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);

	my $descNode = $image->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	my $installNode = $image->getElementsByTagName('install', 0)->item(0);
    my $method = $installNode->getAttribute('method');
    $self->setInstallMethod($method);
    my $distNode = $installNode->getElementsByTagName('dist', 0)->item(0);
    if ($distNode) {
    	my $dist = $distNode->getFirstChild()->getNodeValue();
	    $self->setInstallDist($dist);
    }        
    my $sourceNode = $installNode->getElementsByTagName('source', 0)->item(0);
    if ($sourceNode) {
    	my $source = $sourceNode->getFirstChild()->getNodeValue();
	    $self->setInstallSource($source);
    }        

	my $memoryNode = $image->getElementsByTagName('memory', 0)->item(0);
    if ($memoryNode) {
    	my $memory = $memoryNode->getFirstChild()->getNodeValue();
	    $self->setMemory($memory);
    }        

	my $sizeNode = $image->getElementsByTagName('size', 0)->item(0);
	my $size = $sizeNode->getFirstChild()->getNodeValue();
	$self->setSize($size);

	my $swapNode = $image->getElementsByTagName('swap', 0)->item(0);
    if ($swapNode) {
    	my $swap = $swapNode->getFirstChild()->getNodeValue();
	    $self->setSwap($swap);
    }        

	my $packagesNode = $image->getElementsByTagName('packages', 0)->item(0);
	if ($packagesNode) {
		$self->packages()->load($packagesNode);
	}

	my $preNode = $image->getElementsByTagName('pre-install', 0)->item(0);
	if ($preNode) {
        $self->_addScripts('pre-scripts', $preNode);
	}

	my $postNode = $image->getElementsByTagName('post-install', 0)->item(0);
	if ($postNode) {
        $self->_addScripts('post-scripts', $postNode);
	}

    $doc->dispose();
    return(1);
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

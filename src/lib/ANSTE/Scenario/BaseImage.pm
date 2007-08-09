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

use XML::DOM;

sub new # returns new BaseImage object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
	$self->{memory} = '';
	$self->{size} = '';
	$self->{packages} = new ANSTE::Scenario::Packages();
    $self->{'pre-scripts'} = [];
    $self->{'post-scripts'} = [];

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

sub memory # returns memory string
{
	my ($self) = @_;

	return $self->{memory};
}

sub setMemory # memory string
{
	my ($self, $memory) = @_;	

    defined $memory or
        throw ANSTE::Exceptions::MissingArgument('memory');

	$self->{memory} = $memory;
}

sub size # returns size string
{
	my ($self) = @_;

	return $self->{size};
}

sub setSize # size string
{
	my ($self, $size) = @_;	

    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

	$self->{size} = $size;
}

sub packages # returns Packages object
{
	my ($self) = @_;

	return $self->{packages};
}

sub setPackages # (packages)
{
	my ($self, $packages) = @_;

    defined $packages or
        throw ANSTE::Exceptions::MissingArgument('packages');

	$self->{packages} = $packages;
}

sub preScripts # returns list
{
    my ($self) = @_;

    return $self->{'pre-scripts'};
}

sub postScripts # returns list
{
    my ($self) = @_;

    return $self->{'post-scripts'};
}

sub loadFromFile # (filename)
{
	my ($self, $filename) = @_;

    defined $filename or
        throw ANSTE::Exceptions::MissingArgument('filename');

    # TODO: Throw exception if file doesn't exists

	my $parser = new XML::DOM::Parser;
    my $config = ANSTE::Config->instance();
    my $dir = $config->imageTypePath();
	my $doc = $parser->parsefile("$dir/$filename");

	my $image = $doc->getDocumentElement();

	my $nameNode = $image->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);

	my $descNode = $image->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	my $memoryNode = $image->getElementsByTagName('memory', 0)->item(0);
	my $memory = $memoryNode->getFirstChild()->getNodeValue();
	$self->setMemory($memory);

	my $sizeNode = $image->getElementsByTagName('size', 0)->item(0);
	my $size = $sizeNode->getFirstChild()->getNodeValue();
	$self->setSize($size);

	my $packagesNode = $image->getElementsByTagName('packages', 0)->item(0);
	if($packagesNode){
		$self->packages()->load($packagesNode);
	}

	my $preNode = $image->getElementsByTagName('pre-install', 0)->item(0);
	if($preNode){
        $self->_addScripts('pre-scripts', $preNode);
	}

	my $postNode = $image->getElementsByTagName('post-install', 0)->item(0);
	if($postNode){
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

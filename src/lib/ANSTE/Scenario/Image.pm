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

package ANSTE::Scenario::Image;

use strict;
use warnings;

use ANSTE::Scenario::Packages;

use XML::DOM;

sub new # returns new Image object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = "";
	$self->{desc} = "";
	$self->{packages} = new ANSTE::Scenario::Packages();

	bless($self, $class);

	return $self;
}

sub name # returns name string
{
	my $self = shift;
	return $self->{name};
}

sub setName # name string
{
	my $self = shift;	
	my $name = shift;
	$self->{name} = $name;
}

sub desc # returns desc string
{
	my $self = shift;
	return $self->{desc};
}

sub setDesc # desc string
{
	my $self = shift;	
	my $desc = shift;
	$self->{desc} = $desc;
}

sub packages # returns Packages object
{
	my $self = shift;
	return $self->{packages};
}

sub setPackages # (packages)
{
	my $self = shift;	
	my $packages = shift;
	$self->{packages} = $packages;
}

sub loadFromFile # (filename)
{
	my ($self, $filename) = @_;

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($filename);

	my $image = $doc->getDocumentElement();

	my $nameNode = $image->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);
	my $descNode = $image->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);
	my $packagesNode = $image->getElementsByTagName('packages', 0)->item(0);
	if($packagesNode){
		$self->packages()->load($packagesNode);
	}
}

1;

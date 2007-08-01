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

use ANSTE::Scenario::Network;
use ANSTE::Scenario::Packages;
use XML::DOM;

sub new # returns new Host object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
	$self->{network} = new ANSTE::Scenario::Network;
	$self->{packages} = new ANSTE::Scenario::Packages;

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

	$self->{desc} = $desc;
}

sub network # returns Network object
{
	my ($self) = @_;

	return $self->{network};
}

sub setNetwork # (network)
{
	my ($self, $network) = @_;	

	$self->{network} = $network;
}

sub packages # returns Packages object
{
	my ($self) = @_;

	return $self->{packages};
}

sub setPackages # (packages)
{
	my ($self, $packages) = @_;

	$self->{packages} = $packages;
}

sub load # (dir, node)
{
	my ($self, $dir, $node) = @_;

	my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);
	my $descNode = $node->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);
	my $networkNode = $node->getElementsByTagName('network', 0)->item(0);
	if($networkNode){
		$self->network()->load($networkNode);
	}
	my $packagesNode = $node->getElementsByTagName('packages', 0)->item(0);
	if($packagesNode){
		$self->packages()->load($dir, $packagesNode);
	}
}

1;

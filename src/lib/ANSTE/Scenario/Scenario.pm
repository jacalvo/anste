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

package ANSTE::Scenario::Scenario;

use strict;
use warnings;

use ANSTE::Scenario::Host;
use XML::DOM;

sub new # returns new Scenario object
{
	my $class = shift;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
	$self->{virtualizer} = '';
	$self->{system} = '';
	$self->{hosts} = [];

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

sub virtualizer # returns virtualizer package
{
	my ($self) = @_;

	return $self->{virtualizer};
}

sub setVirtualizer # (virtualizer)
{
	my ($self, $virtualizer) = @_;	

	$self->{virtualizer} = $virtualizer;
}

sub system # returns system package
{
	my ($self) = @_;

	return $self->{system};
}

sub setSystem # (system)
{
	my ($self, $system) = @_;

	$self->{system} = $system;
}

sub hosts # returns hosts list 
{
	my ($self) = @_;

	return $self->{hosts};
}

sub addHost # (host)
{
	my ($self, $host) = @_;	

	push(@{$self->{hosts}}, $host);
}


sub loadFromFile # (dir, filename)
{
	my ($self, $dir, $filename) = @_;

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile("$dir/$filename");

	my $scenario = $doc->getDocumentElement();

	# Read name and description of the scenario
	my $nameNode = $scenario->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);
	my $descNode = $scenario->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	# Load the virtualizer profile
	my $virtualizerNode = 
        $scenario->getElementsByTagName('virtualizer', 0)->item(0);
	my $virtualizer = $virtualizerNode->getFirstChild()->getNodeValue();
	$self->setVirtualizer($virtualizer);

	# Load the system profile
	my $systemNode = 
        $scenario->getElementsByTagName('system', 0)->item(0);
	my $system = $systemNode->getFirstChild()->getNodeValue();
	$self->setSystem($system);


	# Read the <host> elements 
	foreach my $element ($scenario->getElementsByTagName('host', 0)) {
		my $host = new ANSTE::Scenario::Host;
		$host->load($dir, $element);
		$self->addHost($host);
	}

	$doc->dispose();
}

1;

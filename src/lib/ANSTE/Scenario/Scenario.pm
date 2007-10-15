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
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use XML::DOM;

sub new # returns new Scenario object
{
	my ($class) = @_;
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

sub virtualizer # returns virtualizer package
{
	my ($self) = @_;

	return $self->{virtualizer};
}

sub setVirtualizer # (virtualizer)
{
	my ($self, $virtualizer) = @_;	

    defined $virtualizer or
        throw ANSTE::Exceptions::MissingArgument('virtualizer');

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

    defined $system or
        throw ANSTE::Exceptions::MissingArgument('system');

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

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw ANSTE::Exceptions::InvalidType('host',
                                             'ANSTE::Scenario::Host');
    }

	push(@{$self->{hosts}}, $host);
}


sub loadFromFile # (filename)
{
	my ($self, $filename) = @_;

    defined $filename or
        throw ANSTE::Exceptions::MissingArgument('filename');

    my $file = ANSTE::Config->instance()->scenarioFile($filename);

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('filename');
    }

	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($file);

	my $scenario = $doc->getDocumentElement();

	# Read name and description of the scenario
	my $nameNode = $scenario->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);
	my $descNode = $scenario->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	# Read the <host> elements 
	foreach my $element ($scenario->getElementsByTagName('host', 0)) {
		my $host = new ANSTE::Scenario::Host;
		$host->load($element);
		$self->addHost($host);
	}

	$doc->dispose();
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

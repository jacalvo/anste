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

use Text::Template;
use Safe;
use XML::DOM;


# Class: Scenario
#
#   Contains all the information of a scenario needed for its deployment.
#

# Constructor: new
#
#   Constructor for Scenario class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::Scenario> object.
#
sub new # returns new Scenario object
{
	my ($class) = @_;
	my $self = {};
	
	$self->{name} = '';
	$self->{desc} = '';
	$self->{virtualizer} = '';
	$self->{system} = '';
	$self->{hosts} = [];
    $self->{bridges} = {};

	bless($self, $class);

	return $self;
}

# Method: name
#
#   Gets the name of the scenario.
#
# Returns:
#
#   string - contains the scenario name
#
sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

# Method: setName
#
#   Sets the name of the scenario. 
#
# Parameters:
#
#   name - String with the name of the scenario.
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
#   Gets the description of the scenario.
#
# Returns:
#
#   string - contains the scenario description
#
sub desc # returns desc string
{
	my ($self) = @_;

	return $self->{desc};
}

# Method: setDesc
#
#   Sets the description of the scenario.
#
# Parameters:
#
#   desc - String with the description of the scenario.
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

# Method: virtualizer
#
#   Gets the virtualizer backend for this scenario.
#
# Returns:
#
#   string - contains the virtualizer backend name
#
sub virtualizer # returns virtualizer package
{
	my ($self) = @_;

	return $self->{virtualizer};
}

# Method: setVirtualizer
#
#   Sets the virtualizer backend for this scenario.
#
# Parameters:
#
#   virtualizer - String with the virtualizer backend name.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setVirtualizer # (virtualizer)
{
	my ($self, $virtualizer) = @_;	

    defined $virtualizer or
        throw ANSTE::Exceptions::MissingArgument('virtualizer');

	$self->{virtualizer} = $virtualizer;
}

# Method: system
#
#   Gets the system backend for this scenario.
#
# Returns:
#
#   string - contains the system backend name
#
sub system # returns system package
{
	my ($self) = @_;

	return $self->{system};
}

# Method: setSystem
#
#   Sets the system backend for this scenario.
#
# Parameters:
#
#   system - String with the system backend name.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setSystem # (system)
{
	my ($self, $system) = @_;

    defined $system or
        throw ANSTE::Exceptions::MissingArgument('system');

	$self->{system} = $system;
}

# Method: hosts
#
#   Gets the list of hosts.
#
# Returns:
#
#   ref - list of <ANSTE::Scenario::Host> objects
#
sub hosts # returns hosts list 
{
	my ($self) = @_;

	return $self->{hosts};
}

# Method: addHost
#
#   Adds a host to the scenario list of hosts.
#
# Parameters:
#
#   host - <ANSTE::Scenario::Host> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if parameter has wrong type
#
sub addHost # (host)
{
	my ($self, $host) = @_;	

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw ANSTE::Exceptions::InvalidType('host',
                                             'ANSTE::Scenario::Host');
    }

    $host->setScenario($self);

	push(@{$self->{hosts}}, $host);
}

# Method: bridges
#
#   Gets the hash of bridges, indexed by network address.
#
# Returns:
#
#   hash ref - list of <ANSTE::Scenario::NetworkBridge> objects 
#
sub bridges # returns bridges hash reference
{
    my ($self) = @_;

    return $self->{bridges};
}

# Method: addBridge
#
#   Adds a bridge for the specified network address if not exists previously.
#
# Parameters:
#
#   network - beggining of network address string (three first octects).
#
# Returns:
#
#   scalar  - bridge number
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub addBridge # (network)
{
    my ($self, $network) = @_;

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    if (not $self->{bridges}->{$network}) {
        my $num_bridges = scalar(keys %{$self->{bridges}});
        $num_bridges++;
        $self->{bridges}->{$network} = $num_bridges;
    }
    return $self->{bridges}->{$network};
}

# Method: loadFromFile
#
#   Loads the scenario data from a XML file.
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

    my $file = ANSTE::Config->instance()->scenarioFile($filename);

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('filename', $file);
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
        throw ANSTE::Exceptions::Error("Error parsing $filename: $@");
    }

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

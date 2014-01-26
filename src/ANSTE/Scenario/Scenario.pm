# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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
use YAML::XS;


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
sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{name} = '';
    $self->{desc} = '';
    $self->{manualBridging} = 0;
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
sub name
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
sub setName
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
sub desc
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
sub setDesc
{
    my ($self, $desc) = @_;

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

    $self->{desc} = $desc;
}

# Method: manualBridging
#
#   Gets the manual bridging option of the scenario.
#
# Returns:
#
#   boolean - value of the option
#
sub manualBridging
{
    my ($self) = @_;

    return $self->{manualBridging};
}

# Method: setManualBridging
#
#   Sets the manual bridging option of the scenario.
#
# Parameters:
#
#   boolean - manual bridging enabled or disabled
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setManualBridging
{
    my ($self, $manualBridging) = @_;

    defined $manualBridging or
        throw ANSTE::Exceptions::MissingArgument('manualBridging');

    $self->{manualBridging} = $manualBridging;
}

# Method: virtualizer
#
#   Gets the virtualizer backend for this scenario.
#
# Returns:
#
#   string - contains the virtualizer backend name
#
sub virtualizer
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
sub setVirtualizer
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
sub system
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
sub setSystem
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
sub hosts
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
sub addHost
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw ANSTE::Exceptions::InvalidType('host',
                                             'ANSTE::Scenario::Host');
    }

    $host->setScenario($self);

    push (@{$self->{hosts}}, $host);
}

# Method: bridges
#
#   Gets the hash of bridges, indexed by network address.
#
# Returns:
#
#   hash ref - list of <ANSTE::Scenario::NetworkBridge> objects
#
sub bridges
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
#   num     - bridge number (optional)
#
# Returns:
#
#   scalar  - bridge number
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub addBridge
{
    my ($self, $network, $num) = @_;

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    if (not $self->{bridges}->{$network}) {
        if (defined $num) {
            $self->{bridges}->{$network} = $num;
        } else {
            my $num_bridges = scalar(keys %{$self->{bridges}});
            $num_bridges++;
            $self->{bridges}->{$network} = $num_bridges;
        }
    }
    return $self->{bridges}->{$network};
}

# Method: loadFromFile
#
#   Loads the scenario data from a YAML file.
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
sub loadFromFile
{
    my ($self, $filename) = @_;

    defined $filename or
        throw ANSTE::Exceptions::MissingArgument('filename');

    my $file = ANSTE::Config->instance()->scenarioFile($filename);

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('filename', $file);
    }

    $self->{file} = $filename;

    my $template = new Text::Template(SOURCE => $file)
        or die "Couldn't construct template: $Text::Template::ERROR";
    my $variables = ANSTE::Config->instance()->variables();
    my $text = $template->fill_in(HASH => $variables, SAFE => new Safe)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    my ($scenario) = YAML::XS::Load($text);
    $self->_loadYAML($scenario);
}

sub _loadYAML
{
    my ($self, $scenario) = @_;

    # Read name and description of the scenario
    my $name = $scenario->{name};
    $self->setName($name);
    my $desc = $scenario->{desc};
    $self->setDesc($desc);

    if ($scenario->{'manual-bridging'}) {
        $self->setManualBridging(1);
    }

    my @bridges;

    # Read the host elements
    foreach my $element (@{$scenario->{hosts}}) {
        my $host = new ANSTE::Scenario::Host;
        $host->loadYAML($element);
        if ($host->precondition()) {
            $self->addHost($host);
            push (@bridges, @{$host->bridges()});
        }
    }

    if ($scenario->{'manual-bridging'}) {
        my $bridges = $scenario->{'bridges'};
        foreach my $bridgeId (@bridges) {
            $self->{bridges}->{$bridgeId} = $bridgeId;
        }
    }
}

sub _addScripts
{
    my ($self, $list, $node) = @_;

    foreach my $scriptNode ($node->getElementsByTagName('script', 0)) {
        my $script = $scriptNode->getFirstChild()->getNodeValue();
        push(@{$self->{$list}}, $script);
    }
}

1;

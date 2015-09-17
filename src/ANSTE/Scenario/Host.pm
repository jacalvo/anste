# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2013 Rubén Durán Balda <rduran@zentyal.com>
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
use ANSTE::Scenario::Files;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Config;

use Perl6::Junction qw(any);
use TryCatch::Lite;

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
sub new
{
    my $class = shift;
    my $self = {};

    $self->{name} = '';
    $self->{desc} = '';
    $self->{type} = 'none';
    $self->{baseImage} = new ANSTE::Scenario::BaseImage;
    $self->{'baseImage-type'} = '';
    $self->{network} = new ANSTE::Scenario::Network;
    $self->{packages} = new ANSTE::Scenario::Packages;
    $self->{files} = new ANSTE::Scenario::Files;
    $self->{'pre-scripts'} = [];
    $self->{'post-scripts'} = [];
    $self->{scenario} = undef;
    $self->{precondition} = 1;
    $self->{bridges} = [];

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
sub name
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
sub setName
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
sub desc
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
sub setDesc
{
    my ($self, $desc) = @_;

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

    $self->{desc} = $desc;
}

# Method: isRouter
#
#   Checks if the host simulates a router.
#
# Returns:
#
#   boolean - true if it's a router, false if not
#
sub isRouter
{
    my ($self) = @_;

    return $self->{type} =~ /router/;
}

# Method: type
#
#   Gets the type of the host.
#   Current types: none, router, dhcp-router, pppoe-router
#
# Returns:
#
#   string - type of the host
#
sub type
{
    my ($self) = @_;

    return $self->{type};
}

# Method: memory
#
#   Gets the memory size string.
#
# Returns:
#
#   string - contains the memory size
#
sub memory
{
    my ($self) = @_;

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
sub setMemory
{
    my ($self, $memory) = @_;

    defined $memory or
        throw ANSTE::Exceptions::MissingArgument('memory');

    $self->{memory} = $memory;
}

# Method: cpus
#
#   Gets the number of CPUs
#
# Returns:
#
#   string - contains the number of CPUs
#
sub cpus
{
    my ($self) = shift;

    return $self->{cpus};
}

# Method: setCpus
#
#   Sets the number of CPUs
#
# Parameters:
#
#   cpus - String with the number of CPUs
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setCpus
{
    my ($self, $cpus) = @_;

    defined $cpus or
        throw ANSTE::Exceptions::MissingArgument('cpus');

    $self->{cpus} = $cpus;
}


# Method: baseImage
#
#   Gets the object with the information of the base image of the host.
#
# Returns:
#
#   ref - <ANSTE::Scenario::BaseImage> object.
#
sub baseImage
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
sub setBaseImage
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

# Method: baseImageType
#
#   Returns the baseImage type
#
# Returns:
#
#   string - contains the baseImage type
#
sub baseImageType
{
    my ($self) = @_;

    return $self->{'baseImage-type'};
}

# Method: setBaseImageType
#
#   Sets the base image type of the image.
#
# Parameters:
#
#   baseImageType - String with the base image type
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setBaseImageType
{
    my ($self, $baseImageType) = @_;

    defined $baseImageType or
        throw ANSTE::Exceptions::MissingArgument('baseImageType');

    $self->{'baseImage-type'} = $baseImageType;
}

# Method: network
#
#   Gets the object with the network configuration for the host.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Network> object.
#
sub network
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
sub setNetwork
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
sub packages
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
sub setPackages
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

sub bridges
{
    my ($self) = @_;

    return $self->{network}->bridges();
}

# Method: files
#
#   Gets the object with the information of files to be transferred.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Files> object.
#
sub files
{
    my ($self) = @_;

    return $self->{files};
}

# Method: setFiles
#
#   Sets the object with the information of files to be transferred.
#
# Parameters:
#
#   packages - <ANSTE::Scenario::Files> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setFiles # (files)
{
    my ($self, $files) = @_;

    defined $files or
        throw ANSTE::Exceptions::MissingArgument('files');

    if (not $files->isa('ANSTE::Scenario::Files')) {
        throw ANSTE::Exceptions::InvalidType('files',
                                             'ANSTE::Scenario::Files');
    }

    $self->{files} = $files;
}

# Method: preScripts
#
#   Gets the list of scripts that have to be executed before the setup.
#
# Returns:
#
#   ref - reference to the list of script names
#
sub preScripts
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
sub postScripts
{
    my ($self) = @_;

    return $self->{'post-scripts'};
}

# Method: precondition
#
#   Gets if this test has passed the required precondition
#
# Returns:
#
#   boolean - true if passed, false if not
#
sub precondition
{
    my ($self) = @_;

    return $self->{precondition};
}

# Method: setPrecondition
#
#   Sets this test passes the required precondition
#
# Parameters:
#
#   ok - boolean that indicates precondition passe
#
sub setPrecondition
{
    my ($self, $ok) = @_;

    $self->{precondition} = $ok;
}

# Method: scenario
#
#   Gets the object with the scenario configuration for the host.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Scenario> object.
#
sub scenario
{
    my ($self) = @_;

    return $self->{scenario};
}

# Method: setScenario
#
#   Sets the object with the scenario configuration for the host.
#
# Parameters:
#
#   scenario - <ANSTE::Scenario::Scenario> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub setScenario
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw ANSTE::Exceptions::InvalidType('scenario',
                                             'ANSTE::Scenario::Scenario');
    }

    $self->{scenario} = $scenario;
}

sub loadYAML
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    my $name = $host->{name};
    $self->setName($name);

    my $desc = $host->{desc};
    $self->setDesc($desc);

    my $type = $host->{type};
    if ($type) {
        if ($type eq any ('router', 'pppoe-router', 'dhcp-router')) {
            $self->{type} = $type;
        } else {
            my $error = "Type $type not supported in host $name";
            throw ANSTE::Exceptions::Error($error);
        }
    }

    my $memory = $host->{memory};
    if ($memory) {
        $self->setMemory($memory);
    }

    my $cpus = $host->{cpus};
    if ($cpus) {
        $self->setCpus($cpus);
    }

    my $network = $host->{network};
    if ($network) {
        $self->network()->loadYAML($network);
    }

    my $packages = $host->{packages};
    if ($packages) {
        $self->packages()->loadYAML($packages);
    }

    my $files = $host->{files};
    if($files){
       $self->files()->loadYAML($files);
    }

    my $preInstall = $host->{'pre-install'};
    if ($preInstall) {
        $self->_addScriptsYAML('pre-scripts', $preInstall);
    }
    my $postInstall = $host->{'post-install'};
    if ($postInstall) {
        $self->_addScriptsYAML('post-scripts', $postInstall);
    }

    my $baseImageType = $host->{'baseimage-type'};
    if ($baseImageType) {
        $self->setBaseImageType($baseImageType);
    }

    my $baseimage = $host->{baseimage};
    try {
        $self->baseImage()->loadFromFile("$baseimage.yaml");
    } catch (ANSTE::Exceptions::InvalidFile $e) {
        if ($self->baseImageType() eq 'raw') {
            # Dummy image for raw base images
            $self->baseImage()->setName($baseimage);
        } else {
            $e->throw();
        }
    }

    # FIXME
    # Check if all preconditions are satisfied
#    my $configVars = ANSTE::Config->instance()->variables();
#   my $preconditionNodes = $node->getElementsByTagName('precondition', 0);
#    for (my $i = 0; $i < $preconditionNodes->getLength(); $i++) {
#        my $var = $preconditionNodes->item($i)->getAttribute('var');
#        my $expectedValue = $preconditionNodes->item($i)->getAttribute('eq');
#        my $value = $configVars->{$var};
#        unless (defined $value) {
#            $value = 0;
#        }
#        if ($value ne $expectedValue) {
#            $self->setPrecondition(0);
#            last;
#        }
#    }
}

sub _addScriptsYAML
{
    my ($self, $list, $scripts) = @_;

    foreach my $script (@{$scripts}) {
        push (@{$self->{$list}}, $script);
    }
}

1;

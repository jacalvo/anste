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

package ANSTE::Scenario::BaseImage;

use strict;
use warnings;

use ANSTE::Scenario::Packages;
use ANSTE::Scenario::Files;
use ANSTE::Config;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use Text::Template;
use Safe;
use YAML::XS;

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
sub new
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
    $self->{files} = new ANSTE::Scenario::Files();
    $self->{'pre-scripts'} = [];
    $self->{'post-scripts'} = [];
    $self->{'post-tests-scripts'} = [];
    $self->{mirror} = '';

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
sub name
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
sub setName
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
sub desc
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
sub setDesc
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
sub memory
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
sub setMemory
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
sub size
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
sub setSize
{
    my ($self, $size) = @_;

    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

    $self->{size} = $size;
}

# Method: arch
#
#   Gets the arch of the image.
#
# Returns:
#
#   string - contains the arch of the image
#
sub arch
{
    my ($self) = @_;

    return $self->{arch};
}

# Method: setArch
#
#
#   Sets the arch of the image.
#
# Parameters:
#
#   arch - String with the arch of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setArch
{
    my ($self, $arch) = @_;

    defined $arch or
        throw ANSTE::Exceptions::MissingArgument('arch');

    $self->{arch} = $arch;
}

# Method: swap
#
#   Gets the size of the swap partition.
#
# Returns:
#
#   string - contains the size of the image
#
sub swap
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
sub setSwap
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
sub installMethod
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
sub setInstallMethod
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
sub installSource
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
sub setInstallSource
{
    my ($self, $installSource) = @_;

    defined $installSource or
        throw ANSTE::Exceptions::MissingArgument('installSource');

    $self->{installSource} = $installSource;
}

# Dist: installDist
#
#   Returns the distribution to be installed.
#
# Returns:
#
#   string - contains the name of the distribution
#
sub installDist
{
    my ($self) = @_;

    return $self->{installDist};
}

# Dist: setInstallDist
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
sub setInstallDist
{
    my ($self, $installDist) = @_;

    defined $installDist or
        throw ANSTE::Exceptions::MissingArgument('installDist');

    $self->{installDist} = $installDist;
}

# Command: installCommand
#
#   Gets the command to be used for the dist install.
#
# Returns:
#
#   string - contains the command
#
sub installCommand
{
    my ($self) = @_;

    return $self->{installCommand};
}

# Command: setInstallCommand
#
#   Gets the command to be used for the dist install.
#
# Parameters:
#
#   installCommand - String with the installation command
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setInstallCommand
{
    my ($self, $installCommand) = @_;

    defined $installCommand or
        throw ANSTE::Exceptions::MissingArgument('installCommand');

    $self->{installCommand} = $installCommand;
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
sub setFiles
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

# Method: mirror
#
#   Returns the mirror to be used generating the image.
#
# Returns:
#
#   string - contains the mirror to use
#
sub mirror # returns string
{
    my ($self) = @_;

    return $self->{mirror};
}

# Method: setMirror
#
#   Sets the mirror of the image.
#
# Parameters:
#
#   name - String with the mirror of the image.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setMirror # name string
{
    my ($self, $mirror) = @_;

    defined $mirror or
        throw ANSTE::Exceptions::MissingArgument('mirror');

    $self->{mirror} = $mirror;
}

# Method: postTestsScripts
#
#   Gets the list of scripts that have to be executed after the tests run.
#
# Returns:
#
#   ref - reference to the list of script names
#
sub postTestsScripts # returns list ref
{
    my ($self) = @_;

    return $self->{'post-tests-scripts'};
}

# Method: loadFromFile
#
#   Loads the base image data from a YAML file.
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

    my $file = ANSTE::Config->instance()->imageTypeFile($filename);

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('filename', $file);
    }

    my $template = new Text::Template(SOURCE => $file)
        or die "Couldn't construct template: $Text::Template::ERROR";
    my $variables = ANSTE::Config->instance()->variables();
    my $text = $template->fill_in(HASH => $variables, SAFE => new Safe)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    my ($image) = YAML::XS::Load($text);
    return $self->_loadFromYAML($image);
}

sub _addScripts
{
    my ($self, $list, $node) = @_;

    foreach my $scriptNode ($node->getElementsByTagName('script', 0)) {
        my $script = $scriptNode->getFirstChild()->getNodeValue();
        push(@{$self->{$list}}, $script);
    }
}

sub _loadFromYAML
{
    my ($self, $image) = @_;

    # Read name and description of the image
    my $name = $image->{name};
    $self->setName($name);
    my $desc = $image->{desc};
    $self->setDesc($desc);

    my $memory= $image->{memory};
    if ($memory) {
        $self->setMemory($memory);
    }

    my $size = $image->{size};
    $self->setSize($size);

    my $arch= $image->{arch};
    if ($arch) {
        $self->setArch($arch);
    }

    my $swap= $image->{swap};
    if ($swap) {
        $self->setSwap($swap);
    }

    my $installMethod = $image->{method};
    $self->setInstallMethod($installMethod);

    my $installSource = $image->{source};
    if  ($installSource) {
        $self->setInstallSource($installSource);
    }
    my $installDist = $image->{dist};
    if  ($installDist) {
        $self->setInstallDist($installDist);
    }
    my $installCommand = $image->{command};
    if  ($installCommand) {
        $self->setInstallCommand($installCommand);
    }

    my $packages = $image->{packages};
    if ($packages) {
        $self->packages()->loadYAML($packages);
    }

    my $preInstallScripts = $image->{'pre-install'};
    if ($preInstallScripts) {
        $self->_addScriptsFromYAML('pre-scripts', $preInstallScripts);
    }

    my $postInstallScripts = $image->{'post-install'};
    if ($postInstallScripts) {
        $self->_addScriptsFromYAML('post-scripts', $postInstallScripts);
    }

    my $postScriptsScripts = $image->{'post-tests'};
    if ($postScriptsScripts) {
        $self->_addScriptsFromYAML('post-tests-scripts', $postScriptsScripts);
    }

    my $mirror = $image->{mirror};
    if ($mirror) {
        $self->setMirror($mirror);
    }

    my $files = $image->{files};
    if ($files) {
        $self->files()->loadYAML($files);
    }

}

sub _addScriptsFromYAML
{
    my ($self, $list, $node) = @_;

    foreach my $script (@{$node}) {
        push(@{$self->{$list}}, $script);
    }
}

1;

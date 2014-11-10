# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2014 Rubén Durán Balda <rduran@zentyal.com>
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

package ANSTE::Virtualizer::Virtualizer;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::NotImplemented;
use ANSTE::Exceptions::MissingArgument;

# Class: Virtualizer
#
#   Abstract class with the methods called by the rest of the ANSTE
#   framework to interact with a virtualizer software and have to
#   be implemented by each virtualizer backend.
#

# Constructor: new
#
#   Constructor for Virtualizer class and his derivated classes.
#
# Returns:
#
#   A recently created <ANSTE::Virtualizer::Virtualizer> object
#
sub new
{
    my ($class) = @_;
    my $self = {};

    bless($self, $class);

    return $self;
}

# Method: instance
#
#   Returns a instance of the virtualizer object defined in the conf
#
sub instance
{
    my ($self) = @_;

    my $virtualizer = ANSTE::Config->instance()->virtualizer();
    eval "use ANSTE::Virtualizer::$virtualizer";
    die "Can't load package $virtualizer: $@" if $@;

    return "ANSTE::Virtualizer::$virtualizer"->new();
}

# Method: execute
#
#   Executes a command
#
# Parameters:
#
#   command - string that contains the command to be executed
#
# Returns:
#
#   boolean - true if the exit code is 0, false otherwise
#
sub execute
{
    my ($self, $command) = @_;

    defined $command or
        throw ANSTE::Exceptions::MissingArgument('command');

    if (not ANSTE::Config->instance()->verbose()) {
        $command .= ' > /dev/null 2>&1';
    }
    return system($command) == 0;
}

sub cleanup
{
}

# Method: createBaseImage
#
#   Override this method to execute the command of a
#   specific virtualizer to create a base image.
#
# Parameters:
#
#   name   - name of the image type to be created
#   ip     - ip address that will be assigned to the image
#   memory - *optional* size of the RAM memory to be used
#   swap   - *optional* size of the swap partition to be used
#   arch   - *optional* architecture to be used
#   method - installation method to be used (depends of the virtualizer)
#   source - source of the installation data (depends of the virtualizer)
#   dist    - distribution to be installed (depends of the virtualizer)
#   command - command to be used for the installation (depends of the virtualizer)
#
# Returns:
#
#   boolean -   indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub createBaseImage
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: imageNeedsUpdate
#
#   Override this method to tell if a base image needs an update
#   with the proper virtualizer
#
# Parameters:
#
#   name   - name of the image
#
# Returns:
#
#   boolean -   indicates if the image needs an update
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub imageNeedsUpdate
{
    throw ANSTE::Exceptions::NotImplemented();
}


# Method: markImageUpdated
#
#   Override this method to mark an image as updated with the proper virtualizer
#
# Parameters:
#
#   name   - name of the image
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub markImageUpdated
{
    throw ANSTE::Exceptions::NotImplemented();
}

# FIXME: Remove both skips
sub skipImageCreation
{
    return 0;
}

# Method: shutdownImage
#
#   Override this method to execute the command
#   of the corresponding virtualizer program
#   to shutdown a given image being virtualized.
#
# Parameters:
#
#   image - name of the image to shutdown
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub shutdownImage
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: destroyImage
#
#   Override this method to execute the command of the corresponding
#   virtualizer program to force the immediate shutdown of a given image
#   being virtualized.
#
# Parameters:
#
#   image - name of the image to destroy
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub destroyImage
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: createVM
#
#   Override this method to perform the necessary steps before the creation of
#   the Virtual Machine with the corresponding virtualizer program.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub preCreateVM
{
    return 1;
}

# Method: createVM
#
#   Override this method to create the Virtual Machine
#   with the corresponding virtualizer program.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub createVM
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: finishImageCreation
#
#   Override this method to perform the necessary steps after the creation of
#   the Virtual Machine with the corresponding virtualizer program.
#
sub finishImageCreation
{
}

# Method: defineVM
#
#   Override this method to define the Virtual Machine
#   with the corresponding virtualizer program.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub defineVM
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: startVM
#
#   Override this method to start the Virtual Machine
#   with the corresponding virtualizer program.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub startVM
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: removeVM
#
#   Override this method to remove the Virtual Machine
#   with the corresponding virtualizer program.
#
# Parameters:
#
#   name - name of the virtual machine
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub removeVM
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: existsVM
#
#   Override this method to tell if a VM exists
#   with the corresponding virtualizer program.
#
# Parameters:
#
#   name - name of the virtual machine
#
# Returns:
#
#   boolean - indicates if the VM exists
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub existsVM
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: listVMs
#
#   Override this method to list all the existing VMs
#   with the corresponding virtualizer program.
#
# Returns:
#
#   list - names of all the VMs
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub listVMs
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: imageFile
#
#   Override this method to return the full path
#   of the disk image, adding extension and so on
#   given the path and the name of the image.
#
# Parameters:
#
#   path - root directory where images are stored
#   name - name of the image
#
# Returns:
#
#   boolean - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub imageFile # (path, name)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: createImageCopy
#
#  Override this method to create a copy of a base image
#  with the specified new configuration.
#
# Parameters:
#
#   baseimage - an <ANSTE::Deploy::BaseImage> object with the configuration
#               of the base image
#   newimage  - an <ANSTE::Deploy::Image> object with the configuration
#               of the new image
#
# Returns:
#
#   boolean   - indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub createImageCopy
{
    throw ANSTE::Exceptions::NotImplemented();
}


# Method: deleteImage
#
#   Override this method to delete an image using
#   the specific virtualizer program.
#
# Parameters:
#
#   image   - name of the image to be deleted
#
# Returns:
#
#   boolean -   indicates if the process has been successful
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub deleteImage
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: createNetwork
#
#   Override this method to do the stuff needed
#   to set up the network for a scenario, on your
#   specific virtualizer.
#
# Parameters:
#
#   network   - a <ANSTE::Scenario::Network> object
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub createNetwork
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: destroyNetwork
#
#   Override this method to do the stuff needed
#   to destroy the network of a scenario, on your
#   specific virtualizer.
#
# Parameters:
#
#   network   - a <ANSTE::Scenario::Network> object
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub destroyNetwork
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: cleanNetwork
#
#   Override this method to implement the
#   cleaning of the network used by the virtualizer
#
# Parameters:
#
#   identifier       - used to mark the networks
#
sub cleanNetwork
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: createSnapshot
#
#   Override this method to implement the
#   snapshot creation command for a host
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#   description  - description of the snapshot
#
sub createSnapshot
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: revertSnapshot
#
#   Override this method to implement the
#   snapshot revert command for a host
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub revertSnapshot
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: deleteSnapshot
#
#   Override this method to implement the
#   snapshot delete command for a host
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub deleteSnapshot
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: existsSnapshot
#
#   Override this method to tell if a snapshot exists
#
# Parameters:
#
#   domain       - virtual machine name
#   name         - snapshot label
#
sub existsSnapshot
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: takeScreenshot
#
#   Override this method to take an screenshot of the screen
#
# Parameters:
#
#   domain       - virtual machine name
#   file         - screenshot file
#
sub takeScreenshot
{
    throw ANSTE::Exceptions::NotImplemented();
}

1;

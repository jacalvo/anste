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

package ANSTE::System::System;

use strict;
use warnings;

use ANSTE::Exceptions::NotImplemented;

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
	my $class = shift;
	my $self = {};
	
	bless($self, $class);

	return $self;
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
sub execute # (command)
{
    my ($self, $command) = @_;
    return system($command) == 0;
}

# Method: mountImage 
#
#   Override this method to execute the command that 
#   mounts a given image on a given mount point.
#
# Parameters: 
#   
#   image      - path of the image to mount 
#   mountPoint - directory where the image will be mounted
#
# Returns:
#   
#   boolean    - indicates if the process has been successful
#               
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub mountImage # (image, mountPoint)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: unmount 
#
#   Override this method to execute the system command
#   that unmounts a directory.
#
# Parameters: 
#   
#   mountPoint - path of the mounted directory 
#
# Returns:
#   
#   boolean -   indicates if the process has been successful
#               
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub unmount # (mountPoint)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: installBasePackages 
#
#   Override this method with the system-specific
#   installation steps that allow the execution
#   of ansted and anste-slave on the virtualized hosts.
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub installBasePackages
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: resizeImage 
#
#   Override this method with the system-specific
#   commands to resize a image file.
#
# Parameters:
#   
#   image   - image file
#   size    - new size
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub resizeImage # (image, size)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: updatePackagesCommand
#
#   Overriden method that returns the Debian command
#   to update packages database.
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub updatePackagesCommand # returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: updatePackagesCommand
#
#   Overriden method that returns the Debian command
#   to clean packages cache.
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub cleanPackagesCommand # returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: installPackagesCommand 
#
#   Overriden method that returns the Debian command
#   to install the given list of packages 
#
# Parameters:
#   
#   packages - list of packages
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub installPackagesCommand # (packages) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: installVars
#
#   Overriden method that returns the environment variables needed 
#   for the packages installation process.
#
# Returns:
#
#   string - contains the environment variables set commands
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub installVars # return strings
{
    throw ANSTE::Exceptions::NotImplemented();
}


# Method: networkConfig
# FIXME documentation
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub networkConfig # (network) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: hostnameConfig
# FIXME documentation
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub hostnameConfig # (hostname) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: hostsConfig
# FIXME documentation
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub hostsConfig # (hostname) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: storeMasterAddress
# FIXME documentation
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub storeMasterAddress # (address) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: copyToMountCommand
# FIXME documentation
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub copyToMountCommand # (orig, dest) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

1;

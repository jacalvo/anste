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

use ANSTE::Config;
use ANSTE::Exceptions::NotImplemented;
use ANSTE::Exceptions::MissingArgument;

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

    defined $command or
        throw ANSTE::Exceptions::MissingArgument('command');

    if (not ANSTE::Config->instance()->verbose()) {
        $command .= ' &> /dev/null';
    }
    return system($command) == 0;
}

sub _executeSavingLog # (command, log)
{
    my ($self, $command, $log) = @_;

    # Take copies of the file descriptors
    open(OLDOUT, '>&STDOUT')   or return 1;
    open(OLDERR, '>&STDERR')   or return 1;

    # Redirect stdout and stderr
    open(STDOUT, "> $log")     or return 1;
    open(STDERR, '>&STDOUT')   or return 1;

    my $ret = system($command);

    # Close the redirected filehandles
    close(STDOUT)              or return 1;
    close(STDERR)              or return 1;

    # Restore stdout and stderr
    open(STDERR, '>&OLDERR')   or return 1;
    open(STDOUT, '>&OLDOUT')   or return 1;

    # Avoid leaks by closing the independent copies
    close(OLDOUT)              or return 1;
    close(OLDERR)              or return 1;

    return $ret;
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
#   Override this method to return the system-specific
#   command to udpate packages database.
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

# Method: enableInterfacesCommand
#
#   Override this method to return the system-specific
#   command to enable network interfaces.
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented> 
#
sub enableInterfacesCommand # returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: cleanPackagesCommand
#
#   Override this method to return the system-specific
#   command to clean the packages cache.
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

# Method: createMountDirCommand
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub createMountDirCommand # (path) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: firewallDefaultRules
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub firewallDefaultRules # returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: enableNAT
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub enableNAT # (iface, sourceAddr)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: disableNAT
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub disableNAT # (iface, sourceAddr)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: executeSelenium
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub executeSelenium # (%params)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: startVideoRecording
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub startVideoRecording # (filename)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: stopVideoRecording
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub stopVideoRecording
{
    throw ANSTE::Exceptions::NotImplemented();
}

1;

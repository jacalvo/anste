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

package ANSTE::System::System;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::NotImplemented;
use ANSTE::Exceptions::MissingArgument;

# Class: System
#
#   Abstract class with the methods called by the rest of the ANSTE
#   framework to interact with the operating system software and have to
#   be implemented by each system backend.
#

# Constructor: new
#
#   Constructor for System class and his derivated classes.
#
# Returns:
#
#   A recently created <ANSTE::System::System> object
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
# Exceptions:
#
#   <ANSTE::Exceptions::Error> - throw if can't execute the command
#
sub execute # (command)
{
    my ($self, $command) = @_;

    defined $command or
        throw ANSTE::Exceptions::MissingArgument('command');

    if (not ANSTE::Config->instance()->verbose()) {
        $command .= ' > /dev/null 2>&1';
    }
    my $ret = system($command);

    # Checks if the command can't be executed or broken pipe signal
    if ($ret == -1) {
        throw ANSTE::Exceptions::Error("Can't execute $command");
    }

    return $ret == 0;
}

sub runTest # (command, logfile, env, params)
{
    my ($self, $command, $log, $env, $params) = @_;

    defined $command or
        throw ANSTE::Exceptions::MissingArgument('command');

    my $ret = system("$env $command $params > $log 2>&1");

    # Checks if the command can't be executed or broken pipe signal
    if ($ret == -1) {
        throw ANSTE::Exceptions::Error("Can't execute $command");
    }

    return $?;
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
#   boolean - indicates if the process has been successful
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
#   boolean - indicates if the process has been successful
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

# Method: updateNetworkCommand
#
#   Override this method to return the system-specific
#   command to update the network configuration.
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub updateNetworkCommand # returns string
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
#   Override this method to return the Debian command
#   to install the given list of packages.
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

# Method: installPackagesCommandType
#
#   Override this method to return the Debian command
#   to install the given list of packages for a
#   specific type of host.
#
# Parameters:
#
#   type - host type
#
# Returns:
#
#   string - command string
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub installPackagesCommandType # (type) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: installVars
#
#   Override this method to return the environment variables needed
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
#
#   Override this method to return the network configuration
#   for a given network config passed as an argument.
#
# Parameters:
#
#   network - <ANSTE::Scenario::Network> object.
#
# Returns:
#
#   string - contains the network configuration
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub networkConfig # (network) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: hostsConfig
#
#   Override this method to return the hosts configuration
#   passed as an argument.
#
# Parameters:
#
#   hosts - Hash containining hostnames and ip addresses.
#
# Returns:
#
#   string - contains the hosts configuration
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub hostsConfig # (network) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: hostnameConfig
#
#   Override this method to return the hostname configuration
#   for a the given hostname passed as an argument.
#
# Parameters:
#
#   hostname - String with the hostname for write the config.
#
# Returns:
#
#   string - contains the hostname configuration
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub hostnameConfig # (hostname) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: hostConfig
#
#   Override this method to return the hosts configuration
#   for a the given hostname passed as an argument.
#
# Parameters:
#
#   hostname - String with the hostname for write the config.
#
# Returns:
#
#   string - contains the network hosts configuration
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub hostConfig # (hostname) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: storeMasterAddress
#
#   Override this method to return the command for store the master
#   address in the slave host.
#
# Parameters:
#
#   address - String with the IP address to store.
#
# Returns:
#
#   string - contains the command to store the address
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub storeMasterAddress # (address) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: copyToMountCommand
#
#   Override this method to return the command used to copy a given
#   file to a given destiny on a mounted image.
#
# Parameters:
#
#   orig - String with the origin file to copy.
#   dest - String with the destiny of the copy on the mounted image.
#
# Returns:
#
#   string - contains the command to copy to a mounted image
#
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
#   Override this method to return the command used to create a
#   directory on a mounted image.
#
# Parameters:
#
#   path - String with the full path of directories to be created.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub createMountDirCommand # (path) returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: firewallDefaultRules
#
#   Override this method to return the commands needed to set
#   the default firewall (no filtering).
#
# Returns:
#
#   string - contains the commands
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub firewallDefaultRules # returns string
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: enableRouting
#
#   Override this method to return the commands that enables routing
#   on a given network interface.
#
# Parameters:
#
#   iface - String with the interface to enable masquerading.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub enableRouting # (iface)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: setupTypeScript
#
#   Override this method to return the command that runs the script
#   to setup the specified type of host.
#
# Parameters:
#
#   type - String with the type of the host.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub setupTypeScript # (type)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: enableNAT
#
#   Override this method to return the command that enables NAT
#   on a given network interface from a given source address.
#
# Parameters:
#
#   iface - String with the interface to enable masquerading.
#   sourceAddr - String with the source IP address to enable the NAT.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub enableNAT # (iface, sourceAddr)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: disableNAT
#
#   Override this method to return the command that disables NAT
#   on a given network interface from a given source address.
#
# Parameters:
#
#   iface - String with the interface to disable masquerading.
#   sourceAddr - String with the source IP address to disable the NAT.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub disableNAT # (iface, sourceAddr)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: executeSelenium
#
#   Override this method to execute Selenium.
#
# Parameters:
#
#   jar - String with the path of the selenium jar.
#   browser - String with the web browser to be used.
#   url - String with the url of the web we want to test.
#   testFile - String with the filename of the Selenium test suite.
#   resultFile - String with the filename of the Selenium results to be saved.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub executeSelenium # (%params)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: startVideoRecording
#
#   Override this method to return the command that should
#   be used to start video recording on the specific system.
#   The video is stored with the given filename.
#
# Parameters:
#
#   filename - String with the filename of the video to store.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub startVideoRecording # (filename)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: stopVideoRecording
#
#   Override this method to return the command that should
#   be used to stop video recording on the specific system.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   throws <ANSTE::Exceptions::NotImplemented>
#
sub stopVideoRecording
{
    throw ANSTE::Exceptions::NotImplemented();
}

1;

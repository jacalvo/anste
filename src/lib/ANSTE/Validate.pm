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

package ANSTE::Validate;

use strict;
use warnings;

use ANSTE::Config;

use Mail::RFC822::Address;

use Cwd;
use File::Basename;

# Module: Validate
#
#   Contains functions to validate several kinds of data.
#

# Function: natural
#
#   Checks if the passed string is a valid natural number.
#
# Parameters:
#
#   string - String to be validated.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub natural # (string)
{
    my ($string) = @_;

    return $string =~ /^\d+$/;
}

# Function: boolean
#
#   Checks if the passed value is a valid boolean number (0 or 1).
#
# Parameters:
#
#   value - Value to be validated.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub boolean # (value)
{
    my ($value) = @_;

    return $value == 0 || $value == 1;
}

# Function: path
#
#   Checks if the passed path is a existing directory.
#
# Parameters:
#
#   path - String with the path to be checked.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub path # (path)
{
    my ($path) = @_;

    return defined($path) && -d $path;
}

# Function: fileReadable
#
#   Checks if the given file is readable.
#
# Parameters:
#
#   file - String with the path of the file.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub fileReadable # (file)
{
    my ($file) = @_;

    return defined($file) && -r $file;
}

# Function: fileWritable
#
#   Checks if the given file is writable.
#
# Parameters:
#
#   file - String with the path of the file.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub fileWritable # (file)
{
    my ($file) = @_;

    return defined($file) && -w dirname($file);
}

# Function: directoryWritable
#
#   Checks if the given directory is writable.
#
# Parameters:
#
#   dir - String with the directory path.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub directoryWritable # (dir)
{
    my ($dir) = @_;

    return defined($dir) && -w dirname($dir);
}

# Function: system
#
#   Checks if the given string is a existing System implementation.
#
# Parameters:
#
#   system - String with the name of <ANSTE::System::System> implementation.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub system # (system)
{
    my ($system) = @_;

    foreach my $path (@INC) {
        my $file = "$path/ANSTE/System/$system.pm";
        if (-r $file) {
            return 1;
            last;
        }
    }
    return 0;
}

# Function: virtualizer
#
#   Checks if the given string is a existing Virtualizer implementation.
#
# Parameters:
#
#   virtualizer - String with the name of 
#                 the <ANSTE::Virutalizer::Virtualizer> implementation
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub virtualizer # (virtualizer)
{
    my ($virtualizer) = @_;

    foreach my $path (@INC) {
        my $file = "$path/ANSTE/Virtualizer/$virtualizer.pm";
        if (-r $file) {
            return 1;
            last;
        }
    }
    return 0;
}

# Function: port
#
#   Checks if the given argument is a valid port.
#
# Parameters:
#
#   port - String with the port number.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub port # (port)
{
    my ($port) = @_;

    return natural($port) && $port > 0 && $port <= 65535;
}

# Function: host
#
#   Checks if the given host string is a valid domain name.
#
# Parameters:
#
#   host - String with the host.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub host # (host)
{
    my ($host) = @_;

    # Could be an ip
    if ($host =~ m/^[\d.]+$/) {
        return ip($host);
    }
    else { # Or a domain name
        # Rules taken from ebox-platform (EBox::Validate::_checkDomainName)
        ($host =~ /^\w/) or return 0;
        ($host =~ /\w$/) or return 0;
        ($host =~ /\.-/) and return 0;
        ($host =~ /-\./) and return 0;
        ($host =~ /\.\./) and return 0;
        ($host =~ /_/) and return 0;
        ($host =~ /^[-\.\w]+$/) or return 0;
        return 1;
    }
}

# Function: ip
#
#   Checks if the given string is a valid IP address.
#
# Parameters:
#
#   ip - String with the IP address representation.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub ip # (ip)
{
    my ($ip) = @_;

    if (not defined $ip) {
        return 0;
    }

    my @octets = 
        $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;

    if (@octets != 4) {
        return 0;
    }

    foreach my $octect (@octets) {
        if ($octect < 0 || $octect > 255) {
            return 0;
        }
    }

    return 1; 
}

# Function: mac
#
#   Checks if the given string is a valid MAC address.
#
# Parameters:
#
#   mac - String with the MAC address representation.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub mac # (mac)
{
    my ($mac) = @_;

    # Add this to simplify the regex
    $mac .= ':';
    return $mac =~ /^([0-9a-fA-F]{1,2}:){6}$/;
}

# Function: email
#
#   Checks if the given email address is valid according to RFC 822.
#
# Parameters:
#
#   email - String with the email.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub email # (address)
{
    my ($address) = @_;

    return Mail::RFC822::Address::valid($address);
}

# Function: suite
#
#   Checks if the directory passed is an existing test suite directory.
#
# Parameters:
#
#   suite - String with the directory name of the test suite.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub suite # (suite)
{
    my ($suite) = @_;

    my $file = ANSTE::Config->instance()->testFile("$suite/suite.xml");

    return -r $file;
}

# Function: template
#
#   Checks if the file passed is an existing template file.
#
# Parameters:
#
#   template - String with the template name.
#
# Returns:
#
#   boolean - true if it's valid, false otherwise
#
sub template # (template)
{
    my ($template) = @_;

    my $dir = ANSTE::Config->instance()->templatePath();
    my $file = "$dir/$template";

    return -r $file;
}

1;

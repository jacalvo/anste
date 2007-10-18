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

# Function: natural
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
sub natural # (string)
{
    my ($string) = @_;

    return $string =~ /^\d+$/;
}

# Function: boolean
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
sub boolean # (value)
{
    my ($value) = @_;

    return $value == 0 || $value == 1;
}

# Function: path
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
sub path # (path)
{
    my ($path) = @_;

    return defined($path) && -d $path;
}

# Function: fileReadable
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
sub fileReadable # (file)
{
    my ($file) = @_;

    return defined($file) && -r $file;
}

# Function: fileWritable
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
sub fileWritable # (file)
{
    my ($file) = @_;

    return defined($file) && -w dirname($file);
}

# Function: directoryWritable
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
sub directoryWritable # (dir)
{
    my ($dir) = @_;

    return defined($dir) && -w dirname($dir);
}

# Function: system
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
#
#
# Parameters:
#
#
# Returns:
#
#
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
#
#
# Parameters:
#
#
# Returns:
#
#
#
sub port # (port)
{
    my ($port) = @_;

    return natural($port) && $port > 0 && $port <= 65535;
}

# Function: host
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
#
#
# Parameters:
#
#
# Returns:
#
#
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

# Function: email
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
sub email # (address)
{
    my ($address) = @_;

    return Mail::RFC822::Address::valid($address);
}

# Function: suite
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
sub suite # (suite)
{
    my ($suite) = @_;

    my $file = ANSTE::Config->instance()->testFile("$suite/suite.xml");

    return -r $file;
}

# Function: template
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
sub template # (template)
{
    my ($template) = @_;

    my $dir = ANSTE::Config->instance()->templatePath();
    my $file = "$dir/$template";

    return -r $file;
}

1;

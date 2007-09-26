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

sub natural # (string)
{
    my ($string) = @_;

    return $string =~ /^\d+$/;
}

sub boolean # (value)
{
    my ($value) = @_;

    return $value == 0 || $value == 1;
}

sub path # (path)
{
    my ($path) = @_;

    return -d $path;
}

sub fileReadable # (file)
{
    my ($file) = @_;

    return -r $file;
}

sub fileWritable # (file)
{
    my ($file) = @_;

    return -w dirname($file);
}

sub directoryWritable # (dir)
{
    my ($dir) = @_;

    return -w dirname($dir);
}

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

sub port # (port)
{
    my ($port) = @_;

    return natural($port) && $port > 0 && $port <= 65535;
}

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

sub email # (address)
{
    my ($address) = @_;

    return Mail::RFC822::Address::valid($address);
}

sub suite # (suite)
{
    my ($suite) = @_;

    my $dir = ANSTE::Config->instance()->testPath();
    my $file = "$dir/$suite/suite.xml";

    return -r $file;
}

sub template # (template)
{
    my ($template) = @_;

    my $dir = ANSTE::Config->instance()->templatePath();
    my $file = "$dir/$template";

    return -r $file;
}

1;

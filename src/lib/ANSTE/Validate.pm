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

use Cwd;

sub natural # (string)
{
    my ($string) = @_;

    return $string =~ /^\d+$/;
}

sub path # (path)
{
    my ($path) = @_;

    return -d $path;
}

sub system # (system)
{
    my ($system) = @_;

    my $path = "ANSTE/System/$system.pm";
    my $libPath = getcwd() . "/lib/ANSTE/System/$system.pm";

    return -f $path || -f $libPath;
}

sub virtualizer # (virtualizer)
{
    my ($virtualizer) = @_;

    my $path = "ANSTE/Virtualizer/$virtualizer.pm";
    my $libPath = getcwd() . "/lib/ANSTE/Virtualizer/$virtualizer.pm";

    return -f $path || -f $libPath; 
}

sub port # (port)
{
    my ($port) = @_;

    return natural($port) && $port > 0 && $port <= 65535;
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

1;

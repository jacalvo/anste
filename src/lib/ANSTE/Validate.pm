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

sub ip # (ip)
{
    my ($self, $ip) = @_;

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

sub ipRange # (ip)
{
    my ($self, $ip) = @_;

    if (not defined $ip) {
        return 0;
    }

    my @octets = 
        $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;

    if (@octets != 3) {
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

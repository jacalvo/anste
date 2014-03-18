# Copyright (C) 2014 Zentyal S.L.
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

use strict;
use warnings;

package ANSTE;

use ANSTE::Config;
use ANSTE::Util;
use Time::HiRes qw(gettimeofday);

my $INITIAL_TIME = time();

# Method: info
#
#   Prints the msg passed as parameter to the console
#
# Parameters:
#
#   msg  - Contains the string with the message to print
#
sub info
{
    my ($msg) = @_;

    my $config = ANSTE::Config->instance();

    my $output = '';

    if ($config->verbose()) {
        my ($seconds, $microseconds) = gettimeofday();
        my $milliseconds = int ($microseconds / 1000);
        $seconds -= $INITIAL_TIME;
        $output .= "$seconds.$milliseconds> ";
    }

    $output .= "$msg\n";

    print $output;
}

# Method: askForRepeat
#
#   Ask for repetition to the user
#
# Returns:
#
#   value - whether you should repear or not
#
sub askForRepeat
{

    my ($msg) = @_;

    my $ret = 0;
    my $key;
    while (1) {
        print "$msg " .
            "Press 'r' to run the test/script again or 'c' to continue.\n";
        $key = ANSTE::Util::readChar();
        if ($key eq 'r') {
            $ret = 1;
            last;
        } if ($key eq 'c') {
            last;
        }
    }

    return $ret;
}

1;

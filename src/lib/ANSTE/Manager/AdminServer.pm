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

package ANSTE::Manager::AdminServer;

use strict;
use warnings;

use ANSTE::Manager::JobWaiter;

use FreezeThaw qw(thaw);

sub list # returns job queue
{
    my ($self) = @_;

    my $waiter = ANSTE::Manager::JobWaiter->instance();

    my $list = '' ;
    my $number = 1;
    my $current = $waiter->current();
    if ($current) {
        my @job = thaw($current);
        my $job = $job[0];
        $list = "$number) " . $job->toStr() . " (Running)\n";
        $number++;
    }
    foreach my $item (@{$waiter->queue()}) {
        my @job = thaw($item);
        my $job = $job[0];
        $list .= "$number) " . $job->toStr() . "\n";
        $number++;
    }
    return $list ? $list : "No jobs.\n";
}

1;

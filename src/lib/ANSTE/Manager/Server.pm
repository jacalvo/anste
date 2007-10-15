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

package ANSTE::Manager::Server;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Manager::JobWaiter;
use ANSTE::Manager::RSSWriter;
use ANSTE::Manager::Config;

sub addJob # (user, test, mail, path)
{
    my ($self, $user, $test, $mail, $path) = @_;

    my $job = new ANSTE::Manager::Job($user, $test);
    if ($mail) {
        $job->setEmail($mail);
    }
    if ($path) {
        $job->setPath($path);
    }

    print "Added test '$test' from user '$user'\n";

    my $WWWDIR = ANSTE::Manager::Config->instance()->wwwDir(); 
    my $userdir = "$WWWDIR/$user";

    if (not -d $userdir) {
        mkdir($userdir) or die "Can't mkdir: $!";
    }
    my $rss = new ANSTE::Manager::RSSWriter();
    $rss->writeChannel($user);

    my $waiter = ANSTE::Manager::JobWaiter->instance();
    $waiter->jobReceived($job);

   	return 'OK';
}

1;

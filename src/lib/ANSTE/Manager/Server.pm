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

package ANSTE::Manager::Server;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Manager::JobWaiter;
use ANSTE::Manager::RSSWriter;
use ANSTE::Manager::Config;

# Class: Server
#
#   This class is used by the SOAP server that manages the client requests
#   to handle them.
#

# Method: addJob
#
#   Handles an add job command from the client, notifying that the
#   job has been received to the <ANSTE::Manager::JobWaiter> instance.
#
# Parameters:
#
#   user - String with the name of the user that sends the job.
#   test - String with the name of the test to be executed.
#   mail - *optional* String with the address where the user will be notified.
#   path - *optional* String with the path of the user tests.
#
# Returns:
#
#   string - OK if the request is sucessful.
#
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

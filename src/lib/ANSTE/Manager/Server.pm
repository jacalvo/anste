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
use ANSTE::Manager::MailNotifier;
use ANSTE::Manager::JobWaiter;

use threads::shared;

sub addJob # (user, test)
{
    my ($self, $user, $test) = @_;

    my $job = new ANSTE::Manager::Job($user, $test);
    $job->setEmail('josh@localhost');

    open(FILE, '>>', "/tmp/ANSTE_MANAGER");
  	print FILE "$user: $test\n";
   	close FILE or die "Can't close: $!";
    print "Added test '$test' from user '$user'\n";

    my $waiter = ANSTE::Manager::JobWaiter->instance();
    $waiter->jobReceived($job);

    my $mail = new ANSTE::Manager::MailNotifier();
    $mail->sendNotify($job);

   	return 'OK';
}

1;

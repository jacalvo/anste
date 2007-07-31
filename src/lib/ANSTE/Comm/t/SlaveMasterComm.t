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

use strict;
use warnings;

use ANSTE::Comm::MasterServer;
use ANSTE::Comm::SlaveClient;
use ANSTE::Comm::SharedData;

use threads;
use SOAP::Transport::HTTP;
use Net::Domain qw(hostname);

use Test::More tests => 5;

use constant PORT => 8001;

my $HOST = hostname();

# Starts Master Server thread
my $serverThread = threads->create('_startMasterServer');

my $waitThread = threads->create('_waitThread');

# Wait 1 second to the server start
sleep(1);

my $client = new ANSTE::Comm::SlaveClient();

my $URL = "http://$HOST:" . PORT;
ok($client->connect($URL), 'client connect');

ok($client->hostReady(), 'host ready');

ok($client->executionFinished(1), 'execution finished');

# Wait 1 seconds of courtesy and then finish the execution.
# This is due in case of test fail waitThread could never end,
# so we can't do a join.
sleep(1);

exit(0);


sub _startMasterServer
{
    my $server = new SOAP::Transport::HTTP::Daemon(LocalPort => PORT, 
                                                   Reuse => 1);
    $server->dispatch_to('ANSTE::Comm::MasterServer');
    $server->handle();
}

sub _waitThread
{
    my $data = ANSTE::Comm::SharedData->instance();

    ok($data->waitForReady($HOST), 'wait for ready');

    # Should return 1 because the return code = 1 passed in the client
    ok($data->waitForExecution($HOST), 'wait for execution');
}

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

use ANSTE::Comm::MasterClient;
use ANSTE::Comm::SlaveServer;

use Test::More tests => 4;
use SOAP::Transport::HTTP;

use constant PORT => 8000;
use constant SERVER => 'http://localhost:8000';

# Starts slave server in a separate process
my $pid = fork();
exit(1) if not defined($pid);
if ($pid == 0) {
    _startSlaveServer();
    exit(0);
}

# Wait 1 second to ensure that the server is started
sleep 1;

my $client = new ANSTE::Comm::MasterClient;
ok($client->connect(SERVER), 'server connect');

my $FILE;

ok(open($FILE, '>', 'true.sh'), 'create true.sh');
print $FILE '#!/bin/sh\n';
print $FILE 'true\n';
close($FILE);
ok($client->put('true.sh'), 'put true.sh');

unlink('true.sh');

ok($client->del('true.sh'), 'del true.sh');

# Terminates with the server process
kill(9, $pid);

exit(0);

sub _startSlaveServer
{
    my $server = new SOAP::Transport::HTTP::Daemon(LocalPort => PORT, 
                                                   Reuse => 1);
    $server->dispatch_to('ANSTE::Comm::SlaveServer');
    $server->handle();    
}

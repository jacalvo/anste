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

use Test::More tests => 14;
use SOAP::Transport::HTTP;

use constant PORT => '8000';
use constant SERVER => 'localhost';

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
ok($client->connect('http://' . SERVER . ':' . PORT), 'server connect');

my $FILE;

# Basic tests with single paths
ok(open($FILE, '>', 'true.sh'), 'create true.sh');
print $FILE "#!/bin/sh\n";
print $FILE "true\n";
close($FILE);
ok($client->put('true.sh'), 'put true.sh');

ok($client->exec('true.sh', 'out.log'), 'exec true.sh');

# Wait for execution finish
sleep 1;

ok($client->get('out.log'), 'get out.log');

unlink('true.sh');

ok($client->del('true.sh'), 'del true.sh');

unlink('out.log');

ok($client->del('out.log'), 'del out.log');

# Tests with more complex paths
my $DIR = 'anste-testdir';
mkdir $DIR;

my $FILE2;

ok(open($FILE2, '>', "$DIR/test.sh"), 'create DIR/test.sh');
print $FILE2 "#!/bin/sh\n";
print $FILE2 "echo 1234\n";
close($FILE2);
ok($client->put("$DIR/test.sh"), 'put DIR/test.sh');

ok($client->exec("$DIR/test.sh", "$DIR/out.log"), 'put DIR/test.sh');

# Wait for execution finish
sleep 1;

ok($client->get("$DIR/out.log"));

is(-s "$DIR/out.log", 5, 'size(out.log) == 5');

unlink("$DIR/test.sh");

ok($client->del("$DIR/test.sh"), 'del DIR/test.sh');

unlink("$DIR/out.log");

ok($client->del("$DIR/out.log"), 'del DIR/out.log');

rmdir $DIR;

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

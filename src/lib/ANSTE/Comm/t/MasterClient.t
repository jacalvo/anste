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

use Comm::MasterClient;

use Test::More tests => 7;

use constant SERVER => "http://localhost:8000";

my $client = new Comm::MasterClient;
$client->connect(SERVER);

ok($client->put("test.sh"), "put test.sh");

open(my $FILE, ">", "true.sh");
print $FILE "#!/bin/sh\n";
print $FILE "true\n";
close($FILE);
ok($client->put("true.sh"), "put true.sh");

ok($client->exec("true.sh"), "exec true.sh");

unlink("true.sh");

ok($client->exec("test.sh", "test.log"), "exec test.sh");

ok($client->del("test.sh"), "del test.sh");

ok($client->get("test.log"), "get test.log");

ok($client->del("test.log"), "del test.log");

unlink("test.log");

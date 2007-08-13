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

use warnings;
use strict;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use ANSTE::Validate;

use Test::More tests => 14;
use Error qw(:try);
use File::Temp qw(tempdir);

ok(ANSTE::Validate::path('/tmp/'), 'correct path');
ok(!ANSTE::Validate::path('/tmp/DOESNTEXISTS/'), 'incorrect path');

ok(ANSTE::Validate::system('Debian'), 'correct system');
ok(!ANSTE::Validate::system('NOEXISTSDebian'), 'incorrect system');

ok(ANSTE::Validate::virtualizer('Xen'), 'correct virtualizer');
ok(!ANSTE::Validate::virtualizer('NOEXISTSXen'), 'incorrect virtualizer');

ok(ANSTE::Validate::port(65535), 'correct port');
ok(!ANSTE::Validate::port(-1), 'incorrect port');
ok(!ANSTE::Validate::port('aab'), 'incorrect port');

ok(ANSTE::Validate::ip('192.168.0.1'), 'correct ip');
ok(ANSTE::Validate::ip('255.255.255.0'), 'correct ip');

ok(!ANSTE::Validate::ip('a.b.c.d'), 'incorrect ip');
ok(!ANSTE::Validate::ip('192.168.0'), 'incorrect ip');
ok(!ANSTE::Validate::ip('100.200.300.400'), 'incorrect ip');

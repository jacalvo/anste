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

use ANSTE::Image::Image;

use Test::More tests => 5;

my $image = new ANSTE::Image::Image(name => 'Name',
                                    ip => '192.168.0.150',
                                    memory => '256M');

is($image->name(), 'Name', 'image->name == Name');
is($image->ip(), '192.168.0.150', 'image->ip == 192.168.0.150');
is($image->memory(), '256M', 'image->memory == 256M');

$image->setIp('192.168.0.160');
is($image->ip(), '192.168.0.160', 'image set new ip');

$image->setMemory('512M');
is($image->memory(), '512M', 'image set new memory');

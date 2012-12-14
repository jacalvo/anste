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

use warnings;
use strict;

use ANSTE::Scenario::BaseImage;

use Test::More tests => 4;


my $image = ANSTE::Scenario::BaseImage->new();
isa_ok($image, 'ANSTE::Scenario::BaseImage');

ok($image->name() eq "", "Base Image name empty");
ok($image->mirror() eq "", "Base Image mirror empty");

$image->setMirror("mirror");
ok($image->mirror() eq "mirror", "Base Image mirror with value");

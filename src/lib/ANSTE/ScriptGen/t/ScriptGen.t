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

use ANSTE::Scenario::BaseImage;
use ANSTE::Scenario::Scenario;
use ANSTE::Image::Image;
use ANSTE::ScriptGen::BasePreInstall;
use ANSTE::ScriptGen::BaseImageSetup;
use ANSTE::ScriptGen::HostPreInstall;
use ANSTE::ScriptGen::HostImageSetup;

use Test::More tests => 4;

use constant IMAGE => 'sarge-ebox-base.xml';
use constant SCENARIO => 'scenario.xml';
use constant HOSTNAME => 'hostname1';
use constant IP => '192.168.45.192';

my $file = \*STDOUT;

my $image = new ANSTE::Scenario::BaseImage;
$image->loadFromFile(IMAGE);

my $gen = new ANSTE::ScriptGen::BasePreInstall($image);
$gen->writeScript($file);
pass('base pre-install script generation');

$gen = new ANSTE::ScriptGen::BaseImageSetup($image);
$gen->writeScript($file);
pass('base setup script generation');

$image = new ANSTE::Image::Image(name => HOSTNAME,
                                 ip => IP);

$gen = new ANSTE::ScriptGen::HostPreInstall($image);
$gen->writeScript($file);
pass('host pre-install script generation');


my $scenario = new ANSTE::Scenario::Scenario;
$scenario->loadFromFile(SCENARIO);
my $hosts = $scenario->hosts();
$gen = new ANSTE::ScriptGen::HostImageSetup($hosts->[0], 
                                            $scenario->system());
$gen->writeScript($file);
pass('host setup script generation');

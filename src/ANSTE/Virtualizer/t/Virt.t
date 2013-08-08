# Copyright (C) 2013 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

use ANSTE::Scenario::Scenario;

use Test::More tests => 5;

use constant SCENARIO => 'test-bridges.yaml';

my $scenario = new ANSTE::Scenario::Scenario();
$scenario->loadFromFile(SCENARIO);

is ($scenario->manualBridging(), 1, 'manual bridging is set to 1');

is ($scenario->hosts()->[0]->network()->interfaces()->[1]->name(), 'eth2', 'check that second interface of first host is eth2');

is ($scenario->hosts()->[0]->network()->interfaces()->[1]->bridge(), 3, 'check that eth2 of first host has bridge 3');

is (scalar @{$scenario->hosts()->[1]->bridges()}, 1, 'check that second host has one bridge');

is (scalar keys %{$scenario->bridges()}, 2, 'number of bridges in the scenario is 2');

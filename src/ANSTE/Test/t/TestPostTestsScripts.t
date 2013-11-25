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

use strict;
use warnings;

use ANSTE::Test::Suite;
use ANSTE::Test::ScenarioLoader;
use ANSTE::Config;

use Test::More tests => 11;

use constant SUITE => 'test';
use constant SUITE_YAML => 'test-yaml';

sub _checkTests # (tests)
{
	my ($tests) = @_;

    is(@{$tests}[2]->name(), "script1" , 'name = script1');
    is(@{$tests}[3]->name(), "script2" , 'name = script2');

    is(@{$tests}[2]->desc(), "PostTest added from the baseImage of the host hostName" , 'desc = text');
    is(@{$tests}[3]->desc(), "PostTest added from the baseImage of the host hostName" , 'desc = text');

    is(@{$tests}[2]->script(), "script1" , 'dir = script1');
    is(@{$tests}[3]->script(), "script2" , 'dir = script2');

    is(@{$tests}[2]->host(), "hostName" , 'host = hostName');
    is(@{$tests}[3]->host(), "hostName" , 'host = hostName');
}

my $suite = new ANSTE::Test::Suite();
$suite->loadFromDir(SUITE);
is(scalar @{$suite->tests()}, 2, 'size of tests prior loading the scenario = 2');

my $scenarioFile = $suite->scenario();
my $scenario = ANSTE::Test::ScenarioLoader->loadScenario($scenarioFile, $suite);

my $hosts = $scenario->hosts();
is(scalar @{$hosts}, 2, 'size hosts in scenario = 2');

is(scalar @{$suite->tests()}, 6, 'size of tests after loading the scenario = 6');
_checkTests($suite->tests());

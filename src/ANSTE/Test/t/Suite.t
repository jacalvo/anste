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
use ANSTE::Config;
use ANSTE::Exceptions::InvalidFile;

use Test::More tests => 9;

use constant SUITE => 'test';

sub testTest # (test)
{
    my ($test) = @_;
    my $name = $test->name();
    is($name, 'testName', 'name = testName');
    my $desc = $test->desc();
    is($desc, 'testDesc', 'desc = testDesc');
    my $host = $test->host();
    is($host, 'testHost', 'host = testHost');
	my $dir = $test->script();
    is($dir, 'testScript', 'script = testScript');
    my $vars = $test->variables();
    is($vars->{var3}, 'val3', 'local var3 is included with value val3');
    is($vars->{var2}, 'val2', 'global var2 is included with value val2');
    is($vars->{var1}, 'val4', 'var1 is overrided with local value val4');
}

sub test # (suite)
{
    my ($suite) = @_;
    my $name = $suite->name();
    is($name, 'suiteName', 'suite name = suiteName');
    my $desc = $suite->desc();
    is($desc, 'suiteDesc', 'suite desc = suiteDesc');

    my $test = shift @{$suite->tests()};
    testTest($test);
}

my $suite = new ANSTE::Test::Suite();
$suite->loadFromDir(SUITE);
test($suite);

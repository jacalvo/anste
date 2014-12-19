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

use Test::More tests => 27;

use constant SUITE => 'test';

sub testTest
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
    is($vars->{var4}, '', 'var4 has empty value');
    is($vars->{var5}, undef, 'var5 does not exists');
    is($vars->{var6}, 'BAR', 'check that global variables are interpolated');

    my $yaml = 'data/tests/test/suite.yaml';
    system ("cp $yaml /tmp/suite.yaml.bak");
    system ("sed -i 's/var3: val3/var3: val66/g' $yaml");
    system ("sed -i 's/var2: val2/var2: FOO/g' $yaml");
    system ("sed -i 's/testHost/hostModified/g' $yaml");

    $test->reloadVars();
    system ("mv /tmp/suite.yaml.bak $yaml");

    is($test->host(), 'hostModified', 'host = hostModified after reload');

    $vars = $test->variables();
    is($vars->{var3}, 'val66', 'local var3 is val66 after reload');
    is($vars->{var2}, 'FOO', 'global var2 is FOO after reload');
    is($vars->{var6}, 'BAR', 'global var6 is still BAR after reload');
}

sub testIncludeTest
{
    my ($test) = @_;

    my $name = $test->name();
    is($name, 'includedTest', 'name = includedTest');
    my $desc = $test->desc();
    is($desc, 'Included Description', 'desc = Included Description');
    my $host = $test->host();
    is($host, 'testHost', 'host = testHost');
    my $dir = $test->script();
    is($dir, 'includedScript', 'script = includedScript');
    my $vars = $test->variables();
    is($vars->{var1}, 'cow', 'local var1 is included with value cow');
}

sub testTestAfterReplace
{
    my ($test) = @_;

    my $vars = $test->variables();
    is($vars->{var3}, 'newval3', 'local var3 is included with value newval3 after replace');
    is($vars->{var2}, 'newval2', 'global var2 is included with value newval2 after replace');
    is($vars->{var1}, 'val4', 'var1 is still overrided with local value val4 after replace');
    is($vars->{var4}, '', 'var4 still has empty value after replace');
    is($vars->{var7}, 'newval2', 'check that new global variables are interpolated after replace');
    is($vars->{var6}, 'BAZ', 'check that previous interpolations have the new value');
}

my $suite = new ANSTE::Test::Suite();
$suite->loadFromDir(SUITE);
my $name = $suite->name();
is($name, 'suiteName', 'suite name = suiteName');
my $desc = $suite->desc();
is($desc, 'suiteDesc', 'suite desc = suiteDesc');
my $test = $suite->tests()->[0];
testTest($test);
$test = $suite->tests()->[1];
testIncludeTest($test);

$suite = new ANSTE::Test::Suite();
$suite->loadFromDir(SUITE, 'data/tests/test/vars.yaml');
$test = $suite->tests()->[0];
testTestAfterReplace($test);

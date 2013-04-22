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

use ANSTE::Report::JUnitWriter;
use ANSTE::Test::Suite;
use Test::More tests => 8;
use Test::Files;

my $file_name = "/tmp/result.xml";

my $test = ANSTE::Test::Test->new();
isa_ok($test, 'ANSTE::Test::Test');

$test->setName("probando");

my $testResult = ANSTE::Report::TestResult->new();
isa_ok($testResult, 'ANSTE::Report::TestResult');

$testResult->setTest($test);
$testResult->setValue("256");
$testResult->setDuration(0.09);
$testResult->setLog("data/files/log.txt");

my $suite = ANSTE::Test::Suite->new();
isa_ok( $suite, 'ANSTE::Test::Suite' );

ok($suite->name() eq "", "Test suite name empty");

$suite->setName("Test1");
ok($suite->name() eq "Test1", "Test suite name Test1");

my $writer = ANSTE::Report::JUnitWriter->new('');
isa_ok( $writer, 'ANSTE::Report::JUnitWriter' );

my $suiteResult = ANSTE::Report::SuiteResult->new('');
isa_ok( $suiteResult, 'ANSTE::Report::SuiteResult' );

$suiteResult->setSuite($suite);
$suiteResult->add($testResult);
$writer->_writeSuiteFile($suiteResult,$file_name);

file_ok($file_name, "<testsuite name=\"Test1\">
<desc></desc>
<testcase time=\"0.09\" name=\"probando\">
<failure message=\"Error in Anste Tests\">
&quot;probando&quot;
&lt;
&gt;
&apos;
&amp;
</failure>
</testcase>
</testsuite>\n", "Xml one contents");

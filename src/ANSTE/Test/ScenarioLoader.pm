# Copyright (C) 2007-2013 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

package ANSTE::Test::ScenarioLoader;

use strict;
use warnings;

use ANSTE::Scenario::Scenario;
use ANSTE::Test::Suite;
use ANSTE::Test::Test;

sub loadScenario
{
    my ($self, $file, $suite) = @_;

    my $scenario = new ANSTE::Scenario::Scenario();
    $scenario->loadFromFile($file);

    my $hosts = $scenario->hosts();

    foreach my $host (@{$hosts}) {

        my $baseImage = $host->baseImage();
        my $postTestsScripts = $baseImage->postTestsScripts();

        if (scalar @{$postTestsScripts} > 0 ) {
            _loadPostTestsScriptsAsTests($suite, $postTestsScripts, $host->name());
        }
    }

    return $scenario;
}

sub _loadPostTestsScriptsAsTests
{
    my ($suite, $scriptsToAdd, $hostName) = @_;

    foreach my $script (@{$scriptsToAdd}) {

        my $test = new ANSTE::Test::Test();

        $test->setName($script);
        $test->setDesc("PostTest added from the baseImage of the host $hostName");
        $test->setScript($script);
        $test->setHost($hostName);
        $test->setExecuteAlways(1);
        $test->{postScript} = 1;

        $suite->addTest($test);
    }
}

1;

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

use FindBin qw($Bin);
use lib "$Bin/../src";

use ANSTE::Status;

use Test::More tests => 5;

my $config = ANSTE::Config->instance();
$config->setImagePath('/tmp');

is $config->imagePath(), '/tmp', 'image path is properly overrided';

my $status = ANSTE::Status->instance();

$status->setCurrentScenario('foo');
$status->setDeployedHosts({ 'bar1' => '10.6.7.10', 'bar2' => '10.6.7.11' });

ok (-f $status->_statusFile(), 'status file exists');

is $status->currentScenario(), 'foo', 'current scenario is retrieved with correct value';
is_deeply $status->deployedHosts(), { 'bar1' => '10.6.7.10', 'bar2' => '10.6.7.11' }, 'retrieval of deployed hosts';

$status->remove();
ok (not (-f $status->_statusFile()), 'status file does not exists');

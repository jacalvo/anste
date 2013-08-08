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

use ANSTE::Manager::JobWaiter;
use ANSTE::Manager::Job;

use Test::More tests => 7;

my $waiter = ANSTE::Manager::JobWaiter->instance();

my $job1 = new ANSTE::Manager::Job('user1', 'test1');

is($job1->user(), 'user1', 'job1->user == user1');
is($job1->test(), 'test1', 'job1->test == test1');

my $job2 = new ANSTE::Manager::Job('user2', 'test2');
my $job3 = new ANSTE::Manager::Job('user3', 'test3');
my $job4 = new ANSTE::Manager::Job('user4', 'test4');

$waiter->jobReceived($job1);
$waiter->jobReceived($job2);
$waiter->jobReceived($job3);
$waiter->jobReceived($job4);

ok($waiter->deleteJob(3), 'delete job 3');

my @queue = @{$waiter->queue()};

is(scalar @queue, 3, 'queue size == 3');

ok($waiter->waitForJob(), 'wait for job');

@queue = @{$waiter->queue()};
is(scalar @queue, 2, 'queue size == 2');

$waiter->jobReceived($job3);
$waiter->jobReceived($job1);

@queue = @{$waiter->queue()};
is(scalar @queue, 4, 'queue size == 4');

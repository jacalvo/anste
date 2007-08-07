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

package ANSTE::Deploy::ScenarioDeployer;

use strict;
use warnings;

use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::HostDeployer;
use ANSTE::Deploy::WaiterServer;
use ANSTE::Config;

sub new # (scenario) returns new ScenarioDeployer object
{
	my ($class, $scenario) = @_;
	my $self = {};
	
	$self->{scenario} = $scenario;

	bless($self, $class);

	return $self;
}

sub deploy 
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    my @deployers;

    # Starts Master Server thread
    my $server = new ANSTE::Deploy::WaiterServer();
    $server->startThread();

    my $ipRange = ANSTE::Config->instance()->ipRange();

    my $number = 191;
    foreach my $host (@{$scenario->hosts()}) {
        my $deployer = new ANSTE::Deploy::HostDeployer($host);
        my $ip = "$ipRange.$number";
        my $hostname = $host->name();
        print "[$hostname] starting\n";
        $deployer->startDeployThread($ip);
        push(@deployers, $deployer);
        $number++;
    }

    foreach my $deployer (@deployers) {
        $deployer->waitForFinish();
        my $host = $deployer->{host}->name();
        print "[$host] finished\n";
    }
}

1;

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
use ANSTE::Comm::WaiterServer;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Constructor: new
#
#   Constructor for ScenarioDeployer class.
#
# Parameters:
#
#
# Returns:
#
#   A recently created <ANSTE::Deploy::ScenarioDeployer> object.
#
sub new # (scenario) returns new ScenarioDeployer object
{
	my ($class, $scenario) = @_;
	my $self = {};

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw EBox::Exception::InvalidType('scenario',
                                           'ANSTE::Scenario::Scenario');
    }
	
	$self->{scenario} = $scenario;
    $self->{deployers} = [];

	bless($self, $class);

	return $self;
}

# Method: deploy
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub deploy # returns hash ref with the ip of each host 
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    my $hostIP = {};

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    my $firstAddress = ANSTE::Config->instance()->firstAddress();

    # Separate the last number of the ip in order to increment it.
    my ($base, $number) = 
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;

    foreach my $host (@{$scenario->hosts()}) {
        my $deployer = new ANSTE::Deploy::HostDeployer($host);
        my $ip = "$base.$number";
        my $hostname = $host->name();
        $hostIP->{$hostname} = $ip;
    
        print "[$hostname] Starting deployment...\n";
        $deployer->startDeployThread($ip);
        push(@{$self->{deployers}}, $deployer);
        $number++;
    }

    foreach my $deployer (@{$self->{deployers}}) {
        $deployer->waitForFinish();
        my $host = $deployer->{host}->name();
        print "[$host] Deployment finished.\n";
    }

    return $hostIP; 
}

# Method: shutdown
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub shutdown
{
    my ($self) = @_;

    my $deployers = $self->{deployers};

    foreach my $deployer (@{$deployers}) {
        $deployer->shutdown();
        $deployer->deleteImage();
    }
}

1;

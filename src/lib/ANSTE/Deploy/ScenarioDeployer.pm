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

# Class: ScenarioDeployer
#
#   Deploys a given scenario creating its corresponding virtual machines
#   and configurating them properly.
#

# Constructor: new
#
#   Constructor for ScenarioDeployer class.
#   Initializes the object with the given scenario representation object.
#   Creates <ANSTE::Deploy::HostDeployer> objects for each host
#   in the scenario.
#
# Parameters:
# 
#   scenario - <ANSTE::Scenario::Scenario> object.
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
        throw ANSTE::Exception::InvalidType('scenario',
                                            'ANSTE::Scenario::Scenario');
    }
	
	$self->{scenario} = $scenario;

    # Create host deployers
    $self->{deployers} = [];

    my $firstAddress = ANSTE::Config->instance()->firstAddress();

    # Separate the last number of the ip in order to increment it.
    my ($base, $number) = 
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;

    foreach my $host (@{$scenario->hosts()}) {
        my $ip = "$base.$number";
        my $hostname = $host->name();
        my $deployer = new ANSTE::Deploy::HostDeployer($host, $ip);
        push(@{$self->{deployers}}, $deployer);
        $number++;
    }        

	bless($self, $class);

	return $self;
}

# Method: deploy
#
#   Starts the master server thread and another thread for the
#   deployment of each host in the scenario.
#   The deployment of each host is done through <ANSTE::Deploy::HostDeployer>.
#
# Returns:
#
#   hash - Contains the IP address of each deployed host indexed by hostname.
#
sub deploy # returns hash ref with the ip of each host 
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    my $hostIP = {};

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    if (ANSTE::Config->instance->autoCreateImages()) {
        $self->_createMissingBaseImages();
    }

    foreach my $deployer (@{$self->{deployers}}) {
        my $hostname = $deployer->host()->name();
        print "[$hostname] Starting deployment...\n";
        $deployer->startDeployThread();

        $hostIP->{$hostname} = $deployer->ip();
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
#   Notify all of the deployer threads of the scenario that have to shut down.
#   Also ask them for image deletion.
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

# Method: destroy
#
#   Destroys immediately all the running virtual machines from this scenario.
#   Also ask them for image deletion.
#
sub destroy
{
    my ($self) = @_;

    my $deployers = $self->{deployers};
   
    foreach my $deployer (@{$deployers}) {
        $deployer->destroy();
        $deployer->deleteImage();
    }        
}

sub _createMissingBaseImages
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    # Tries to create all the base images, if a image
    # already exists, does nothing.
    foreach my $host (@{$scenario->hosts()}) {
        my $image = $host->baseImage();
        my $hostname = $host->name();
        print "[$hostname] Auto-creating base image if not exists...\n";
        my $creator = new ANSTE::Image::Creator($image);
        if($creator->createImage()) {
            print "[$hostname] Base image created.\n";
        }
        else {
            print "[$hostname] Base image already exists.\n";
        }
    }
}

1;

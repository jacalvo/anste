# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2013 Rubén Durán Balda <rduran@zentyal.com>
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

use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::HostDeployer;
use ANSTE::Comm::WaiterServer;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Virtualizer::Virtualizer;

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
    my $config = ANSTE::Config->instance();

    $self->{virtualizer} = ANSTE::Virtualizer::Virtualizer->instance();

    $self->{scenario} = $scenario;

    # Create host deployers
    $self->{deployers} = [];

    my $firstAddress = $config->firstAddress();

    # Separate the last number of the ip in order to increment it.
    my ($base, $number) =
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;

    # Add the bridge for the comunications interface
    $scenario->addBridge($base, 1);

    foreach my $host (@{$scenario->hosts()}) {
        my $ip = "$base.$number";
        my $hostname = $host->name();
        my $deployer = new ANSTE::Deploy::HostDeployer($host, $ip);
        push(@{$self->{deployers}}, $deployer);
        $number++;

        # Add the bridges needed for each host if no manual bridging option is set
        unless ($scenario->manualBridging()) {
            foreach my $iface (@{$host->network()->interfaces()}) {
                my ($net, $unused) =
                    $iface->address() =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;
                if ($net) {
                    my $bridge = $scenario->addBridge($net);
                    $iface->setBridge($bridge);
                }
            }
        }
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

    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();

    if (not $reuse) {
        if ($config->autoDownloadImages()) {
            $self->_downloadMissingBaseImages();
        } elsif ($config->autoCreateImages()) {
            $self->_createMissingBaseImages();
        } else {
            my $action = $self->imageMissingAction();
            throw ANSTE::Exceptions::Error("Not valid action '$action'.");
        }

        # Set up the network before deploy
        print "Setting up network...\n";
        $self->{virtualizer}->createNetwork($scenario)
            or throw ANSTE::Exceptions::Error('Error creating network.');
    }

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    foreach my $deployer (@{$self->{deployers}}) {
        my $hostname = $deployer->host()->name();
        if (not $reuse) {
            print "[$hostname] Starting deployment...\n";
            $deployer->startDeployThread();
        }

        my $ip = $deployer->ip();
        if (not $ip) {
            throw ANSTE::Exceptions::Error("Canot get IP for host $hostname");
        }
        $hostIP->{$hostname} = $ip;
    }

    if (not $reuse) {
        foreach my $deployer (@{$self->{deployers}}) {
            my $os = $deployer->{host}->OS();
            if ($os eq 'linux') {
                $deployer->waitForFinish();
            }
            my $host = $deployer->{host}->name();
            print "[$host] Deployment finished.\n";
        }
    }

    # Save status for other tools like anste-connect
    my $status = ANSTE::Status->instance();
    $status->setCurrentScenario($scenario->{file});
    $status->setDeployedHosts($hostIP);

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
    $self->{virtualizer}->destroyNetwork($self->{scenario});

    ANSTE::Status->instance()->remove();
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
    $self->{virtualizer}->destroyNetwork($self->{scenario});

    ANSTE::Status->instance()->remove();
}

sub _createMissingBaseImages
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    # Tries to create all the base images, if a image
    # already exists, does nothing.
    # Only creates images for linux hosts
    foreach my $host (@{$scenario->hosts()}) {
        my $os = $host->OS();
        my $hostname = $host->name();
        if ($os eq 'linux') {
            my $image = $host->baseImage();
            my $hostname = $host->name();
            print "[$hostname] Auto-creating base image if not exists...\n";
            my $creator = new ANSTE::Image::Creator($image);
            if ($creator->createImage()) {
                print "[$hostname] Base image created.\n";
            } else {
                print "[$hostname] Base image already exists.\n";
            }
        } else {
            print "[$hostname] Ignoring not linux host.\n";
            # TODO: Error if baseimage does not exists
        }
    }
}

sub _downloadMissingBaseImages
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    # Tries to download all the base images, if a image
    # already exists, does nothing.
    foreach my $host (@{$scenario->hosts()}) {
        my $image = $host->baseImage();
        my $hostname = $host->name();
        print "[$hostname] Auto-downloading base image if not exists...\n";
        my $getter = new ANSTE::Image::Getter($image);
        if ($getter->getImage()) {
            print "[$hostname] Base image downloaded.\n";
        } else {
            print "[$hostname] Base image already exists.\n";
        }
    }
}

1;

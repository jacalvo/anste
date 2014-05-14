# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2013-2014 Rubén Durán Balda <rduran@zentyal.com>
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

use ANSTE;
use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::HostDeployer;
use ANSTE::Comm::WaiterServer;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Virtualizer::Virtualizer;
use ANSTE::Image::Commands;

use File::Slurp;
use POSIX;

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
sub new
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
    my $commIface = $config->commIface();

    # Separate the last number of the ip in order to increment it.
    my ($base, $number) =
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;

    # Add the bridge for the comunications interface
    $scenario->addBridge($base, 1);

    foreach my $host (@{$scenario->hosts()}) {
        my $ip = "$base.$number";

        # Add the bridges needed for each host if no manual bridging option is set
        unless ($scenario->manualBridging()) {
            foreach my $iface (@{$host->network()->interfaces()}) {
                my ($net, $unused) =
                    $iface->address() =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;
                if ($net) {
                    my $bridge = $scenario->addBridge($net);
                    $iface->setBridge($bridge);
                }

                # IP for the Host from the scenario
                if ($iface->name() eq $commIface) {
                    $ip = $iface->address();
                }
            }
        }

        my $deployer = new ANSTE::Deploy::HostDeployer($host, $ip);
        push(@{$self->{deployers}}, $deployer);
        $number++;
    }

    bless ($self, $class);

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
sub deploy
{
    my ($self) = @_;

    my $scenario = $self->{scenario};

    my $hostIP = {};

    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    if (not $reuse) {
        $self->_createOrGetMissingBaseImages();

        # Set up the network before deploy
        ANSTE::info("Setting up network...");
        $self->{virtualizer}->createNetwork($scenario)
            or throw ANSTE::Exceptions::Error('Error creating network.');

        $self->_importMissingBaseImages();

        $self->_autoUpdateBaseImages() if $config->autoUpdate();
    }

    foreach my $deployer (@{$self->{deployers}}) {
        my $hostname = $deployer->host()->name();
        if (not $reuse) {
            ANSTE::info("[$hostname] Starting deployment...");
            $deployer->startDeployThread();
        }

        my $ip = $deployer->ip();
        if (not $ip) {
            throw ANSTE::Exceptions::Error("Cannot get IP for host $hostname");
        }
        $hostIP->{$hostname} = $ip;
    }

    if (not $reuse) {
        foreach my $deployer (@{$self->{deployers}}) {
            $deployer->waitForFinish();

            my $host = $deployer->{host}->name();
            ANSTE::info("[$host] Deployment finished.");
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

    return if ANSTE::Config->instance()->noDestroy();

    my $deployers = $self->{deployers};

    foreach my $deployer (@{$deployers}) {
        $deployer->destroy();
        $deployer->deleteImage();
    }
    $self->{virtualizer}->destroyNetwork($self->{scenario});

    ANSTE::Status->instance()->remove();
}

sub _createOrGetMissingBaseImages
{
    my ($self) = @_;

    my $scenario = $self->{scenario};
    my $config = ANSTE::Config->instance();

    # Tries to create all the base images, if a image
    # already exists, does nothing.
    # Does not create raw base images
    foreach my $host (@{$scenario->hosts()}) {
        my $hostname = $host->name();
        my $image = $host->baseImage();
        if ($host->baseImageType() eq 'raw' or $config->autoDownloadImages()) {
            ANSTE::info("[$hostname] Auto-downloading base image if not exists...");
            my $getter = new ANSTE::Image::Getter($image);
            if ($getter->getImage()) {
                ANSTE::info("[$hostname] Base image downloaded.");
            } else {
                ANSTE::info("[$hostname] Base image already exists.");
            }
        } else {
            ANSTE::info("[$hostname] Auto-creating base image if not exists...");
            my $creator = new ANSTE::Image::Creator($image);
            if ($creator->createImage()) {
                ANSTE::info("[$hostname] Base image created.");
            } else {
                ANSTE::info("[$hostname] Base image already exists.");
            }
        }
    }
}

sub _importMissingBaseImages
{
    my ($self) = @_;

    my $scenario = $self->{scenario};
    foreach my $host (@{$scenario->hosts()}) {
        my $image = $host->baseImage();
        my $hostname = $host->name();
        if ($host->baseImageType() eq 'raw') {
            ANSTE::info("[$hostname] Auto-importing base image if not exists...");
            my $cmd = new ANSTE::Image::Commands($image);
            $cmd->importImage($hostname);
        }
    }
}

sub _autoUpdateBaseImages
{
    my ($self) = @_;

    my $config = ANSTE::Config->instance();
    my $imgdir = $config->imagePath();

    my $timestamp = strftime("%Y%m%d", localtime(time));

    # TODO: Update base images at the same time
    my $scenario = $self->{scenario};
    foreach my $host (@{$scenario->hosts()}) {
        # Do not upgrade raw base images
        unless ($host->baseImageType() eq 'raw') {
            my $hostname = $host->name();
            my $baseimage = $host->baseImage();
            my $name = $baseimage->name();

            my $tsFile = "$imgdir/$name/last-update";
            my $lastUpdateTS = read_file($tsFile, err_mode => 'quiet');
            chomp($lastUpdateTS) if $lastUpdateTS;

            # Only update if not updated today
            if(not $lastUpdateTS or ($lastUpdateTS lt $timestamp)) {
                ANSTE::info("[$hostname] Auto-updating base image...");

                my $cmd = new ANSTE::Image::Commands($baseimage);

                if ($cmd->updateSystem()) {
                    ANSTE::info("[$hostname] Auto-update completed successfully.");
                } else {
                    ANSTE::info("[$hostname] Could not update base image.");
                }
                $cmd->shutdown();

                # Update timestamp
                write_file($tsFile, $timestamp);
            }
        }
    }
}

1;

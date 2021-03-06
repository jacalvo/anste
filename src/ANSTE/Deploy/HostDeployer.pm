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

package ANSTE::Deploy::HostDeployer;

use strict;
use warnings;

use ANSTE::Scenario::Host;
use ANSTE::ScriptGen::HostImageSetup;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::MasterServer;
use ANSTE::Comm::HostWaiter;
use ANSTE::Image::Image;
use ANSTE::Image::Commands;
use ANSTE::Image::Creator;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Virtualizer::Virtualizer;
use ANSTE::System::System;

use threads;
use TryCatch;

# Class: HostDeployer
#
#   Deploys a host virtual machine in a separate thread.
#   The operations are done with the classes in <ANSTE::Image> module.
#

# Constructor: new
#
#   Constructor for HostDeployer class.
#   Initializes the object with the given host representation object and
#   the given IP address for the communications interface.
#
# Parameters:
#
#   host - <ANSTE::Scenario::Host> object.
#   ip - IP address to be assigned.
#
# Returns:
#
#   A recently created <ANSTE::Deploy::HostDeployer> object.
#
sub new
{
    my ($class, $host, $ip) = @_;
    my $self = {};

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');
    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw ANSTE::Exception::InvalidType('host',
                                            'ANSTE::Scenario::Host');
    }

    my $config = ANSTE::Config->instance();
    $self->{system} = ANSTE::System::System->instance();
    $self->{virtualizer} = ANSTE::Virtualizer::Virtualizer->instance();

    my $hostname = $host->name();
    my $memory = $host->memory();
    if (not $memory) {
        $memory = $host->baseImage()->memory();
    }
    my $cpus = $host->cpus();
    if (not $cpus) {
        $cpus = $host->baseImage()->cpus();
    }
    my $swap = $host->baseImage()->swap();
    my $image = new ANSTE::Image::Image(name => $hostname,
                                        memory => $memory,
                                        swap => $swap,
                                        cpus => $cpus,
                                        ip => $ip);
    $image->setNetwork($host->network());

    my $cmd = new ANSTE::Image::Commands($image);

    $self->{host} = $host;
    $self->{image} = $image;
    $self->{cmd} = $cmd;
    $self->{ip} = $ip;

    bless($self, $class);

    return $self;
}

# Method: host
#
#   Gets the the host object.
#
# Returns:
#
#   ref - <ANSTE::Scenario::Host> object.
#
sub host
{
    my ($self) = @_;

    return $self->{host};
}

# Method: ip
#
#   Gets the IP address assigned to the object's host.
#
# Returns:
#
#   string - contains the IP address
#
sub ip
{
    my ($self) = @_;

    return $self->{ip};
}

# Method: startDeployThread
#
#   Starts the deploying thread for the object's host.
#
# Returns:
#
#   ref - Reference to the created thread.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub startDeployThread
{
    my ($self, $ip) = @_;

    $self->{thread} = threads->create('_deploy', $self);
}

# Method: waitForFinish
#
#   Waits until the deploying thread finishes.
#
sub waitForFinish
{
    my ($self) = @_;

    my $ret = $self->{thread}->join();
    if (not $ret) {
        my $host = $self->{host}->name();
        throw ANSTE::Exceptions::Error("[$host] Error in the deployment.");
    }
    $self->{virtualizer}->finishImageCreation($self->{image}->{name});
}

# Method: shutdown
#
#   Shuts down the image and virtual machine creation.
#
sub shutdown
{
    my ($self) = @_;

    my $cmd = $self->{cmd};

    $cmd->shutdown();
}

# Method: destroy
#
#   Stops immediately the virtual machine of the host.
#
sub destroy
{
    my ($self) = @_;

    my $cmd = $self->{cmd};

    $cmd->destroy();
}

# Method: deleteImage
#
#   Deletes the image of the deployed hosts that does not use raw base images
#
sub deleteImage
{
    my ($self) = @_;

    my $cmd = $self->{cmd};

    my $host = $self->{host};
    unless ($host->baseImageType() eq 'raw') {
        $cmd->deleteImage();
    }
}

# Return True if the deployment was successful and False otherwise
sub _deploy
{
    my ($self) = @_;

    my $host = $self->{host};

    if ($host->baseImageType() eq 'raw') {
        return $self->_deploySnapshot();
    } else {
        return $self->_deployCopy();
    }
}

sub _deploySnapshot
{
    my ($self) = @_;

    my $host = $self->{host};
    my $hostname = $host->name();
    my $cmd = $self->{cmd};

    # TODO: libvirt dependant => refactor
    ANSTE::info("[$hostname] Restoring base snapshot...");
    $cmd->restoreBaseSnapshot($hostname);

    ANSTE::info("[$hostname] Creating virtual machine...");
    my $virtualizer = $self->{virtualizer};
    return $virtualizer->startVM($self->{image}, $host);
}

sub _deployCopy
{
    my ($self) = @_;

    my $host = $self->{host};
    my $hostname = $host->name();

    my $system = $self->{system};

    my $image = $self->{image};
    my $cmd = $self->{cmd};

    my $ip = $image->ip();

    my $config = ANSTE::Config->instance();

    # Add communications interface
    my $commIface = $image->commInterface();
    # This gateway is not needed anymore
    # and may conflict with the real one.
    $commIface->removeGateway() unless $host->isRouter();
    unshift (@{$host->network()->interfaces()}, $commIface);

    # Steps previous to the VM creation
    unless ($cmd->preCreateVirtualMachine($host)) {
        return undef;
    }

    ANSTE::info("[$hostname] Creating virtual machine ($ip)...");
    $cmd->createVirtualMachine();

    my $ret = 0;
    try {
        # Execute pre-install scripts
        my $pre = $host->preScripts();
        if (@{$pre}) {
            ANSTE::info("[$hostname] Executing pre scripts...");
            $cmd->executeScripts($pre);
        }

        my $setupScript = "$hostname-setup.sh";
        ANSTE::info("[$hostname] Generating setup script...");
        $self->_generateSetupScript($setupScript);
        $self->_executeSetupScript($ip, $setupScript);

        # It worths it stays here in order to be able to use pre/post-install
        # scripts as well. This permits us to move trasferred file,
        # change their rights and so on.
        my $list = $host->{files}->list(); # retrieve files list
        ANSTE::info("[$hostname] Transferring files...");
        $cmd->transferFiles($list);
        ANSTE::info("... done");

        # NAT with this address is not needed anymore
        my $iface = $config->natIface();
        $system->disableNAT($iface, $commIface->address());
        # Adding the new nat rule
        my $interfaces = $host->network()->interfaces();
        foreach my $if (@{$interfaces}) {
            if ($if->gateway() eq $config->gateway()) {
                $system->enableNAT($iface, $if->address());
                last;
            }
        }

        # Execute post-install scripts
        my $post = $host->postScripts();
        if (@{$post}) {
            ANSTE::info("[$hostname] Executing post scripts...");
            $cmd->executeScripts($post);
        }

        $ret = 1;
    } catch (ANSTE::Exceptions::Error $e) {
        my $msg = $e->message();
        ANSTE::info("[$hostname] ERROR: $msg");
    } catch ($e) {
        ANSTE::info("[$hostname] ERROR: $e");
    }
    return $ret;
}

sub _generateSetupScript # (script)
{
    my ($self, $script) = @_;

    my $host = $self->{host};
    my $hostname = $host->name();

    my $generator = new ANSTE::ScriptGen::HostImageSetup($host);
    my $FILE;
    open($FILE, '>', $script)
        or throw ANSTE::Exceptions::Error("Can't open file $script: $!");
    $generator->writeScript($FILE);
    close($FILE)
        or throw ANSTE::Exceptions::Error("Can't close file $script: $!");
}

sub _executeSetupScript
{
    my ($self, $host, $script) = @_;

    my $system = $self->{system};

    my $client = new ANSTE::Comm::MasterClient;
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    my $config = ANSTE::Config->instance();

    my $PORT = $config->anstedPort();
    $client->connect("http://$host:$PORT");

    my $verbose = $config->verbose();

    my $hostname = $self->{host}->name();

    ANSTE::info("[$hostname] Executing setup script...") if $verbose;
    $client->put($script) or ANSTE::info("Upload failed");
    $client->exec($script, "$script.out") or ANSTE::info("Failed");
    my $ret = $waiter->waitForExecution($hostname);
    ANSTE::info("[$hostname] Setup script finished (Return value = $ret).");

    if ($verbose) {
        ANSTE::info("[$hostname] Script executed with the following output:");
        $client->get("$script.out");
        $self->_printOutput($hostname, "$script.out");
    }

    ANSTE::info("[$hostname] Deleting generated files...") if $verbose;
    $client->del($script);
    $client->del("$script.out");
    unlink ($script);
    unlink ("$script.out") if $verbose;

    if ($ret) {
        throw ANSTE::Exceptions::Error("Setup script execution failed.");
    }
}

sub _printOutput # (hostname, file)
{
    my ($self, $hostname, $file) = @_;

    my $FILE;
    open ($FILE, '<', $file) or die "Can't open file $file: $!";
    my @lines = <$FILE>;
    foreach my $line (@lines) {
        ANSTE::info("[$hostname] $line");
    }
    ANSTE::info("");
    close ($FILE) or die "Can't close file $file: $!";
}

1;

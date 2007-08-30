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

use threads;
use threads::shared;
use Error qw(:try);

use constant SETUP_SCRIPT => 'setup.sh';

my $lockMount : shared;

sub new # (host) returns new HostDeployer object
{
	my ($class, $host) = @_;
	my $self = {};

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    if (not $host->isa('ANSTE::Scenario::Host')) {
        throw EBox::Exception::InvalidType('host',
                                           'ANSTE::Scenario::Host');
    }

	$self->{host} = $host;
    $self->{image} = undef;
    $self->{cmd} = undef;

    my $config = ANSTE::Config->instance();
    my $system = $config->system();
    my $virtualizer = $config->virtualizer();

    eval("use ANSTE::System::$system");
    die "Can't load package $system: $@" if $@;

    eval("use ANSTE::Virtualizer::$virtualizer");
    die "Can't load package $virtualizer: $@" if $@;

    $self->{system} = "ANSTE::System::$system"->new();
    $self->{virtualizer} = "ANSTE::Virtualizer::$virtualizer"->new();

	bless($self, $class);

	return $self;
}

sub startDeployThread # (ip)
{
    my ($self, $ip) = @_;

    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

    my $host = $self->{host};
    my $hostname = $host->name();
    my $memory = $host->baseImage()->memory();
    my $image = new ANSTE::Image::Image(name => $hostname,
                                        memory => $memory,
                                        ip => $ip);
    $image->setNetwork($host->network());

    my $cmd = new ANSTE::Image::Commands($image);

    $self->{image} = $image;
    $self->{cmd} = $cmd;

    $self->{thread} = threads->create('_deploy', $self);
}

sub waitForFinish
{
    my ($self) = @_;
    
    $self->{thread}->join();
}

sub _deploy
{
    my ($self) = @_;

    my $image = $self->{image};
    my $cmd = $self->{cmd};

    my $host = $self->{host};
    my $hostname = $host->name();
    my $ip = $image->ip();

    print "[$hostname] Creating a copy of the base image...\n";
    try {
        $self->_copyBaseImage() or die "Can't copy base image";
    } catch ANSTE::Exceptions::NotFound with {
        if (ANSTE::Config->instance->autoCreateImages()) {
            print "[$hostname] Base image not found, creating...\n";
            my $creator = new ANSTE::Image::Creator($host->baseImage());
            $creator->createImage();
            $self->_copyBaseImage() or die "Can't copy base image";
            print "[$hostname] Base image created.\n";
        } else {
            die "[$hostname] Base image not found, can't continue.";
        }
    };

    # Critical section here to prevent mount errors with loop device busy
    { 
        lock($lockMount);
        print "[$hostname] Updating hostname on the new image...\n";
        $self->_updateHostname();
    };

    print "[$hostname] Creating virtual machine ($ip)...\n"; 
    $cmd->createVirtualMachine();

    # Add communications interface
    my $commIface = $image->commInterface();
    # This gateway is not needed anymore
    # and may conflict with the real one.
    $commIface->removeGateway();
    $host->network()->addInterface($commIface);

    # Execute pre-install scripts
    print "[$hostname] Executing pre scripts...\n";
    $cmd->executeScripts($host->preScripts());

    print "[$hostname] Generating setup script...\n";
    $self->_generateSetupScript(SETUP_SCRIPT);
    $self->_executeSetupScript($ip, SETUP_SCRIPT);

    # Execute post-install scripts
    print "[$hostname] Executing post scripts...\n";
    $cmd->executeScripts($host->postScripts());
}

sub shutdown
{
    my ($self) = @_;

    my $cmd = $self->{cmd};

    my $host = $self->{host};
    my $hostname = $host->name();

    print "[$hostname] shutting down...\n";
    $cmd->shutdown();
}

sub deleteImage
{
    my ($self) = @_;

    my $virtualizer = $self->{virtualizer};

    my $host = $self->{host};
    my $hostname = $host->name();

    print "[$hostname] deleting image...\n";
    $virtualizer->deleteImage($hostname);
}

sub _copyBaseImage
{
    my ($self) = @_;

    my $virtualizer = $self->{virtualizer};

    my $host = $self->{host};

    my $baseimage = $host->baseImage();
    my $newimage = $self->{image}; 

    $virtualizer->createImageCopy($baseimage, $newimage);
}

sub _updateHostname
{
    my ($self) = @_;

    my $cmd = $self->{cmd};
    
    try {
        $cmd->mount() or die "Can't mount image: $!";
    } catch Error with {
        $cmd->deleteMountPoint();
        die "Can't mount image.";
    };

    try {
        $cmd->copyHostFiles() or die "Can't copy files: $!";
    } finally {
        $cmd->umount() or die "Can't unmount image: $!";
    };
}

sub _generateSetupScript # (script)
{
    my ($self, $script) = @_;
    
    my $host = $self->{host};
    my $hostname = $host->name();

    my $generator = new ANSTE::ScriptGen::HostImageSetup($host);
    my $FILE;
    open($FILE, '>', $script) or die "Can't open file $script: $!";
    $generator->writeScript($FILE);
    close($FILE) or die "Can't close file $script: $!";
}

sub _executeSetupScript # (host, script)
{
    my ($self, $host, $script) = @_;

    my $system = $self->{system};

    my $client = new ANSTE::Comm::MasterClient;
    my $PORT = ANSTE::Config->instance()->anstedPort(); 
    $client->connect("http://$host:$PORT");

    my $hostname = $self->{host}->name();

    print "[$hostname] Uploading setup script...\n";
    $client->put($script);

    print "[$hostname] Executing setup script...\n";
    $client->exec($script, "$script.out");

    print "[$hostname] Script executed with the following output:\n";
    $client->get("$script.out");
    $self->_printOutput($hostname, "$script.out");

    print "[$hostname] Deleting generated files...\n";
    $client->del($script);
    $client->del("$script.out");
    unlink($script);
    unlink("$script.out");
}

sub _printOutput # (hostname, file)
{
    my ($self, $hostname, $file) = @_;

    my $FILE;
    open($FILE, '<', $file) or die "Can't open file $file: $!";
    my @lines = <$FILE>;
    foreach my $line (@lines) {
        print "[$hostname] $line";
    }
    print "\n";
    close($FILE) or die "Can't close file $file: $!";
}

1;

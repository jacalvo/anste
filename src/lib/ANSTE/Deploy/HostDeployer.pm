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
use ANSTE::Image::Commands;
use ANSTE::ScriptGen::HostImageSetup;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::MasterServer;
use ANSTE::Comm::HostWaiter;
use ANSTE::Image::Image;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use threads;
use Error qw(:try);

use constant SETUP_SCRIPT => 'setup.sh';

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

    my $config = ANSTE::Config->instance();
    my $system = $config->system();
    my $virtualizer = $config->virtualizer();
    my $image = undef;

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

    $self->{thread} = threads->create('deploy', $self, $ip);

}

sub waitForFinish
{
    my ($self) = @_;
    
    $self->{thread}->join();
}

sub deploy # (ip)
{
    my ($self, $ip) = @_;

    defined $ip or
        throw ANSTE::Exceptions::MissingArgument('ip');

    my $host = $self->{host};
    my $hostname = $host->name();
    my $memory = $host->baseImage()->memory();

    $self->{image} = new ANSTE::Image::Image(name => $hostname,
                                             memory => $memory,
                                             ip => $ip);
   
    print "[$hostname] Creating a copy of the base image\n";
    $self->_copyBaseImage() or die "Can't copy base image";

    print "[$hostname] Updating hostname on the new image\n";
    $self->_updateHostname();

    my $cmd = $self->{cmd};
    print "[$hostname] Creating virtual machine ($ip)\n"; 
    $cmd->createVirtualMachine();

    print "[$hostname] Generating setup script...\n";
    $self->_generateSetupScript(SETUP_SCRIPT);
    $self->_executeSetupScript($ip, SETUP_SCRIPT);
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

    my $image = $self->{image}; 

    my $cmd = new ANSTE::Image::Commands($image);

    $self->{cmd} = $cmd;

    $cmd->mount() or die "Can't mount image: $!";

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
    $generator->writeScript(\*STDOUT);
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

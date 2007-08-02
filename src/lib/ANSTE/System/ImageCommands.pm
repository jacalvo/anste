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

package ANSTE::System::ImageCommands;

use warnings;
use strict;

use ANSTE::Config;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::HostWaiter;
use ANSTE::System::BaseScriptGen;
use ANSTE::System::CommInstallGen;

use Cwd;
use File::Temp qw(tempfile tempdir);

# TODO: autogenerate it!
use constant XEN_TOOLS_CONFIG => 'conf/xen-tools.conf';

sub new # (image) returns new Commands object
{
	my ($class, $image) = @_;
	my $self = {};

    $self->{mountPoint} = undef;
    $self->{image} = $image;

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

sub create
{
	my ($self) = @_;

    my $name = $self->{image}->name();

    # TODO: Autogenerate this 
    my $confFile = getcwd() . "/data/".XEN_TOOLS_CONFIG;

    my $virtualizer = $self->{virtualizer};

    # TODO: Erradicate this fucking IP!!!
    $virtualizer->createBaseImage(name => $name,
                                 ip => '192.168.45.191',
                                 config => $confFile);
}

sub mount
{
	my ($self) = @_;

    my $name = $self->{image}->name();

    $self->{mountPoint} = tempdir() or die "Can't create temp directory: $!";

    my $mountPoint = $self->{mountPoint};

    # Read images path from the config
    my $config = ANSTE::Config->instance();
    my $imagePath = $config->imagePath();

    # Get the image file from the specific virtualizer
    my $image = $self->{virtualizer}->imageFile($imagePath, $name);

    my $system = $self->{system};

    $system->mountImage($image, $mountPoint);
}

sub copyBaseFiles
{
    my ($self) = @_;

    my $mountPoint = $self->{mountPoint};
    my $image = $self->{image};
    my $system = $self->{system};

    # Generates the installation script on a temporary file
    my $gen = new ANSTE::System::CommInstallGen($image);
    my ($fh, $filename) = tempfile() or die "Can't create temporary file: $!";
    $gen->writeScript($fh);
    close($fh) or die "Can't close temporary file: $!";
    # Gives execution perm to the script
    chmod(700, $filename) or die "Can't chmod $filename: $!";
    
    # Executes the installation script passing the mount point
    # of the image as argument
    my $ret = $system->execute("$filename $mountPoint");

    unlink($filename) or die "Can't unlink $filename: $!";

    return $ret;
}

sub installBasePackages
{
    my ($self) = @_;

    my $LIST;

    my $mountPoint = $self->{mountPoint};

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif ($pid == 0) { # child
        chroot($mountPoint) or die "Can't chroot: $!";
        $ENV{HOSTNAME} = $self->{image}->name();
        
        my $system = $self->{system};

        my $ret = $system->installBasePackages();

        exit($ret);
    }
    else { # parent
        waitpid($pid, 0);
        return($?);
    }
}

sub prepareSystem 
{
    my ($self) = @_;

    my $image = $self->{image};
    
    my $client = new ANSTE::Comm::MasterClient;
    # FIXME: hardcoded!!!
    $client->connect('http://192.168.45.191:8000');

    my $name = $image->name();

    $self->_createVirtualMachine($name);

    my $setupScript = 'install.sh';
    my $gen = new ANSTE::System::BaseScriptGen($image);

    my $FILE;
    open($FILE, '>', $setupScript) 
        or die "Can't create $setupScript: $!";

    $gen->writeScript($FILE);

    close($FILE) 
        or die "Can't close file $setupScript: $!";

    $self->_executeSetup($client, $setupScript);

    # TODO: Do all this file things in /tmp
    unlink($setupScript)
        or die "Can't remove $setupScript: $!";
}


sub umount
{
    my ($self) = @_;
    
    my $mountPoint = $self->{mountPoint};
    my $system = $self->{system};

    my $ret = $system->unmount($mountPoint);
    
    rmdir($mountPoint) or die "Can't remove mount directory: $!";

    return($ret);
}

sub shutdown
{
    my ($self) = @_;

    my $image = $self->{image}->name();
    my $virtualizer = $self->{virtualizer}; 

    # TODO: Maybe this could be done more softly sending poweroff :)
    $virtualizer->shutdownImage($image);
}

sub _createVirtualMachine # (name)
{
    my ($self, $name) = @_;

    my $virtualizer = $self->{virtualizer};

    $virtualizer->createVM($name);

    print "Waiting for the system start...\n";
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    $waiter->waitForReady($name);
    print "System is up\n";
}

sub _executeSetup # (client, script)
{
    my ($self, $client, $script) = @_;

    my $waiter = ANSTE::Comm::HostWaiter->instance();

    print "Trying to put $script\n";
    my $ret = $client->put($script);
    print "Server returned $ret\n";
    print "Trying to exec $script\n";
    $ret = $client->exec($script);
    print "Server returned $ret\n";
    my $image = $self->{image}->name();
    $ret = $waiter->waitForExecution($image);
    print "Execution finished with return value = $ret\n";
}

1;

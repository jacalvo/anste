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

package ANSTE::Image::Commands;

use warnings;
use strict;

use ANSTE::Config;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::HostWaiter;
use ANSTE::ScriptGen::BasePreInstall;
use ANSTE::ScriptGen::BaseImageSetup;
use ANSTE::ScriptGen::HostPreInstall;
use ANSTE::Image::Image;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use Cwd;
use File::Temp qw(tempfile tempdir);

sub new # (image) returns new Commands object
{
	my ($class, $image) = @_;
	my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Image::Image')) {
        throw EBox::Exception::InvalidType('image',
                                           'ANSTE::Image::Image');
    }

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
    my $ip = $self->{image}->ip();

    my $virtualizer = $self->{virtualizer};

    $virtualizer->createBaseImage(name => $name,
                                  ip => $ip);
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

# TODO: This two methods are very similar, try to factorize them
sub copyBaseFiles
{
    my ($self) = @_;

    my $mountPoint = $self->{mountPoint};
    my $image = $self->{image};
    my $system = $self->{system};

    # Generates the installation script on a temporary file
    my $gen = new ANSTE::ScriptGen::BasePreInstall($image);
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

sub copyHostFiles 
{
    my ($self) = @_;

    my $mountPoint = $self->{mountPoint};
    my $image = $self->{image};
    my $system = $self->{system};

    # Generates the installation script on a temporary file
    my $gen = new ANSTE::ScriptGen::HostPreInstall($image);
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

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->{image}->ip();
    $client->connect("http://$ip:$port");

    my $name = $image->name();

    $self->_createVirtualMachine($name);

    # Execute pre-install scripts
    print "Executing pre scripts...\n";
    $self->_executeScripts($client, $image->preScripts());

    my $setupScript = '/tmp/install.sh';
    my $gen = new ANSTE::ScriptGen::BaseImageSetup($image);

    my $FILE;
    open($FILE, '>', $setupScript) 
        or die "Can't create $setupScript: $!";

    $gen->writeScript($FILE);

    close($FILE) 
        or die "Can't close file $setupScript: $!";

    $self->_executeSetup($client, $setupScript);

    unlink($setupScript)
        or die "Can't remove $setupScript: $!";

    # Execute post-install scripts
    print "Executing post scripts...\n";
    $self->_executeScripts($client, $image->postScripts());

    return 1;
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

sub resize # (size)
{
    my ($self, $size) = @_;

    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

    my $system = $self->{system};
    my $virtualizer = $self->{virtualizer}; 
    my $image = $self->{image}->name();

    # Read images path from the config
    my $config = ANSTE::Config->instance();
    my $imagePath = $config->imagePath();

    print "Resizing the image to $size\n";
    $system->resizeImage($virtualizer->imageFile($imagePath, $image), $size);
}

sub _createVirtualMachine # (name)
{
    my ($self, $name) = @_;

    my $virtualizer = $self->{virtualizer};
    my $system = $self->{system};

    my $addr = $self->{image}->ip();

    my $iface = ANSTE::Config->instance()->natIface();

    $system->enableNAT($iface, $addr);

    $virtualizer->createVM($name);

    print "Waiting for the system start...\n";
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    $waiter->waitForReady($name);
    print "System is up\n";
}

sub _executeScripts # (client, list)
{
    my ($self, $client, $list) = @_;

    my $image = $self->{image};

    my $path = ANSTE::Config->instance()->scriptPath();

    foreach my $script (@{$list}) {
        $self->_executeSetup($client, "$path/$script");
    }
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

    return ($ret);
}

1;

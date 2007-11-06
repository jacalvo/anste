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

# Class: Commands
#
#   Set of commands for manipulating a image. 
#

# Constructor: new
#
#   Constructor for Commands class.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   A recently created <ANSTE::Image::Commands> object.
#
sub new # (image) returns new Commands object
{
	my ($class, $image) = @_;
	my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exceptions::InvalidType('image',
                                             'ANSTE::Scenario::BaseImage');
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

# Method: ip
#
#   Returns the IP address of the image.
#   Either from the image data or from the configuration.
#
# Returns:
#
#   string - contains the IP address of the image
#
sub ip
{
    my ($self) = @_;

    my $image = $self->{image};

    my $ip = $image->isa('ANSTE::Image::Image') ? 
             $image->ip() : 
             ANSTE::Config->instance()->firstAddress();
    
    return $ip;
}

# Method: create
#
#   Creates the image using the virtualizer interface.
#
sub create
{
	my ($self) = @_;

    my $image = $self->{image};
    my $name = $image->name();
    my $ip = $self->ip();
    my $memory = $image->memory();
    my $swap = $image->swap();

    my $virtualizer = $self->{virtualizer};

    $virtualizer->createBaseImage(name => $name,
                                  ip => $ip,
                                  memory => $memory,
                                  swap => $swap);
}

# Method: mount
#
#   Mounts the image to a temporary mount point.
#
sub mount
{
	my ($self) = @_;

    my $name = $self->{image}->name();

    $self->{mountPoint} = tempdir(CLEANUP => 1) 
        or die "Can't create temp directory: $!";

    my $mountPoint = $self->{mountPoint};

    # Read images path from the config
    my $config = ANSTE::Config->instance();
    my $imagePath = $config->imagePath();

    # Get the image file from the specific virtualizer
    my $image = $self->{virtualizer}->imageFile($imagePath, $name);

    my $system = $self->{system};

    $system->mountImage($image, $mountPoint);
}

# Method: copyBaseFiles
#
#   Generates and executes the pre-install script that copies
#   the necessary files on the base image.
#
# Returns:
#
#   integer - return value of the pre-install script
#
sub copyBaseFiles
{
    my ($self) = @_;

    my $image = $self->{image};

    my $gen = new ANSTE::ScriptGen::BasePreInstall($image);
    return $self->_copyFiles($gen)
}

# Method: copyHostFiles
#
#   Generates and executes the pre-install script that copies
#   the necessary files on a host image.
#
# Returns:
#
#   integer - return value of the pre-install script
#
sub copyHostFiles 
{
    my ($self) = @_;

    my $image = $self->{image};

    my $gen = new ANSTE::ScriptGen::HostPreInstall($image);
    return $self->_copyFiles($gen)
}

# Method: installBasePackages
#
#   Install the image base packages using the system interface.
#
# Returns:
#
#   integer - exit code of the installation process
#
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

# Method: prepareSystem
#
#   Prepares a base image executing the proper pre-setup, setup
#   and post-setup scripts.
#   The setup script is generated before its execution.
#
# Returns:
#
#   boolean - true if sucesss, false otherwise
#
# Exceptions:
#
#   TODO: change dies to throw exception
#
sub prepareSystem 
{
    my ($self) = @_;

    my $image = $self->{image};

    
    my $client = new ANSTE::Comm::MasterClient;

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->ip();
    $client->connect("http://$ip:$port");

    $self->createVirtualMachine();

    # Execute pre-install scripts
    print "Executing pre scripts...\n" if $config->verbose();
    $self->executeScripts($image->preScripts());

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
    print "Executing post scripts...\n" if $config->verbose();
    $self->executeScripts($image->postScripts());

    return 1;
}


# Method: umount
#
#   Umounts the image.
#
# Returns:
#
#   boolean - true if sucesss, false otherwise
#
# Exceptions:
#
#   TODO: change dies to throw exception
#
sub umount
{
    my ($self) = @_;
    
    my $mountPoint = $self->{mountPoint};
    my $system = $self->{system};

    my $ret = $system->unmount($mountPoint);
    
    rmdir($mountPoint) or die "Can't remove mount directory: $!";

    return($ret);
}

# Method: delete
#
#   Deletes this image from disk.
#
# Returns:
#
#   boolean - true if sucesss, false otherwise
#
sub deleteImage
{
    my ($self) = @_;

    my $virtualizer = $self->{virtualizer};

    my $image = $self->{image}->name();

    $virtualizer->deleteImage($image);
}

# Method: deleteMountPoint
#
#   Deletes the temporary mount point.
#
# Returns:
#
#   boolean - true if sucesss, false otherwise
#
sub deleteMountPoint
{
    my ($self) = @_;
    
    my $mountPoint = $self->{mountPoint};
    
    rmdir($mountPoint);
}

# Method: shutdown
#
#   Shuts down a running image using the virtualizer interface.
#
sub shutdown
{
    my ($self) = @_;

    my $image = $self->{image}->name();
    my $virtualizer = $self->{virtualizer}; 
    my $system = $self->{system};

    print "[$image] Shutting down...\n";
    $virtualizer->shutdownImage($image);
    print "[$image] Shutdown done.\n";

    # Delete the NAT rule for this image
    $self->_disableNAT();
}

# Method: destroy
#
#   Destroys immediately a running image using the virtualizer interface.
#
sub destroy
{
    my ($self) = @_;

    my $image = $self->{image}->name();
    my $virtualizer = $self->{virtualizer}; 
    my $system = $self->{system};

    $virtualizer->destroyImage($image);
    print "[$image] Terminated.\n";

    # Delete the NAT rule for this image
    $self->_disableNAT();
}

# Method: resize
#
#   Changes the size of the image.
#
# Parameters:
#
#   size - String with the new size of the image.
#
# Returns:
#
#   boolean - true if sucesss, false otherwise
#
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

    print "Resizing the image to $size\n" if $config->verbose();
    $system->resizeImage($virtualizer->imageFile($imagePath, $image), $size);
}

# Method: exists
#
#   Checks if this image exists physically in the disk.
#
# Returns:
#
#   boolean - true if the image exists, false if not
#
sub exists
{
    my ($self) = @_;

    my $image = $self->{image}->name();
    my $virtualizer = $self->{virtualizer};
    my $path = ANSTE::Config->instance()->imagePath();

    return -r $virtualizer->imageFile($path, $image);
}

# Method: createVirtualMachine
#
#   Creates the image virtual machine using the virtualizer interface,
#   once the machine is created it waits for the system start.
#
sub createVirtualMachine
{
    my ($self) = @_;

    my $virtualizer = $self->{virtualizer};
    my $system = $self->{system};

    my $name = $self->{image}->name();
    my $addr = $self->ip();

    my $iface = ANSTE::Config->instance()->natIface();

    $system->enableNAT($iface, $addr);

    $virtualizer->createVM($name);

    print "[$name] Waiting for the system start...\n";
    my $waiter = ANSTE::Comm::HostWaiter->instance();
    $waiter->waitForReady($name);
    print "[$name] System is up.\n";
}

# Method: executeScripts
#
#   Executes the given list of scripts on the running image.
#
# Parameters:
#
#   list - Reference to the list of scripts to be executed.
#
sub executeScripts # (list)
{
    my ($self, $list) = @_;

    my $image = $self->{image};

    my $client = new ANSTE::Comm::MasterClient;

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->ip();
    $client->connect("http://$ip:$port");

    foreach my $script (@{$list}) {
        my $file = $config->scriptFile($script);
        $self->_executeSetup($client, $file);
    }
}

sub _disableNAT
{
    my ($self) = @_;

    my $system = $self->{system};
    my $config = ANSTE::Config->instance();
    my $interfaces = $self->{image}->network()->interfaces(); 

    my $natIface = $config->natIface();

    foreach my $if (@{$interfaces}) {
        if ($if->gateway() eq $config->gateway()) {
            $system->disableNAT($natIface, $if->address());
        }
    }
}

sub _copyFiles # (gen)
{
    my ($self, $gen) = @_;

    my $mountPoint = $self->{mountPoint};
    my $system = $self->{system};

    # Generates the installation script on a temporary file
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

sub _executeSetup # (client, script)
{
    my ($self, $client, $script) = @_;

    my $waiter = ANSTE::Comm::HostWaiter->instance();
    my $config = ANSTE::Config->instance();

    print "Executing $script...\n" if $config->verbose();
    $client->put($script) or print "Upload failed\n";
    $client->exec($script) or print "Failed\n";
    my $image = $self->{image}->name();
    my $ret = $waiter->waitForExecution($image);
    print "Execution finished. Return value = $ret.\n" if $config->verbose();

    return ($ret);
}

1;

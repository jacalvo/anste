# Copyright (C) 2007-2013 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

package ANSTE::Image::Commands;

use warnings;
use strict;

use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Comm::MasterClient;
use ANSTE::Comm::HostWaiter;
use ANSTE::ScriptGen::BasePreInstall;
use ANSTE::ScriptGen::BaseImageSetup;
use ANSTE::ScriptGen::HostPreInstall;
use ANSTE::Image::Image;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Virtualizer::Virtualizer;
use ANSTE::System::System;

use Cwd;
use TryCatch::Lite;
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

    $self->{system} = ANSTE::System::System->instance();
    $self->{virtualizer} = ANSTE::Virtualizer::Virtualizer->instance();

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
    my $method = $image->installMethod();
    my $source = $image->installSource();
    my $dist = $image->installDist();
    my $command = $image->installCommand();
    my $size = $image->size();
    my $arch = $image->arch();
    my $mirror = $image->mirror();

    my $virtualizer = $self->{virtualizer};

    unless ($virtualizer->skipImageCreation()) {
        $virtualizer->createBaseImage(name => $name,
                                  ip => $ip,
                                  memory => $memory,
                                  swap => $swap,
                                  method => $method,
                                  source => $source,
                                  dist => $dist,
                                  size => $size,
                                  arch => $arch,
                                  command => $command,
                                  mirror => $mirror);
    }
}

# Method: get
#
#   Gets the image from the image repo
#
# Returns:
#
#   boolean - true if success, false otherwise
#
sub get
{
    my ($self) = @_;

    my $image = $self->{image};
    my $name = $image->name();

    my $config = ANSTE::Config->instance();
    my $imgdir = $config->imagePath();
    my $repoUrl = $config->imageRepo();

    my $fileName = "$name.tar.gz";
    my $tmpDir = "/tmp/anste-downloads";
    system("mkdir -p $tmpDir");

    my $ret = system("wget $repoUrl/$fileName -O $tmpDir/$fileName");
    unless ($ret == 0) {
        print STDERR "Download failed\n";
        return 0;
    }

    $ret = system("tar -xvzf $tmpDir/$fileName -C $imgdir");
    unless ($ret == 0) {
        print STDERR "Import failed\n";
        return 0;
    }

    system("rm -f $tmpDir/$fileName");

    # Creates the configuration file for the new image
    my $configFile = "$imgdir/$name/domain.xml";
    my $configVar;

    # Read the configuration file
    my $FILE;
    open($FILE, '<', $configFile) or return 0;
    local $/;
    $configVar = <$FILE>;
    close($FILE) or return 0;

    # Update the configuration
    $configVar =~ s:'.*\.(qcow2|img)':'$imgdir/$name/disk.qcow2':;
    $configVar =~ s:<name>.*</name>:<name>$name</name>:;

    # Writes the configuration file
    open($FILE, '>', $configFile) or return 0;
    print $FILE $configVar;
    close($FILE) or return 0;

    return 1;
}

# Method: importImage
#
#   Imports the image using the virtualizer interface.
#
# Returns:
#
#   boolean - true if success, false otherwise
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub importImage
{
    my ($self, $hostname) = @_;

    defined $hostname or
        throw ANSTE::Exceptions::MissingArgument('hostname');

    my $virtualizer = $self->{virtualizer};
    my $name = $self->{image}->name();

    unless ($virtualizer->existsVM($name)) {
        $virtualizer->defineVM($self->{image});
    }

    unless ($virtualizer->existsSnapshot($name, $hostname)) {
        $virtualizer->createSnapshot($name, $hostname, 'Base snapshot');
    }
}

# Method: restoreBaseSnapshot
#
#   Restores the base snapshot of a host with a raw base image
#
# Returns:
#
#   boolean - true if success, false otherwise
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub restoreBaseSnapshot
{
    my ($self, $hostname) = @_;

    defined $hostname or
        throw ANSTE::Exceptions::MissingArgument('hostname');

    my $virtualizer = $self->{virtualizer};
    my $name = $self->{image}->name();
    $virtualizer->revertSnapshot($name, $hostname);
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
    } elsif ($pid == 0) { # child
        chroot($mountPoint) or die "Can't chroot: $!";
        chdir('/');
        $ENV{HOSTNAME} = $self->{image}->name();

        my $system = $self->{system};

        my $ret = -1;

        try {
            $ret = $system->installBasePackages();
        } catch ($e) {
            print "ERROR: $e\n";
        }
        exit($ret);
    } else { # parent
        waitpid($pid, 0);
        return($?);
        # TODO: Abort process if exit code != 0 ??
    }
}

# Method: configureAptProxy
#
#  Configure the apt proxy
#
# Returns:
#
#   integer - return value of the configure-apt script
#
sub configureAptProxy
{
    my ($self, $proxy) = @_;

    defined $proxy or
        throw ANSTE::Exceptions::MissingArgument('proxy');

    my $system = $self->{system};

    my $ret = $system->configureAptProxy($proxy);
    return $ret;
}

# Method: prepareSystem
#
#   Prepares a base image executing the proper pre-setup, setup
#   and post-setup scripts.
#   The setup script is generated before its execution.
#
# Returns:
#
#   boolean - true if success, false otherwise
#
# Exceptions:
#
#   TODO: change dies to throw exception
#
sub prepareSystem
{
    my ($self) = @_;

    my $image = $self->{image};
    my $hostname = $image->name();

    my $client = new ANSTE::Comm::MasterClient;

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->ip();
    $client->connect("http://$ip:$port");

    $self->createVirtualMachine();

    # Execute pre-install scripts
    print "[$hostname] Executing pre-setup scripts...\n" if $config->verbose();
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

    my $list = $image->{files}->list(); # retrieve files list
    print "[$hostname] Transferring files...";
    $self->transferFiles($list);
    print "... done\n";

    # Execute post-install scripts
    print "[$hostname] Executing post-setup scripts...\n" if $config->verbose();
    $self->executeScripts($image->postScripts());

    return 1;
}


# Method: umount
#
#   Umounts the image.
#
# Returns:
#
#   boolean - true if success, false otherwise
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
#   boolean - true if success, false otherwise
#
sub deleteImage
{
    my ($self) = @_;

    my $virtualizer = $self->{virtualizer};

    my $image = $self->{image}->name();

    $virtualizer->deleteImage($image);

    # Deletes also the VM in case it is permanent
    #TODO: This should be improved to work with raw images and detect when we are deleteing volatile ones
    #$virtualizer->removeVM($image);
}

# Method: deleteMountPoint
#
#   Deletes the temporary mount point.
#
# Returns:
#
#   boolean - true if success, false otherwise
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
    # (only if not is a BaseImage)
    if ($self->{image}->isa('ANSTE::Image::Image')) {
        $self->_disableNAT();
    }
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
# Parameters:
#
#   wait - Boolean telling whether the method must wait for the system to start
#          Defaults to 1 (True)
#
sub createVirtualMachine
{
    my ($self, $wait) = @_;

    my $virtualizer = $self->{virtualizer};

    unless (defined $wait) {
        $wait = not $virtualizer->skipExtra();
    }

    my $system = $self->{system};

    my $name = $self->{image}->name();
    my $addr = $self->ip();

    my $config = ANSTE::Config->instance();
    my $iface = $config->natIface();

    $system->enableNAT($iface, $addr);

    $virtualizer->createVM($self->{image});

    if ($wait) {
        print "[$name] Waiting for the system start...\n";

        # Tell the client how to talk to us (the master)
        my $client = new ANSTE::Comm::MasterClient;
        my $port = $config->anstedPort();
        my $ip = $self->ip();
        $client->connect("http://$ip:$port");

        # Generate the script
        my ($fh, $filename) = tempfile() or die "Can't create temporary file: $!";
        my $masterPort = $config->masterPort();
        my $masterIP = $config->master();
        my $MASTER = "$masterIP:$masterPort";
        print $fh "echo $MASTER > /var/local/anste.master";
        close($fh) or die "Can't close temporary file: $!";

        # Upload and exec it
        while (not $client->put($filename)) {
            sleep 1;
        }
        $client->exec($filename);

        # Wait for the execution to be done
        my $waiter = ANSTE::Comm::HostWaiter->instance();
        my $ret = $waiter->waitForExecution($name);
        if ($ret == 0 ) {
            print "[$name] System is up.\n";
        } else {
            die "[$name] Could not set the system up.\n";
        }
    }
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

    if ($config->verbose()) {
        print "Scripts to be executed: ";
        print join ',',@{$list};
        print "\n";
    }

    foreach my $script (@{$list}) {
        my $file = $config->scriptFile($script);
        $self->_executeSetup($client, $file);
    }
}

# Method: transferFiles
#
#   Transfer the given list of files on the running image.
#
#   If the file is a directory, then recursively copy the directory
#   content but without preserving the directory structure in the
#   running image.
#
# Parameters:
#
#   list - Reference to the list of files to be transferred.
#
sub transferFiles # (list)
{
    my ($self, $list) = @_;

    my $image = $self->{image};

    my $client = new ANSTE::Comm::MasterClient;

    my $config = ANSTE::Config->instance();
    my $port = $config->anstedPort();
    my $ip = $self->ip();
    $client->connect("http://$ip:$port");

    foreach my $file (@{$list}) {
        $self->_transferFile($file, $image, $config, $client);
    }
}

# Method: finalConfigurations
#
#   Performs the final configurations in the image
#
#   If openstack command line argument has been provided, removes the network
#   persistent rules in the image.
#
sub finalConfigurations
{
    my ($self) = @_;

    if (ANSTE::Status->instance()->useOpenStack()) {
        my $system = $self->{system};
        my $cmd = 'cat /dev/null > /etc/udev/rules.d/70-persistent-net.rules ' .
                  '&& cat /dev/null > /lib/udev/rules.d/75-persistent-net-generator.rules';
        $system->execute($cmd);
    }
}

sub _disableNAT
{
    my ($self) = @_;

    my $system = $self->{system};
    my $config = ANSTE::Config->instance();
    my $natIface = $config->natIface();
    my $network = $self->{image}->network();

    if ($network) {
        foreach my $if (@{$network->interfaces()}) {
            if ($if->gateway() eq $config->gateway()) {
                $system->disableNAT($natIface, $if->address());
                last;
            }
        }
    }
    else {
        $system->disableNAT($natIface, $self->ip());
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
    my $image = $self->{image}->name();
    my $log = '/tmp/anste-setup-script.log';

    print "[$image] Executing $script...\n" if $config->verbose();
    $client->put($script) or print "[$image] Upload failed.\n";
    $client->exec($script, $log, $config->env()) or print "[$image] Execution failed.\n";
    my $ret = $waiter->waitForExecution($image);
    if ($ret == 0 ) {
        print "[$image] Execution finished successfully.\n" if $config->verbose();
    } else {
        print "[$image] Execution finished with errors ($ret):\n\n";
        $client->get($log);
        system ("cat $log");
        print "\n\n";
        throw ANSTE::Exceptions::Error("Error executing script $script, returned exit value of $ret");
    }

    return ($ret);
}

# Real transfer of files to the client
# If the file is a directory, then recursively transfer its content
sub _transferFile
{
    my ($self, $file, $image, $config, $client) = @_;

    my $tarFile = undef;
    my $filePath = $config->listsFile($file);
    if (-d $filePath) {
        $tarFile = "$filePath.tar";
        system ("tar cf $tarFile $filePath");
        $filePath = $tarFile;
    }

    $client->put($filePath) or print "[$image:$filePath] Transfer failed.\n";

    unlink ($tarFile) if $tarFile;
}

1;

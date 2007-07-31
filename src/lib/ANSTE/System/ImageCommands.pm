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

use ANSTE::Comm::MasterClient;
use ANSTE::Comm::SharedData;
use ANSTE::System::BaseScriptGen;
use ANSTE::System::CommInstallGen;

use Cwd;
use File::Temp qw(tempfile tempdir);

use constant XEN_TOOLS_CONFIG => '/data/conf/xen-tools.conf';

use constant IMAGE_PATH => '/home/xen/domains/';

sub new # (image) returns new Commands object
{
	my ($class, $image) = @_;
	my $self = {};

    $self->{mountPoint} = undef;
    $self->{image} = $image;
	
	bless($self, $class);

	return $self;
}

# TODO: Do this with Virtualizer package
sub create
{
	my ($self) = @_;

    my $name = $self->{image}->name();

    my $confFile = getcwd() . XEN_TOOLS_CONFIG;
    my $command = "xen-create-image --hostname=$name".
                  " --ip='192.168.45.191' --config=$confFile"; 

    return _execute($command);
}

sub mount
{
	my ($self) = @_;

    my $name = $self->{image}->name();

    $self->{mountPoint} = tempdir();

    my $mountPoint = $self->{mountPoint};

    my $image = IMAGE_PATH . $name . '/disk.img';

    my $cmd = "mount -t ext3 -o loop $image $mountPoint";

    return _execute($cmd);
}

sub copyBaseFiles
{
    my ($self) = @_;

    my $mountPoint = $self->{mountPoint};
    my $image = $self->{image};

    # Generates the installation script on a temporary file
    my $gen = new ANSTE::System::CommInstallGen($image);
    my ($fh, $filename) = tempfile();
    $gen->writeScript($fh);
    close($fh);
    # Gives execution perm to the script
    chmod(700, $filename);
    
    # Executes the installation script passing the mount point
    # of the image as argument
    my $ret = _execute("$filename $mountPoint");

    unlink($filename);

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
        _execute('apt-get update') or die "apt-get update failed: $!";
        my $ret = _installPackages('libsoap-lite-perl');
        _execute('apt-get clean') or die "apt-get clean failed: $!";
        # TODO: Do this more in a more generic way with the XMLs!!!
        _execute('update-rc.d ansted defaults 99') 
            or die "update-rc.d fail: $!";
        exit($ret);
    }
    else { # parent
        waitpid($pid, 0);
        return $?;
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

    $self->_createVirtualMachine($client, $name);

    my $script = 'install.sh';
    my $gen = new ANSTE::System::BaseScriptGen($image);
    my $FILE;
    open($FILE, '>', $script);
    $gen->writeScript($FILE);
    close($FILE);

    $self->_executeSetup($client, 'install.sh');

    # TODO: Do all this file things in /tmp
    unlink $script;
}


sub umount
{
    my ($self) = @_;
    my $mountPoint = $self->{mountPoint};
    my $ret = _execute("umount $mountPoint");
    _execute("rmdir $mountPoint");
    return($ret);
}

sub shutdown
{
    my ($self) = @_;

    my $image = $self->{image}->name();

    # TODO: Maybe this could be done more softly sending poweroff :)
    system("xm destroy $image");
}


sub _installPackages # (list)
{
    my ($list) = @_;

    $ENV{DEBIAN_FRONTEND} = 'noninteractive';

    my $forceNew = '-o DPkg::Options::=--force-confnew';
    my $forceDef = '-o DPkg::Options::=--force-confdef';
    my $options = "-y $forceNew $forceDef";

    my $command = "apt-get install $options $list";
    return _execute($command);
}

sub _createVirtualMachine # (client, name)
{
    my ($self, $client, $name) = @_;

    _execute("xm create $name.cfg");

    print "Waiting for the system start...\n";
    my $data = ANSTE::Comm::SharedData->instance();
    $data->waitForReady($name);
    print "System is up\n";
}

sub _executeSetup # (client, script)
{
    my ($self, $client, $script) = @_;

    my $data = ANSTE::Comm::SharedData->instance();

    print "Trying to put $script\n";
    my $ret = $client->put($script);
    print "Server returned $ret\n";
    print "Trying to exec $script\n";
    $ret = $client->exec('install.sh');
    print "Server returned $ret\n";
    $ret = $data->waitForExecution('baseimage');
    print "Execution finished with return value = $ret\n";
}

sub _execute # (command)
{
    my ($command) = @_;
    return system($command) == 0;
}

1;

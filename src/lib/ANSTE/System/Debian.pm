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

package ANSTE::System::Debian;

use base 'ANSTE::System::System';

use strict;
use warnings;

# Method: mountImage 
#
#   Overriden method that executes mount with
#   the given image and mount point as arguments.
#
# Parameters: 
#   
#   image      - path of the image to mount 
#   mountPoint - directory where the image will be mounted
#
# Returns:
#   
#   boolean    - indicates if the process has been successful
#               
sub mountImage # (image, mountPoint)
{
    my ($self, $image, $mountPoint) = @_;

    my $cmd = "mount -t ext3 -o loop $image $mountPoint";

    $self->execute($cmd);
}

# Method: unmount 
#
#   Overriden method that executes umount with
#   the mount point specified.
#
# Parameters: 
#   
#   mountPoint - path of the mounted directory 
#
# Returns:
#   
#   boolean    - indicates if the process has been successful
#               
sub unmount # (mountPoint)
{
    my ($self, $mountPoint) = @_;

    $self->execute("umount $mountPoint");
}

# Method: installBasePackages 
#
#   Overriden methods that install the required packages
#   to run anste on the slave host by using apt.
#   Also creates the init.d symlinks for ansted.
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
sub installBasePackages
{
    my ($self) = @_;

    $self->execute('apt-get update') 
        or die "apt-get update failed: $!";

    my $ret = $self->_installPackages('libsoap-lite-perl');

    $self->execute('apt-get clean') 
        or die "apt-get clean failed: $!";

    $self->execute('update-rc.d ansted defaults 99') 
        or die "update-rc.d failed: $!";

    return($ret);
}

# Method: resizeImage 
#
#   Overriden method that resizes a image file
#   using resize2fs, checking it first with e2fsck.
#
# Parameters:
#   
#   image   - image file
#   size    - new size
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
sub resizeImage # (image, size)
{
    my ($self, $image, $size) = @_;

    my ($ret, $tries) = (1, 0); 

    # Sometimes it needs two (or more?) passes to work.
    do {
        $self->execute("e2fsck -f $image");

        $ret = $self->execute("resize2fs $image $size");

        $tries++;
    } while ($ret == 0 and $tries < 2);

    return $ret ;
}

# Method: updatePackagesCommand
#
#   Overriden method that returns the Debian command
#   to update packages database.
#
# Returns:
#
#   string - command string
#
sub updatePackagesCommand # returns string
{
    my ($self) = @_;

    return 'apt-get update';
}

# Method: updatePackagesCommand
#
#   Overriden method that returns the Debian command
#   to clean packages cache.
#
# Returns:
#
#   string - command string
#
sub cleanPackagesCommand # returns string
{
    my ($self) = @_;

    return 'apt-get clean';
}

# Method: installPackagesCommand 
#
#   Overriden method that returns the Debian command
#   to install the given list of packages 
#
# Parameters:
#   
#   packages - list of packages
#
# Returns:
#
#   string - command string
#
sub installPackagesCommand # (packages) returns string
{
    my ($self, @packages) = @_;

    my $packages = join(' ', @packages);

    return 'apt-get install -y $APT_OPTIONS ' . $packages;
}

# Method: installVars
#
#   Overriden method that returns the environment variables needed 
#   for the packages installation process.
#
# Returns:
#
#   string - contains the environment variables set commands
#
sub installVars # return strings
{
    my ($self) = @_;

    my $vars = '';

    $vars .= "export DEBIAN_FRONTEND=noninteractive\n\n";
    my $forceConfnew = 'Dpkg::Options::=--force-confnew';
    my $forceConfdef = 'Dpkg::Options::=--force-confdef';
    $vars .= "APT_OPTIONS='-o $forceConfnew -o $forceConfdef';\n\n"; 

    return $vars;
}


# Method: networkConfig
# FIXME documentation
sub networkConfig # (network) returns string
{
    my ($self, $network) = @_;

    my $config = '';
	$config .= "cat << EOF > /etc/network/interfaces\n";
    $config .= "auto lo\n";
	$config .= "iface lo inet loopback\n";
    foreach my $iface (@{$network->interfaces()}) {
    	$config .= "\n";
        $config .= $self->_interfaceConfig($iface);
    }
	$config .= "EOF\n";
	$config .= "\n";
	$config .= "# Bring up all the interfaces\n";
	$config .= "ifup -a\n";

    return $config;
}

# Method: hostnameConfig
# FIXME documentation
sub hostnameConfig # (hostname) returns string
{
    my ($self, $hostname) = @_;

    return "echo $hostname > " . '$MOUNT/etc/hostname';
}

# Method: hostsConfig
# FIXME documentation
sub hostsConfig # (hostname) returns string
{
    my ($self, $hostname) = @_;

    my $config = '';

    $config .= 'cat << EOF > $MOUNT/etc/hosts'."\n";
    $config .= "127.0.0.1 localhost.localdomain localhost\n";
    $config .= "127.0.1.1 $hostname.localdomain $hostname\n";
    $config .= "\n";
    $config .= "# The following lines are desirable for IPv6 capable hosts\n";
    $config .= "::1     ip6-localhost ip6-loopback\n";
    $config .= "fe00::0 ip6-localnet\n";
    $config .= "ff00::0 ip6-mcastprefix\n";
    $config .= "ff02::1 ip6-allnodes\n";
    $config .= "ff02::2 ip6-allrouters\n";
    $config .= "ff02::3 ip6-allhosts\n";
    $config .= "EOF";

    return $config;
}

# Method: storeMasterAddress
# FIXME documentation
sub storeMasterAddress # (address) returns string
{
    my ($self, $address) = @_;

    return "echo $address > " . '$MOUNT/var/local/anste.master'; 
}

# Method: copyToMountCommand
# FIXME documentation
sub copyToMountCommand # (orig, dest) returns string
{
    my ($self, $orig, $dest) = @_;

    return "cp $orig " . '$MOUNT' . $dest;
}

# Method: createMountDirCommand
# FIXME documentation
sub createMountDirCommand # (path) returns string
{
    my ($self, $path) = @_;

    return 'mkdir -p $MOUNT' . $path;
}

sub _interfaceConfig # (iface)
{
    my ($self, $iface) = @_;

    my $config = '';

    my $name = $iface->name();
	$config .= "auto $name\n";
	if ($iface->type() == ANSTE::Scenario::NetworkInterface->IFACE_TYPE_DHCP) {
        $config .= "iface $name inet dhcp\n";
	} else {
		my $address = $iface->address();
		my $netmask = $iface->netmask();
		my $gateway = $iface->gateway();
		$config .= "iface $name inet static\n";
		$config .= "address $address\n";
		$config .= "netmask $netmask\n";
		$config .= "gateway $gateway\n";
	}
}

sub _installPackages # (list)
{
    my ($self, $list) = @_;

    $ENV{DEBIAN_FRONTEND} = 'noninteractive';

    my $forceNew = '-o DPkg::Options::=--force-confnew';
    my $forceDef = '-o DPkg::Options::=--force-confdef';
    my $options = "-y $forceNew $forceDef";

    my $command = "apt-get install $options $list";

    $self->execute($command);
}

1;

# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidFile;
use File::Basename;

use threads;
use threads::shared;

my %nbdDevs : shared;

# Class: System
#
#    Implementation of the System class that interacts
#    with the Debian GNU/Linux system.
#

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

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');
    defined $mountPoint or
        throw ANSTE::Exceptions::MissingArgument('mountPoint');

    my $num = scalar keys %nbdDevs;
    my $device = "/dev/nbd$num";

    $self->execute('modprobe nbd max_part=63');

    $self->execute("qemu-nbd -c $device $image");

    $nbdDevs{$mountPoint} = $device;

    $self->execute("mount ${device}p1 $mountPoint");
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

    defined $mountPoint or
        throw ANSTE::Exceptions::MissingArgument('mountPoint');

    $self->execute("umount $mountPoint");

    my $loopDev = $nbdDevs{$mountPoint};
    $self->execute("qemu-nbd -d $loopDev");
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

    my @PACKAGES = ('libsoap-lite-perl',
                    'libtrycatch-lite-perl',
                    'libdevel-stacktrace-perl',
                    'iptables',
                    'hping3',
                    'netcat',
                    'tcpdump');

    $self->execute('echo "deb http://ppa.launchpad.net/zentyal/anste/ubuntu precise main" > /etc/apt/sources.list.d/anste.list')
        or die "write anste repository to sources.list failed: $!";

    $self->execute('apt-get update')
        or die "apt-get update failed: $!";

    my $ret = $self->_installPackages(@PACKAGES);

    $self->execute('apt-get clean')
        or die "apt-get clean failed: $!";

    $self->execute('update-rc.d ansted defaults 99')
        or die "update-rc.d failed: $!";

    return($ret);
}

# Method: configureAptProxy
#
#  Configure the apt Proxy
#
# Returns:
#
#   integer - return value of the script
#
sub configureAptProxy
{
    my ($self, $proxy) = @_;

    $self->execute("echo \"Acquire::http::Proxy \\\"$proxy\\\";\" > /etc/apt/apt.conf.d/01proxy")
        or die "Configure apt proxy failed: $!";

    return 1;
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

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');
    defined $size or
        throw ANSTE::Exceptions::MissingArgument('size');

    my ($ret, $tries) = (1, 0);

#FIXME: This doesn't work with kvm, only with xen
# temporary unimplemented.
    return 1;

#    # Sometimes it needs two (or more?) passes to work.
#    do {
#        $self->execute("e2fsck -f $image");
#
#        $ret = $self->execute("resize2fs $image $size");
#
#        $tries++;
#    } while ($ret == 0 and $tries < 2);
#
#    return $ret ;
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

# Method: updateNetworkCommand
#
#   Overriden method that returns the system-specific
#   command to update the network configuration.
#
# Returns:
#
#   string - command string
#
sub updateNetworkCommand # returns string
{
    my ($self) = @_;

    system ("lsb_release -c | grep precise");
    if ($? == 0) {
        return '/etc/init.d/networking restart';
    } else {
        return '/sbin/restart networking';
    }
}

# Method: cleanPackagesCommand
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

    return 'DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y --force-yes $APT_OPTIONS ' . $packages;
}

# Method: installPackagesCommandType
#
#   Overriden method that returns the Debian command
#   to install the given list of packages for
#   a specific type of host
#
# Parameters:
#
#   type - host type
#
# Returns:
#
#   string - command string
#
sub installPackagesCommandType # (type) returns string
{
    my ($self, $type) = @_;

    my @packages;

    if ($type eq 'dhcp-router') {
        push (@packages, 'dhcp3-server');
    } elsif ($type eq 'pppoe-router') {
        push (@packages, 'pppoe');
    }

    return $self->installPackagesCommand(@packages);
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
#
#   Overriden method that returns the network configuration
#   for a given network config passed as an argument.
#
# Parameters:
#
#   network - <ANSTE::Scenario::Network> object.
#
# Returns:
#
#   string - contains the network configuration
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub networkConfig # (network) returns string
{
    my ($self, $network) = @_;

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

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

    foreach my $route (@{$network->routes()}) {
        $config .= $self->_routeCommand($route);
        $config .= "\n";
    }

    return $config;
}

# Method: hostsConfig
#
#   Overriden method that returns the hosts configuration
#   passed as an argument.
#
# Parameters:
#
#   hosts - Hash containining hostnames and ip addresses.
#
# Returns:
#
#   string - contains the hosts configuration
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub hostsConfig # (%hosts) returns string
{
    my ($self, %hosts) = @_;

    if (not %hosts) {
        throw ANSTE::Exceptions::MissingArgument('hosts');
    }

    my $config = "echo '\n# ANSTE hosts' >> /etc/hosts\n";
    while (my ($host, $address) = each(%hosts)) {
        $config .= "echo '$address $host.localdomain $host' >> /etc/hosts\n";
    }

    return $config;
}

# Method: initialNetworkConfig
#
#
#
# Parameters:
#
#   iface    - communications interface
#   network  - <ANSTE::Scenario::Network> object
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub initialNetworkConfig # (iface, network) returns string
{
    my ($self, $iface, $network) = @_;

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');

    defined $network or
        throw ANSTE::Exceptions::MissingArgument('network');

    if (not $iface->isa('ANSTE::Scenario::NetworkInterface')) {
        throw ANSTE::Exceptions::InvalidType('iface',
            'ANSTE::Scenario::NetworkInterface');
    }

    if (not $network->isa('ANSTE::Scenario::Network')) {
        throw ANSTE::Exceptions::InvalidType('network',
            'ANSTE::Scenario::Network');
    }

    my $config = '';

    # HACK: To avoid problems with udev and mac addresses
    $config .= "rm -f \$MOUNT/lib/udev/rules.d/75-persistent-net-generator.rules\n";
    $config .= "cat << EOF > \$MOUNT/etc/udev/rules.d/70-persistent-net.rules\n";
    foreach my $if (@{$network->interfaces()}) {
        my $mac = lc $if->hwAddress();
        my $name = $if->name();
        $config .= 'SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ';
        $config .= "ATTR{address}==\"$mac\", ATTR{dev_id}==\"0x0\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"$name\"\n";
    }
    $config .= "EOF\n\n";

    my $nameserver = ANSTE::Config->instance()->nameserverHost();
    $config .= "echo 'nameserver $nameserver' > /etc/resolv.conf\n";

    $config .= "cat << EOF > \$MOUNT/etc/network/interfaces\n";
    $config .= "auto lo\n";
    $config .= "iface lo inet loopback\n\n";
    $config .= $self->_interfaceConfig($iface);
    $config .= "EOF";

    return $config;
}

# Method: hostnameConfig
#
#   Overriden method that returns the hostname configuration
#   for a the given hostname passed as an argument.
#
# Parameters:
#
#   hostname - String with the hostname for write the config.
#
# Returns:
#
#   string - contains the hostname configuration
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub hostnameConfig # (hostname) returns string
{
    my ($self, $hostname) = @_;

    defined $hostname or
        throw ANSTE::Exceptions::MissingArgument('hostname');

    return "echo $hostname > " . '$MOUNT/etc/hostname';
}

# Method: hostConfig
#
#   Overriden method that returns the host configuration
#   for a the given hostname passed as an argument.
#
# Parameters:
#
#   hostname - String with the hostname for write the config.
#
# Returns:
#
#   string - contains the network hosts configuration
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub hostConfig # (hostname) returns string
{
    my ($self, $hostname) = @_;

    defined $hostname or
        throw ANSTE::Exceptions::MissingArgument('hostname');

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
#
#   Overriden method that returns the command for store the master
#   address in the slave host.
#
# Parameters:
#
#   address - String with the IP address to store.
#
# Returns:
#
#   string - contains the command to store the address
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub storeMasterAddress # (address) returns string
{
    my ($self, $address) = @_;

    defined $address or
        throw ANSTE::Exceptions::MissingArgument('address');

    return "echo $address > " . '$MOUNT/var/local/anste.master';
}

# Method: copyToMountCommand
#
#   Overriden method that returns the command used to copy a given
#   file to a given destiny on a mounted image.
#
# Parameters:
#
#   orig - String with the origin file to copy.
#   dest - String with the destiny of the copy on the mounted image.
#
# Returns:
#
#   string - contains the command to copy to a mounted image
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub copyToMountCommand # (orig, dest) returns string
{
    my ($self, $orig, $dest) = @_;

    defined $orig or
        throw ANSTE::Exceptions::MissingArgument('orig');
    defined $dest or
        throw ANSTE::Exceptions::MissingArgument('dest');

    return "cp $orig " . '$MOUNT' . $dest;
}

# Method: createMountDirCommand
#
#   Overriden method that returns the command used to create a
#   directory on a mounted image.
#
# Parameters:
#
#   path - String with the full path of directories to be created.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub createMountDirCommand # (path) returns string
{
    my ($self, $path) = @_;

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');

    return 'mkdir -p $MOUNT' . $path;
}

# Method: firewallDefaultRules
#
#   Overriden method that returns the commands needed to set
#   the default firewall (no filtering).
#
# Returns:
#
#   string - contains the commands
#
sub firewallDefaultRules # returns string
{
    my ($self) = @_;

    my $config = '';

    $config .= "iptables -F\n";
    $config .= "iptables -P INPUT ACCEPT\n";
    $config .= "iptables -P OUTPUT ACCEPT\n";
    $config .= "iptables -P FORWARD ACCEPT";

    return $config;
}

# Method: enableRouting
#
#   Overriden method that returns the commands that enables routing
#   on a given network interface.
#
# Parameters:
#
#   ifaces - List of strings with the interfaces to enable masquerading.
#
# Returns:
#
#   string - contains the command
#
sub enableRouting # (@iface)
{
    my ($self, @ifaces) = @_;

    my $command = "echo 1 > /proc/sys/net/ipv4/ip_forward\n";
    $command .= "unset MODPROBE_OPTIONS\n";
    foreach my $iface (@ifaces) {
        $command .= "iptables -t nat -A POSTROUTING -o $iface -j MASQUERADE\n";
    }

    return $command;
}

# Method: setupTypeScript
#
#   Overriden method that returns the command that runs the script
#   to setup the specified type of host.
#
# Parameters:
#
#   type - String with the type of the host.
#
# Returns:
#
#   string - contains the command
#
sub setupTypeScript # (type)
{
    my ($self, $type) = @_;

    return "/usr/local/bin/anste-setup-$type";
}

# Method: enableNAT
#
#   Overriden method that returns the command that enables NAT
#   on a given network interface from a given source address.
#
# Parameters:
#
#   iface - String with the interface to enable masquerading.
#   sourceAddr - String with the source IP address to enable the NAT.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub enableNAT # (iface, sourceAddr)
{
    my ($self, $iface, $sourceAddr) = @_;

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');
    defined $sourceAddr or
        throw ANSTE::Exceptions::MissingArgument('sourceAddr');

    # TODO: Maybe this will need to be turned off after ANSTE deployment
    # or better restored to its initial value
    $self->execute('echo 1 > /proc/sys/net/ipv4/ip_forward');

    $self->execute("iptables -t nat -A POSTROUTING " .
#                   "-o $iface -s $sourceAddr -j MASQUERADE");
                   "-o $iface -j MASQUERADE");
}

# Method: disableNAT
#
#   Overriden method that returns the command that disables NAT on
#   a given network interface from a given source address.
#
# Parameters:
#
#   iface - String with the interface to disable masquerading.
#   sourceAddr - String with the source IP address to disable the NAT.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub disableNAT # (iface, sourceAddr)
{
    my ($self, $iface, $sourceAddr) = @_;

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');
    defined $sourceAddr or
        throw ANSTE::Exceptions::MissingArgument('sourceAddr');

    $self->execute("iptables -t nat -D POSTROUTING " .
                   "-o $iface -s $sourceAddr -j MASQUERADE");
}

# Method: executeSelenium
#
#   Overriden method that executes Selenium.
#
# Parameters:
#
#   jar - String with the path of the selenium jar.
#   browser - String with the web browser to be used.
#   url - String with the url of the web we want to test.
#   testFile - String with the filename of the Selenium test suite.
#   resultFile - String with the filename of the Selenium results to be saved.
#
# Returns:
#
#   boolean - true if execution was ok, false otherwise
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub executeSelenium # (%params)
{
    my ($self, %params) = @_;

    exists $params{jar} or
        throw ANSTE::Exceptions::MissingArgument('jar');
    exists $params{browser} or
        throw ANSTE::Exceptions::MissingArgument('browser');
    exists $params{url} or
        throw ANSTE::Exceptions::MissingArgument('url');
    exists $params{testFile} or
        throw ANSTE::Exceptions::MissingArgument('testFile');
    exists $params{resultFile} or
        throw ANSTE::Exceptions::MissingArgument('resultFile');

    my $jar = $params{jar};
    my $browser = $params{browser};
    my $url = $params{url};
    my $testFile = $params{testFile};
    my $resultFile = $params{resultFile};

    my $config = ANSTE::Config->instance();

    my $firefoxProfile = $config->seleniumFirefoxProfile();
    my $profileOption = '';
    if ($firefoxProfile) {
        $profileOption = "-firefoxProfileTemplate \"$firefoxProfile\"";
    }

    my $date = `date +%y%m%d%H%M%S`;
    chomp($date);
    my $LOG =  "/tmp/anste-selenium-$date.log";

    my $singleWindow = $config->seleniumSingleWindow();
    my $windowLayout = '-multiWindow';
    if ($singleWindow) {
        $windowLayout = "-singleWindow";
    }

    my $userExtensions = $config->seleniumUserExtensions();

    my $cmd = "java -jar $jar -avoidProxy -htmlSuite \"$browser\"  "
            . "\"$url\" \"$testFile\" \"$resultFile\" "
            . "-userExtensions $userExtensions "
            . "$windowLayout $profileOption > $LOG 2>&1";


    my $ld_path = '';
    my @browserSplit = split(/ /, $browser);
    if ($browserSplit[1]) {
        my $browserPath = dirname($browserSplit[1]);
        $ld_path = "LD_LIBRARY_PATH=$browserPath ";
    }

    print STDERR "Selenium command: $cmd\n" if ($config->verbose());
    return $self->execute($ld_path . $cmd);
}

# Method: startVideoRecording
#
#   Overriden method that returns the command that should
#   be used to start video recording on the specific system.
#   The video is stored with the given filename.
#
# Parameters:
#
#   filename - String with the filename of the video to store.
#
# Returns:
#
#   string - contains the command
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidFile> - throw if file is not writable
#
sub startVideoRecording # (filename)
{
    my ($self, $filename) = @_;

    if (not ANSTE::Validate::fileWritable($filename)) {
        throw ANSTE::Exceptions::InvalidFile('filename', $filename);
    }

    my $pid = fork();
    defined $pid or die "Can't fork: $!";

    if ($pid == 0) {
        # TODO: Personalize
        my $command = "recordmydesktop --overwrite --no-sound -o $filename";
        # Exec without output
        open(STDOUT, '>', '/dev/null');
        open(STDERR, '>&STDOUT');
        exec(split(' ', $command));
    }
    else {
        $self->{videoPid} = $pid;
    }
}

# Method: stopVideoRecording
#
#   Overriden method that returns the command that should
#   be used to stop video recording on the specific system.
#
# Returns:
#
#   string - contains the command
#
sub stopVideoRecording
{
    my ($self) = @_;

    my $pid = $self->{videoPid};

    kill 15, $pid;

    waitpid($pid, 0);
}

sub _interfaceConfig # (iface)
{
    my ($self, $iface) = @_;

    my $config = '';

    my $type = $iface->type();
    my $name = $iface->name();

    $config .= "auto $name\n";
    if ($type == ANSTE::Scenario::NetworkInterface->IFACE_TYPE_DHCP) {
        $config .= "iface $name inet dhcp\n";
    } elsif ($type == ANSTE::Scenario::NetworkInterface->IFACE_TYPE_STATIC) {
        my $address = $iface->address();
        my $netmask = $iface->netmask();
        my $gateway = $iface->gateway();
        $config .= "iface $name inet static\n";
        $config .= "address $address\n";
        $config .= "netmask $netmask\n";
        if ($gateway) {
            $config .= "gateway $gateway\n";
        }
    }

    return $config;
}

sub _routeCommand # (route)
{
    my ($self, $route) = @_;

    my $dest = $route->destination();
    my $gateway = $route->gateway();
    my $netmask = $route->netmask();
    my $iface = $route->iface();

    my $command = '';

    if ($dest eq 'default') {
        $command = "route add default gw $gateway";
    }
    else {
        $command =
            "route add -net $dest netmask $netmask gw $gateway dev $iface";
    }

    return $command;
}

sub _installPackages # (list)
{
    my ($self, @list) = @_;

    $ENV{DEBIAN_FRONTEND} = 'noninteractive';

    my $forceNew = '-o DPkg::Options::=--force-confnew';
    my $forceDef = '-o DPkg::Options::=--force-confdef';
    my $options = "-y --force-yes $forceNew $forceDef";

    my $list = join(' ', @list);
    my $command = "apt-get install $options $list";

    $self->execute($command);
}

1;

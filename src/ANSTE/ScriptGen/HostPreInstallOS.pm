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

package ANSTE::ScriptGen::HostPreInstallOS;

use strict;
use warnings;

use ANSTE::Image::Image;
use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidFile;
use ANSTE::System::System;

# Class: HostPreInstall
#
#   Writes the setup script for a host image that is executed on
#   a mounted image, before creating the virtual machine.
#   The generated script updates the hostname and network configuration
#   on the image.
#

# Constructor: new
#
#   Constructor for HostPreInstall class.
#
# Parameters:
#
#   host - <ANSTE::Scenario::Host> object.
#
# Returns:
#
#   A recently created <ANSTE::ScriptGen::HostPreInstall> object.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType> - throw if argument has wrong type
#
sub new
{
    my ($class, $image) = @_;
    my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Image::Image')) {
        throw ANSTE::Exceptions::InvalidType('image',
                                             'ANSTE::Image::Image');
    }

    $self->{image} = $image;
    $self->{system} = ANSTE::System::System->instance();

    bless($self, $class);

    return $self;
}

# Method: writeScript
#
#   Writes the script to the given file.
#
# Parameters:
#
#   file - String with the name of the file to be written.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidFile> - throw if argument is not a writable file
#
sub writeScript
{
    my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    if (not -w $file) {
        throw ANSTE::Exceptions::InvalidFile('file', $file);
    }

    my $hostname = $self->{image}->name();

    print $file "#cloud-config file\n";
    print $file "# Generated by ANSTE for host $hostname\n\n";

    print $file "# Prevent cloud-init from overwriting /etc/apt/sources.list\n";
    print $file "apt_preserve_sources_list: True\n";

    $self->_writeHostnameConfig($file);
    $self->_writeHostConfig($file);
    print $file "# Network configuration\n";
    print $file "bootcmd:\n";
    $self->_writeMasterAddress($file);
    $self->_writeInitialNetworkConfig($file);
}

sub _writeHostnameConfig
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $hostname = $self->{image}->name();

    print $file "# Write hostname config\n";
    print $file "hostname: $hostname\n\n";
}

sub _writeHostConfig
{
    my ($self, $file) = @_;

    my $system = $self->{system};
    my $host = $self->{image}->name();

    print $file "# Write host configuration\n";
    print $file "manage_etc_hosts: localhost\n\n";
}

sub _writeInitialNetworkConfig
{
    my ($self, $file) = @_;

    my $system = $self->{system};
    my $iface = $self->{image}->commInterface();
    my $network = $self->{image}->network();
    unless ($network) {
        return;
    }

    my $config = $self->initialNetworkConfig($iface, $network);

    print $file "$config\n\n";
}

sub _writeMasterAddress
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $config = ANSTE::Config->instance();
    my $port = $config->masterPort();
    my $masterIP = $config->master();
    my $MASTER = "$masterIP:$port";

    print $file " - echo $MASTER > /var/local/anste.master\n";

}


# Method: initialNetworkConfig
#
#
# Parameters:
#
#   iface    - communications interface
#   network  - <ANSTE::Scenario::Network> object
#
sub initialNetworkConfig {
    my ( $self, $iface, $network ) = @_;

    defined $iface
      or throw ANSTE::Exceptions::MissingArgument('iface');

    defined $network
      or throw ANSTE::Exceptions::MissingArgument('network');

    if ( not $iface->isa('ANSTE::Scenario::NetworkInterface') ) {
        throw ANSTE::Exceptions::InvalidType( 'iface',
            'ANSTE::Scenario::NetworkInterface' );
    }

    if ( not $network->isa('ANSTE::Scenario::Network') ) {
        throw ANSTE::Exceptions::InvalidType( 'network',
            'ANSTE::Scenario::Network' );
    }

    my $config = '';

    # HACK: To avoid problems with udev and mac addresses
    $config .= " - rm -f /lib/udev/rules.d/75-persistent-net-generator.rules\n";
    $config .= " - rm -f /etc/udev/rules.d/70-persistent-net.rules\n";

    $config .= " - echo 'auto lo' > /etc/network/interfaces\n";
    $config .= " - echo 'iface lo inet loopback' > /etc/network/interfaces\n";
    my $type = $iface->type();
    my $name = $iface->name();
    $config .= " - echo 'auto $name' > /etc/network/interfaces\n";
    if ( $type == ANSTE::Scenario::NetworkInterface->IFACE_TYPE_DHCP ) {
        $config .= " - echo 'iface $name inet dhcp' > /etc/network/interfaces\n";
    }
    elsif ( $type == ANSTE::Scenario::NetworkInterface->IFACE_TYPE_STATIC ) {
        my $address = $iface->address();
        my $netmask = $iface->netmask();
        my $gateway = $iface->gateway();
        $config .= " - ifconfig $name $address netmask $netmask\n";
        $config .= " - route add default gw $gateway\n";
        $config .= " - echo 'iface $name inet static' > /etc/network/interfaces\n";
        $config .= " - echo 'address $address' > /etc/network/interfaces\n";
        $config .= " - echo 'netmask $netmask' > /etc/network/interfaces\n";
        if ($gateway) {
            $config .= " - echo 'gateway $gateway' > /etc/network/interfaces\n";
        }
    }
    return $config;
}

1;
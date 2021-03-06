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

package ANSTE::Scenario::NetworkInterface;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::InvalidData;
use ANSTE::Exceptions::Error;
use ANSTE::Validate;

use threads;
use threads::shared;

use constant AUTOASSIGNED_MAC_ADDR_START => 'DE:AD:BE:EF:00:';

# Autoassignation of mac addressses decreasing this value
our $MAC_ADDR_COUNTER : shared = 99;
our $lockAddress : shared;

# Class: NetworkInterface
#
#   Contains the information of a network interface.
#

# Constant: IFACE_TYPE_STATIC
#
#   Constant for the network interface type that indicates static
#   configuration.
#
use constant IFACE_TYPE_STATIC => 0;

# Constant: IFACE_TYPE_DHCP
#
#   Constant for the network interface type that indicates dynamic
#   configuration.
#
use constant IFACE_TYPE_DHCP => 1;

# Constant: IFACE_TYPE_UNSET
#
#   Constant for the network interface type that indicates a
#   interface without configuration.
#
use constant IFACE_TYPE_UNSET => 2;

# Constructor: new
#
#   Constructor for NetworkInterface class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::NetworkInterface> object.
#
sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{type} = IFACE_TYPE_STATIC;
    $self->{name} = '';
    $self->{address} = '';
    $self->{netmask} = '';
    $self->{gateway} = '';
    $self->{external} = 0;
    $self->{bridge} = 1;
    # Autoassing mac address
    {
        lock($lockAddress);
        $self->{hwAddress} = AUTOASSIGNED_MAC_ADDR_START . $MAC_ADDR_COUNTER;
        $MAC_ADDR_COUNTER--;
        if ($MAC_ADDR_COUNTER < 0) {
            $MAC_ADDR_COUNTER = 99;
        }
    }

    bless($self, $class);

    return $self;
}

# Method: name
#
#   Gets the interface name.
#
# Returns:
#
#   string - contains the name of the interface
#
sub name
{
    my ($self) = @_;

    return $self->{name};
}

# Method: setName
#
#   Sets the interface name.
#
# Parameters:
#
#   name - String with the name of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setName
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    $self->{name} = $name;
}

# Method: type
#
#   Gets the interface type.
#
# Returns:
#
#   constant - IFACE_TYPE_STATIC or IFACE_TYPE_DHCP or IFACE_TYPE_UNSET
#
sub type
{
    my ($self) = @_;

    return $self->{type};
}

# Method: setTypeStatic
#
#   Sets the interface type to static.
#
sub setTypeStatic
{
    my ($self) = @_;

    $self->{type} = IFACE_TYPE_STATIC;
}

# Method: setTypeDHCP
#
#   Sets the interface type to DHCP.
#
sub setTypeDHCP
{
    my ($self) = @_;

    $self->{type} = IFACE_TYPE_DHCP;
}

# Method: setTypeUnset
#
#   Sets the interface type to unset.
#
sub setTypeUnset
{
    my ($self) = @_;

    $self->{type} = IFACE_TYPE_UNSET;
}

# Method: address
#
#   Gets the interface address.
#
# Returns:
#
#   string - the interface IP address
#
sub address
{
    my ($self) = @_;

    return $self->{address};
}

# Method: setAddress
#
#   Sets the interface address.
#
# Parameters:
#
#   address - String with the IP address of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setAddress
{
    my ($self, $address) = @_;

    defined $address or
        throw ANSTE::Exceptions::MissingArgument('address');

    if (not ANSTE::Validate::ip($address)) {
        throw ANSTE::Exceptions::InvalidData('address', $address);
    }

    $self->{address} = $address;
}

# Method: hwAddress
#
#   Gets the interface hardware address.
#
# Returns:
#
#   string - the interface hardware address
#
sub hwAddress
{
    my ($self) = @_;

    return $self->{hwAddress};
}

# Method: setHwAddress
#
#   Sets the interface hardware address.
#
# Parameters:
#
#   hwAddress - String with the hardware address of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setHwAddress
{
    my ($self, $hwAddress) = @_;

    defined $hwAddress or
        throw ANSTE::Exceptions::MissingArgument('hwAddress');

    if (not ANSTE::Validate::mac($hwAddress)) {
        throw ANSTE::Exceptions::InvalidData('hwAddress', $hwAddress);
    }

    $self->{hwAddress} = $hwAddress;
}


# Method: netmask
#
#   Gets the interface network mask.
#
# Returns:
#
#   string - contains the network mask of the interface
#
sub netmask
{
    my ($self) = @_;

    return $self->{netmask};
}

# Method: setNetmask
#
#   Sets the interface network mask.
#
# Parameters:
#
#   netmask - String with the network mask of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setNetmask
{
    my ($self, $netmask) = @_;

    defined $netmask or
        throw ANSTE::Exceptions::MissingArgument('netmask');

    if (not ANSTE::Validate::ip($netmask)) {
        throw ANSTE::Exceptions::InvalidData('netmask', $netmask);
    }

    $self->{netmask} = $netmask;
}

# Method: gateway
#
#   Gets the interface gateway.
#
# Returns:
#
#   string - contains the gateway of the interface
#
sub gateway
{
    my ($self) = @_;

    return $self->{gateway};
}

# Method: setGateway
#
#   Sets the interface gateway.
#
# Parameters:
#
#   gateway - String with the gateway of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidData> - throw if argument is not an IP address
#
sub setGateway
{
    my ($self, $gateway) = @_;

    defined $gateway or
        throw ANSTE::Exceptions::MissingArgument('gateway');

    if (not ANSTE::Validate::ip($gateway)) {
        throw ANSTE::Exceptions::InvalidData('gateway', $gateway);
    }

    $self->{gateway} = $gateway;
}

# Method: removeGateway
#
#   Remove the interface gateway.
#
sub removeGateway
{
    my ($self) = @_;

    $self->{gateway} = '';
}

# Method: external
#
#   Gets if the interface is external or not.
#
# Returns:
#
#   boolean - true if it's external, false otherwise.
#
sub external
{
    my ($self) = @_;

    return $self->{external};
}

# Method: setExternal
#
#   Sets the if the interface is external or not.
#
# Parameters:
#
#   external - boolean.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setExternal
{
    my ($self, $external) = @_;

    defined $external or
        throw ANSTE::Exceptions::MissingArgument('external');

    $self->{external} = $external;
}

# Method: bridge
#
#   Gets the interface bridge.
#
# Returns:
#
#   string - contains the bridge of the interface
#
sub bridge
{
    my ($self) = @_;

    return $self->{bridge};
}

# Method: setBridge
#
#   Sets the interface bridge.
#
# Parameters:
#
#   bridge - String with the bridge of the interface.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setBridge
{
    my ($self, $bridge) = @_;

    defined $bridge or
        throw ANSTE::Exceptions::MissingArgument('bridge');

    $self->{bridge} = $bridge;
}

sub loadYAML
{
    my ($self, $iface) = @_;

    defined $iface or
        throw ANSTE::Exceptions::MissingArgument('iface');

    my $type = $iface->{type};
    my $name = $iface->{name};
    $self->setName($name);
    if ($type eq 'static') {
        $self->setTypeStatic();
        my $address = $iface->{address};
        $self->setAddress($address);
        my $netmask = $iface->{netmask};
        $self->setNetmask($netmask);
        my $gateway = $iface->{gateway};
        if ($gateway) {
            $self->setGateway($gateway);
        }
        my $external = $iface->{external};
        if ($external) {
            $self->setExternal(1);
        }
    } elsif ($type eq 'dhcp') {
        $self->setTypeDHCP();
    } elsif ($type eq 'unset') {
        $self->setTypeUnset();
    } else {
        throw ANSTE::Exceptions::Error("Invalid type for interface $name");
    }
    # MAC address may be specified on both dhcp and static interfaces
    my $hwAddr = $iface->{'hw-addr'};
    if ($hwAddr) {
        $self->setHwAddress($hwAddr);
    }

    my $bridge = $iface->{bridge};
    if (defined ($bridge)) {
        $self->setBridge($bridge);
    } else {
        unless ($type eq 'static') {
            throw ANSTE::Exceptions::Error("Auto-bridging cannot be done with non-static interface $name. You need to specify a bridge manually.");
        }
    }
}

1;

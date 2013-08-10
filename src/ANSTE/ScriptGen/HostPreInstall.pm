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

package ANSTE::ScriptGen::HostPreInstall;

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
sub new # (image) returns new HostInstallGen object
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
sub writeScript # (file)
{
    my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    if (not -w $file) {
        throw ANSTE::Exceptions::InvalidFile('file', $file);
    }

    my $hostname = $self->{image}->name();

    print $file "#!/bin/sh\n";
    print $file "\n# Hostname configuration file\n";
    print $file "# Generated by ANSTE for host $hostname\n\n";

    print $file "# Receives the mount point of the image as an argument\n";
    print $file 'MOUNT=$1'."\n\n";

    $self->_writeHostnameConfig($file);
    $self->_writeHostConfig($file);
    $self->_writeInitialNetworkConfig($file);
    $self->_writeMasterAddress($file);
}

sub _writeHostnameConfig # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $hostname = $self->{image}->name();

    print $file "# Write hostname config\n";
    my $config = $system->hostnameConfig($hostname);
    print $file "$config\n\n";
}

sub _writeHostConfig # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};
    my $host = $self->{image}->name();

    print $file "# Write host configuration\n";
    my $config = $system->hostConfig($host);
    print $file "$config\n\n";
}

sub _writeInitialNetworkConfig # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};
    my $iface = $self->{image}->commInterface();
    my $network = $self->{image}->network();
    unless ($network) {
        return;
    }

    my $config = $system->initialNetworkConfig($iface, $network);

    print $file "# Write initial network configuration\n";
    print $file "$config\n\n";
}

sub _writeMasterAddress # (file)
{
    my ($self, $file) = @_;

    my $system = $self->{system};

    my $config = ANSTE::Config->instance();
    my $port = $config->masterPort();
    my $masterIP = $config->gateway();
    my $MASTER = "$masterIP:$port";

    print $file "# Stores the master address so anste-slave can read it\n";
    my $command = $system->storeMasterAddress($MASTER);
    print $file "$command\n";
}

1;
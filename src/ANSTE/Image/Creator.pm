# Copyright (C) 2007-2013 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2014 Rubén Durán Balda <rduran@zentyal.com>
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

package ANSTE::Image::Creator;

use warnings;
use strict;

use ANSTE::Image::Commands;
use ANSTE::Comm::WaiterServer;
use ANSTE::Image::Image;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;
use ANSTE::Scenario::Scenario;
use ANSTE::Virtualizer::Virtualizer;

use TryCatch;

# Class: Creator
#
#   Creates base images.
#

# Constructor: new
#
#   Constructor for Creator class.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   A recently created <ANSTE::Image::Creator> object.
#
sub new # (image) returns new ImageCreator object
{
    my ($class, $image) = @_;
    my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exceptions::InvalidType('image',
                                             'ANSTE::Scenario::BaseImage');
    }

    $self->{virtualizer} = ANSTE::Virtualizer::Virtualizer->instance();

    $self->{image} = $image;

    bless($self, $class);

    return $self;
}

# Method: createImage
#
#   Does the image creation. If the image already exists, does nothing,
#   unless reuse config option is set.
#
# Returns:
#
#   boolean - true if the image is created, false if already exists
#
# Exceptions:
#
#   throws ANSTE::Exceptions::Error
#
sub createImage
{
    my ($self) = @_;

    my $image = $self->{image};
    my $name = $image->name();
    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();

    my $cmd = new ANSTE::Image::Commands($image);

    if ($cmd->exists() and not $reuse) {
        return 0;
    }
    elsif (not $reuse or not $cmd->exists()) {
        print "[$name] Creating image...";
        $cmd->create()
            or throw ANSTE::Exceptions::Error('Error creating base image.');
        print "done.\n";
    }

    print "[$name] Mounting image... ";
    $cmd->mount()
        or throw ANSTE::Exceptions::Error('Error mounting image.');
    print "done.\n";

    try {
        print "[$name] Copying base files... ";
        $cmd->copyBaseFiles()
            or throw ANSTE::Exceptions::Error('Error copying files.');
        print "done.\n";

        my $proxy = $config->vmBuilderProxy();
        if ($proxy) {
            print "[$name] Configuring apt proxy... ";
            $cmd->configureAptProxy($proxy)
                or throw ANSTE::Exceptions::Error('Error configuring apt proxy.');
            print "done.\n";
        }

        print "[$name] Installing base packages... ";
        $cmd->installBasePackages()
            or throw ANSTE::Exceptions::Error('Error installing packages.');
        print "done.\n";

        print "[$name] Final configurations... ";
        $cmd->finalConfigurations()
            or throw ANSTE::Exceptions::Error('Error finishing configuration.');
        print "done.\n";

    } catch ($e) {
        $self->_umountImage($cmd, $name);
        $e->throw();
    }
    $self->_umountImage($cmd, $name);

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    # Set up the network before deploy
    print "[$name] Setting up network... ";
    my $virtualizer = $self->{virtualizer};

    # Get the network address for the communications interface
    # and add the bridge to the a mock scenario
    my $scenario = new ANSTE::Scenario::Scenario();
    my $firstAddress = ANSTE::Config->instance()->firstAddress();
    my ($net, $unused) =
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;
    $scenario->addBridge($net);

    $virtualizer->createNetwork($scenario)
        or throw ANSTE::Exceptions::Error('Error creating network.');
    print "done.\n";

    try {
        print "[$name] Starting to prepare the system... \n";
        $cmd->prepareSystem()
            or throw ANSTE::Exceptions::Error('Error preparing system.');
    } catch (ANSTE::Exceptions::Error $e) {
        my $msg = $e->message();
        print "ERROR: $msg\n";
        $self->_shutdown($cmd);
        $e->throw();
    } catch ($e) {
        print "ERROR: $e\n";
    }
    $self->_shutdown($cmd);

    $virtualizer->destroyNetwork($scenario);

    print "[$name] Image creation finished.\n";

    return 1;
}

# Method: update
#
#   Updates the image using the virtualizer interface
#
sub update
{
    my ($self) = @_;

    my $image = $self->{image};
    my $name = $image->name();

    my $cmd = new ANSTE::Image::Commands($image);

    if (not $cmd->exists()) {
        print "[$name] Cannot update an image that does not exists.\n";
        return 0;
    }

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    # Set up the network before deploy
    print "[$name] Setting up network...\n";
    my $virtualizer = $self->{virtualizer};

    # Get the network address for the communications interface
    # and add the bridge to the a mock scenario
    my $scenario = new ANSTE::Scenario::Scenario();
    my $firstAddress = ANSTE::Config->instance()->firstAddress();
    my ($net, $unused) =
        $firstAddress =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3})\.(\d{1,3})$/;
    $scenario->addBridge($net);

    $virtualizer->createNetwork($scenario)
        or throw ANSTE::Exceptions::Error('Error creating network.');
    print "done.\n";

    try {
        print "[$name] Starting to update the image...\n";

        $cmd->updateSystem()
            or throw ANSTE::Exceptions::Error('Error updating system.');
    } catch (ANSTE::Exceptions::Error $e) {
        my $msg = $e->message();
        print "ERROR: $msg\n";
        $self->_shutdown($cmd);
        $e->throw();
    } catch ($e) {
        print "ERROR: $e\n";
    }
    $self->_shutdown($cmd);

    $virtualizer->destroyNetwork($scenario);


    print "[$name] Image update finished.\n";

    return 1;
}

sub _shutdown
{
    my ($self, $cmd) = @_;

    my $config = ANSTE::Config->instance();
    if ($config->wait()) {
        print "Waiting for testing on the image. " .
              "Press any key to shutdown it and finish.\n";
        my $line = <STDIN>;
    }
    $cmd->shutdown();
}

sub _umountImage
{
    my ($self, $cmd, $name) = @_;

    print "[$name] Umounting image... ";
    $cmd->umount()
        or throw ANSTE::Exceptions::Error('Error unmounting image.');
    print "done.\n";
}

1;

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

package ANSTE::Image::Creator;

use warnings;
use strict;

use ANSTE::Image::Commands;
use ANSTE::Comm::WaiterServer;
use ANSTE::Image::Image;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use Error qw(:try);

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
    my $reuse = ANSTE::Config->instance()->reuse();

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

        print "[$name] Installing base packages... ";
        $cmd->installBasePackages() 
            or throw ANSTE::Exceptions::Error('Error installing packages.');
        print "done.\n";
    } finally {
        print "[$name] Umounting image... ";
        $cmd->umount()
            or throw ANSTE::Exceptions::Error('Error unmounting image.');
        print "done.\n";
    };

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    try {
        print "[$name] Starting to prepare the system... \n";
        $cmd->prepareSystem()
            or throw ANSTE::Exceptions::Error('Error preparing system.');
    } finally {
        $cmd->shutdown();
    };

    print "[$name] Resizing image... ";
    $cmd->resize($image->size())
        or throw ANSTE::Exceptions::Error('Error resizing image.');
    
    print "[$name] Image creation finished.\n";

    return 1;
}



1;

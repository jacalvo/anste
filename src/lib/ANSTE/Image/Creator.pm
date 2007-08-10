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
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use Error qw(:try);

sub new # (image) returns new ImageCreator object
{
	my ($class, $image) = @_;
	my $self = {};

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    if (not $image->isa('ANSTE::Image::Image')) {
        throw EBox::Exception::InvalidType('image',
                                           'ANSTE::Image::Image');
    }
	
	$self->{image} = $image;

	bless($self, $class);

	return $self;
}

sub createImage
{
    my ($self) = @_;

    my $image = $self->{image};

    my $cmd = new ANSTE::Image::Commands($image);

    $cmd->create() or die 'Error creating base image.';

    try {
        $cmd->mount() or die 'Error mounting image.';

        $cmd->copyBaseFiles() or die 'Error copying files.';

        $cmd->installBasePackages() or die 'Error installing packages.';
    } finally {
        $cmd->umount() or die 'Error unmounting image.';
    };

    # Starts Master Server thread
    my $server = new ANSTE::Comm::WaiterServer();
    $server->startThread();

    try {
        $cmd->prepareSystem() or die 'Error preparing system.'; 
    } finally {
        $cmd->shutdown();
    };

    $cmd->resize($image->size()) or die 'Error resizing image.';
}

1;

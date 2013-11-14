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

package ANSTE::Image::Getter;

use warnings;
use strict;

use ANSTE::Image::Commands;
use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: Getter
#
#   Downloads base images.
#

# Constructor: new
#
#   Constructor for Getter class.
#
# Parameters:
#
#   image - <ANSTE::Scenario::BaseImage> object.
#
# Returns:
#
#   A recently created <ANSTE::Image::Getter> object.
#
sub new # (image)
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

# Method: getImage
#
#   Gets the image. If the image already exists, does nothing,
#   unless reuse config option is set.
#
# Returns:
#
#   boolean - true if the image is gotten, false if already exists
#
# Exceptions:
#
#   throws ANSTE::Exceptions::Error
#
sub getImage
{
    my ($self) = @_;

    my $image = $self->{image};
    my $name = $image->name();
    my $config = ANSTE::Config->instance();
    my $reuse = $config->reuse();

    my $cmd = new ANSTE::Image::Commands($image);

    my $imgdir = $config->imagePath();
    if ($cmd->exists() and not $reuse) {
        return 0;
    } elsif (not $reuse or not $cmd->exists()) {
        print "[$name] Downloading image...\n";
        $cmd->get()
            or throw ANSTE::Exceptions::Error('Error getting base image.');
        print "done.\n";
    }

    return 1;
}

1;

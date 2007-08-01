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

package ANSTE::Virtualizer::Xen;

use base 'ANSTE::Virtualizer::Virtualizer';

use strict;
use warnings;

# Method: createImage
#
#   Overriden method that creates a new base image using the xen-create-image
#   utility from xen-tools.
#
# Parameters: 
#   
#   name    -   name of the image type to be created
#   ip      -   ip address that will be assigned to the image
#   config  -   path of the specific xen-tools.conf file 
#
# Returns:
#
#   boolean - Always returns true due to xen-create-image is broken and
#             returns it although the creation process fails.
#
sub createImage # (%params)
{
    my ($self, %params) = @_;
    my $name = $params{name};
    my $ip = $params{ip};
    my $confFile = $params{config};

    my $command = "xen-create-image --hostname=$name" .
                  " --ip='192.168.45.191' --config=$confFile"; 

    $self->execute($command);
}

# Method: shutdownImage 
#
#   Overriden method that destroys a Xen running image.
#
# Parameters:
#
#   image - name of the image to shutdown 
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
sub shutdownImage # (image)
{
    my ($self, $image) = @_;

    $self->execute("xm destroy $image");
}

# Method: createVM
#
#   Overriden method that creates a Xen Virtual Machine.
#
# Parameters:
#
#   name - name of the xen configuration file for the image 
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
sub createVM # (name)
{
    my ($self, $name) = @_;

    $self->execute("xm create $name.cfg");
}

# Method: imageFile
#
#   Overriden method to get the path o a Xen disk image. 
#
# Parameters:
#
#   path - root directory where images are stored
#   name - name of the image (of the directory in the Xen case)
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#
sub imageFile # (path, name)
{
    my ($self, $path, $name) = @_;

    return "$path/$name/disk.img";
}

1;

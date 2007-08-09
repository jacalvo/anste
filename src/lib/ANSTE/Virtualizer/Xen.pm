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

use ANSTE::Config;
use ANSTE::Image::Image;
use ANSTE::Exceptions::MissingArgument;

use File::Copy;
use File::Copy::Recursive qw(dircopy);

use constant XEN_CONFIG_TEMPLATE => 'data/xen-config.tmpl';

# Method: createBaseImage
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
sub createBaseImage # (%params)
{
    my ($self, %params) = @_;

    exists $params{name} or
        throw ANSTE::Exceptions::MissingArgument('name');
    exists $params{ip} or
        throw ANSTE::Exceptions::MissingArgument('ip');
    exists $params{config} or
        throw ANSTE::Exceptions::MissingArgument('config');

    my $name = $params{name};
    my $ip = $params{ip};
    my $confFile = $params{config};

    my $command = "xen-create-image --hostname=$name" .
                  " --ip='$ip' --config=$confFile"; 

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

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

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

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

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

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    return "$path/$name/disk.img";
}

# Method: copyImage
#
#  Overriden method that creates a copy of a base image
#  with the specified new configuration.
#
# Parameters:
#
#   baseimage - an <ANSTE::Deploy::BaseImage> object with the configuration
#               of the base image
#   newimage  - an <ANSTE::Deploy::Image> object with the configuration 
#               of the new image
#
# Returns:
#   
#   boolean   - indicates if the process has been successful
#
sub createImageCopy # (baseimage, newimage)
{
    my ($self, $baseimage, $newimage) = @_;

    defined $baseimage or
        throw ANSTE::Exceptions::MissingArgument('baseimage');
    defined $newimage or
        throw ANSTE::Exceptions::MissingArgument('newimage');

    my $path = ANSTE::Config->instance()->imagePath();

    my $basename = $baseimage->name();
    my $newname = $newimage->name();

    dircopy("$path/$basename", "$path/$newname");

    # TODO: Change /etc/hostname and /etc/hosts with the new values

    # Creates the configuration file for the new image
    my $config = $self->_createConfig($newimage, $path);

    # Writes the xen configuration file
    my $FILE;
    my $configFile = "/etc/xen/$newname.cfg";
    open($FILE, '>', $configFile) or return 0;
    print $FILE $config;
    close($FILE) or return 0; 

    return 1;
}

# Method: deleteImage 
#
#   Overriden method that deletes an Xen image using
#   the xen-delete-image program from xen-tools.
#
# Parameters: 
#   
#   image - name of the image to be deleted
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
sub deleteImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    $self->execute("xen-delete-image $image");
}


sub _createConfig # (image, path) returns config string
{
    my ($self, $image, $path) = @_;

    use Text::Template;

    my $template = new Text::Template(SOURCE => XEN_CONFIG_TEMPLATE)
        or die "Couldnt' construct template: $Text::Template::ERROR";

    my %vars = (hostname => $image->name(),
                ip => $image->ip(),
                memory => $image->memory(),
                path => $path,
                device => 'sda');

    my $config = $template->fill_in(HASH => \%vars)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    return $config;
}

1;

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
use ANSTE::Exceptions::InvalidType;
use ANSTE::Exceptions::NotFound;

use File::Temp qw(tempfile);
use File::Copy;
use File::Copy::Recursive qw(dircopy);

use constant XEN_CONFIG_TEMPLATE => 'xen-config.tmpl';

# Class: Xen
#
#   Implementation of the Virtualizer class that interacts
#   with the Xen virtualization software.
#

# Method: createBaseImage
#
#   Overriden method that creates a new base image using the xen-create-image
#   utility from xen-tools.
#
# Parameters: 
#   
#   name    -   name of the image type to be created
#   ip      -   ip address that will be assigned to the image
#
# Returns:
#
#   boolean - Always returns true due to xen-create-image is broken and
#             returns it although the creation process fails.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createBaseImage # (%params)
{
    my ($self, %params) = @_;

    exists $params{name} or
        throw ANSTE::Exceptions::MissingArgument('name');
    exists $params{ip} or
        throw ANSTE::Exceptions::MissingArgument('ip');

    my $name = $params{name};
    my $ip = $params{ip};

    my $confFile = _createXenToolsConfig();

    my $config = ANSTE::Config->instance();

    my $dir = $config->imagePath();
    my $ide = $config->xenUseIdeDevices();
    my $modules = $config->xenModules();

    my $command = "xen-create-image --dir=$dir --hostname=$name" .
                  " --ip='$ip' --config=$confFile"; 
    
    if ($ide) {
        $command .= " --ide";
    }

    if ($modules) {
        $command .= " --modules=$modules";
    }

    print "Showing xen-tools.conf:\n";
    open(FILE, '<', $confFile);
    foreach(<FILE>) {
        print;
    }
    close(FILE);

    $self->execute($command);

    unlink($confFile);
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
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub shutdownImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $config = ANSTE::Config->instance();

    $self->execute("xm shutdown $image");

    # Wait until shutdown finishes
    my $waitScript = $config->scriptFile('xen-waitshutdown.sh');
    system("$waitScript $image");
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
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
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
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub imageFile # (path, name)
{
    my ($self, $path, $name) = @_;

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');
    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    return "$path/domains/$name/disk.img";
}

# Method: copyImage
#
#  Overriden method that creates a copy of a base image
#  with the specified new configuration.
#
# Parameters:
#
#   baseimage - an <ANSTE::Scenario::BaseImage> object with the configuration
#               of the base image
#   newimage  - an <ANSTE::Image::Image> object with the configuration 
#               of the new image
#
# Returns:
#   
#   boolean   - indicates if the process has been successful
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub createImageCopy # (baseimage, newimage)
{
    my ($self, $baseimage, $newimage) = @_;

    defined $baseimage or
        throw ANSTE::Exceptions::MissingArgument('baseimage');
    defined $newimage or
        throw ANSTE::Exceptions::MissingArgument('newimage');

    if (not $baseimage->isa('ANSTE::Scenario::BaseImage')) {
        throw ANSTE::Exception::InvalidType('baseimage',
                                            'ANSTE::Scenario::BaseImage');
    }
    if (not $newimage->isa('ANSTE::Image::Image')) {
        throw ANSTE::Exception::InvalidType('newimage',
                                            'ANSTE::Image::Image');
    }

    my $path = ANSTE::Config->instance()->imagePath();

    my $basename = $baseimage->name();
    my $newname = $newimage->name();

    if (not -r $self->imageFile($path, $basename)) {
        throw ANSTE::Exceptions::NotFound('Image', $basename);
    }

    dircopy("$path/domains/$basename", "$path/domains/$newname");

    # Creates the configuration file for the new image
    my $config = $self->_createImageConfig($newimage, $path);

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
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub deleteImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    my $dir = ANSTE::Config->instance()->imagePath();

    $self->execute("xen-delete-image $image --dir $dir");
}

sub _createXenToolsConfig # returns filename
{
    my ($self) = @_;

    my ($fh, $filename) = tempfile();

    my $config = ANSTE::Config->instance();

    my $dir = $config->imagePath();
    my $installMethod = $config->xenInstallMethod();
    my $size = $config->xenSize();
    my $memory = $config->xenMemory();
    my $noSwap = $config->xenNoSwap();
    my $dist = $config->xenDist();
    my $image = $config->xenImage();
    my $kernel = $config->xenKernel();
    my $initrd = $config->xenInitrd();
    my $mirror = $config->xenMirror();
    my $gateway = $config->gateway();
    my $netmask = '255.255.255.0';

    print $fh "dir = $dir\n";
    print $fh "install-method = $installMethod\n";
    print $fh "size = $size\n";
    print $fh "memory = $memory\n";
    print $fh "noswap = $noSwap\n";
    print $fh "dist = $dist\n";
    print $fh "image = $image\n";
    print $fh "cache = no\n";
    print $fh "kernel = $kernel\n";
    print $fh "initrd = $initrd\n";
    print $fh "mirror = $mirror\n";
    print $fh "gateway = $gateway\n";
    print $fh "netmask = $netmask\n";

    close($fh);

    return $filename;
}

sub _createImageConfig # (image, path) returns config string
{
    my ($self, $image, $path) = @_;

    use Text::Template;

    my $tmplPath = ANSTE::Config->instance()->templatePath();
    my $confFile = "$tmplPath/" . XEN_CONFIG_TEMPLATE;

    my $template = new Text::Template(SOURCE => $confFile)
        or die "Couldn't construct template: $Text::Template::ERROR";

    my $ip = $image->{ip};

    my $ifaceList = "'ip=$ip'";

    foreach my $iface (@{$image->network()->interfaces()}) {
        $ip = $iface->address();
        my $mac = $iface->hwAddress();
        if ($mac) {
            $ifaceList .= ", 'ip=$ip,mac=$mac'";
        }
        else {
            $ifaceList .= ", 'ip=$ip'";
        }
    }

    my $useIDE = ANSTE::Config->instance()->xenUseIdeDevices();
    my $device = $useIDE ? 'hda' : 'sda';

    my %vars = (hostname => $image->name(),
                iface_list => $ifaceList,
                memory => $image->memory(),
                path => $path,
                device => $device);

    my $config = $template->fill_in(HASH => \%vars)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    return $config;
}

1;

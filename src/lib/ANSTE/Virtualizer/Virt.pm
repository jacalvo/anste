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

package ANSTE::Virtualizer::Virt;

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

use constant KVM_CONFIG_TEMPLATE => 'kvm-config.tmpl';

# Class: Virt
#
#   Implementation of the Virtualizer class that interacts
#   with libvirt.
#

# Method: createBaseImage
#
#   Overriden method that creates a new base image using the xen-create-image
#   utility from xen-tools.
#
# Parameters: 
#   
#   name    - name of the image type to be created
#   ip      - ip address that will be assigned to the image
#   memory  - *optional* size of the RAM memory to be used
#   swap    - *optional* size of the swap partition to be used
#   dist    - distribution to be installed (for debootstrap method)
#   command - command to be used for the installation (for debootstrap method)
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
    my $memory = $params{memory};
    my $swap = $params{swap};
    my $dist = $params{dist};

    my $config = ANSTE::Config->instance();

    my $size = $config->virtSize();
    my $gateway = $config->gateway();
    my $netmask = '255.255.255.0';

    if (not $memory) {
        $memory = $config->virtMemory();
    }        

    my $dir = $config->imagePath() . '/' . $name;
    # FIXME: si el directorio ya existe avisar...

    my $mirror = $config->xenMirror(); # TODO: change this to generic ->mirror() ?

    my $vm = 'kvm'; # FIXME: Unhardcode this
    my $command = "ubuntu-vm-builder $vm $dist --dest $dir --hostname $name" .
                  " --ip $ip --mirror $mirror --mem $memory" . 
                  " --mask $netmask --gw $gateway --rootsize $size" .
                  " --components main,universe"; 
    
    if ($swap) {
        $command .= " --swapsize $swap";
    }
    
    $self->execute($command);

    # Creates the configuration file for the new image
    my $image = new ANSTE::Image::Image(name => $name,
                                        ip => $ip,
                                        memory => $memory);
    my $xml = $self->_createImageConfig($image, $dir);

    # Writes the qemu configuration file
    my $FILE;
    my $xmlFile = "/etc/libvirt/qemu/$name.xml";
    open($FILE, '>', $xmlFile) or return 0;
    print $FILE $xml;
    close($FILE) or return 0; 
}

# Method: shutdownImage 
#
#   Overriden method that shuts down a Xen running image.
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

    $self->execute("virsh shutdown $image");

    # Wait until shutdown finishes
    my $waitScript = $config->scriptFile('kvm-waitshutdown.sh');
    system("$waitScript $image");
}

# Method: destroyImage 
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
sub destroyImage # (image)
{
    my ($self, $image) = @_;

    defined $image or
        throw ANSTE::Exceptions::MissingArgument('image');

    $self->execute("virsh destroy $image");
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

    $self->execute("virsh create /etc/libvirt/qemu/$name.xml");
}

# Method: imageFile
#
#   Overriden method to get the path o a KVM disk image. 
#
# Parameters:
#
#   path - root directory where images are stored
#   name - name of the image (of the directory in the KVM case)
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

    return "$path/$name/root.qcow2";
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

    dircopy("$path/$basename", "$path/$newname");

    # Creates the configuration file for the new image
    my $config = $self->_createImageConfig($newimage, $path);

    # Writes the xen configuration file
    my $FILE;
    my $configFile = "/etc/libvirt/qemu/$newname.xml";
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

sub _createImageConfig # (image, path) returns config string
{
    my ($self, $image, $path) = @_;

    use Text::Template;

    my $tmplPath = ANSTE::Config->instance()->templatePath();
    my $confFile = "$tmplPath/" . KVM_CONFIG_TEMPLATE;

    my $template = new Text::Template(SOURCE => $confFile)
        or die "Couldn't construct template: $Text::Template::ERROR";

    my $ip = $image->{ip};

#    my $ifaceList = "'ip=$ip'";

#    foreach my $iface (@{$image->network()->interfaces()}) {
#        $ip = $iface->address();
#        my $mac = $iface->hwAddress();
#        if ($ip and $mac) {
#            $ifaceList .= ", 'ip=$ip,mac=$mac'";
#        }
#        elsif ($mac) {
#            $ifaceList .= ", 'mac=$mac'";
#       }
#       else {
#           $ifaceList .= ", 'ip=$ip'";
#       }
#   }

    my $config = ANSTE::Config->instance();

    my %vars = (hostname => $image->name(),
                memory => $image->memory(),
                path => $path);

    my $imageConfig = $template->fill_in(HASH => \%vars)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    return $imageConfig;
}

1;

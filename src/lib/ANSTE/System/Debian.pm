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

package ANSTE::System::Debian;

use base 'ANSTE::System::System';

use strict;
use warnings;

# Method: mountImage 
#
#   Overriden method that executes mount with
#   the given image and mount point as arguments.
#
# Parameters: 
#   
#   image      - path of the image to mount 
#   mountPoint - directory where the image will be mounted
#
# Returns:
#   
#   boolean    - indicates if the process has been successful
#               
sub mountImage # (image, mountPoint)
{
    my ($self, $image, $mountPoint) = @_;

    my $cmd = "mount -t ext3 -o loop $image $mountPoint";

    $self->execute($cmd);
}

# Method: unmount 
#
#   Overriden method that executes umount with
#   the mount point specified.
#
# Parameters: 
#   
#   mountPoint - path of the mounted directory 
#
# Returns:
#   
#   boolean    - indicates if the process has been successful
#               
sub unmount # (mountPoint)
{
    my ($self, $mountPoint) = @_;

    $self->execute("umount $mountPoint");
}

# Method: installBasePackages 
#
#   Overriden methods that install the required packages
#   to run anste on the slave host by using apt.
#   Also creates the init.d symlinks for ansted.
#
# Returns:
#   
#   boolean - indicates if the process has been successful
#               
sub installBasePackages
{
    my ($self) = @_;

    $self->execute('apt-get update') 
        or die "apt-get update failed: $!";

    my $ret = $self->_installPackages('libsoap-lite-perl');

    $self->execute('apt-get clean') 
        or die "apt-get clean failed: $!";

    $self->execute('update-rc.d ansted defaults 99') 
        or die "update-rc.d failed: $!";

    return($ret);
}

sub _installPackages # (list)
{
    my ($self, $list) = @_;

    $ENV{DEBIAN_FRONTEND} = 'noninteractive';

    my $forceNew = '-o DPkg::Options::=--force-confnew';
    my $forceDef = '-o DPkg::Options::=--force-confdef';
    my $options = "-y $forceNew $forceDef";

    my $command = "apt-get install $options $list";

    $self->execute($command);
}

1;

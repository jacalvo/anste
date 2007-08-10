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

package ANSTE::Config;

use strict;
use warnings;

use ANSTE::Exceptions::InvalidConfig;
use ANSTE::Validate;

use Config::Tiny;

use constant CONFIG_FILE => 'data/anste.conf';

my $singleton;

# TODO: Add exception throwing when incorrect values in the file

sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        $self->{config} = Config::Tiny->read(CONFIG_FILE);
        
        $singleton = bless($self, $class);

        $singleton->_setDefaults();
    }

    return $singleton;
}

sub system
{
    my ($self) = @_;

    return $self->_getOption('global', 'system');
}

sub virtualizer
{
    my ($self) = @_;

    return $self->_getOption('global', 'virtualizer');
}

sub imagePath
{
    my ($self) = @_;

    return $self->_getOption('paths', 'images');
}

sub imageTypePath
{
    my ($self) = @_;

    return $self->_getOption('paths', 'image-types');
}

sub scenarioPath
{
    my ($self) = @_;

    return $self->_getOption('paths', 'scenarios');
}

sub profilePath
{
    my ($self) = @_;

    return $self->_getOption('paths', 'profiles');
}

sub scriptPath
{
    my ($self) = @_;

    return $self->_getOption('paths', 'scripts');
}

sub anstedPort
{
    my ($self) = @_;

    return $self->_getOption('ansted', 'port');
}

sub masterPort
{
    my ($self) = @_;

    return $self->_getOption('master', 'port');
}

sub ipRange
{
    my ($self) = @_;

    my $ipRange =  $self->_getOption('comm', 'ip-range');

    if (not ANSTE::Validate::ipRange($ipRange)) {
        throw ANSTE::Exceptions::InvalidConfig('ip-range', $ipRange);
    }

    return $ipRange;
}

sub gateway
{
    my ($self) = @_;

    my $gateway =  $self->_getOption('comm', 'gateway');

    if (not ANSTE::Validate::ip($gateway)) {
        throw ANSTE::Exceptions::InvalidConfig('gateway', $gateway);
    }

    return $gateway;
}

sub xenDir
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'dir');
}

sub xenInstallMethod
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'install-method');
}

sub xenSize
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'size');
}

sub xenMemory
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'memory');
}

sub xenNoSwap
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'noswap');
}

sub xenFS
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'fs');
}

sub xenDist
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'dist');
}

sub xenImage
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'image');
}

sub xenKernel
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'kernel');
}

sub xenInitrd
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'initrd');
}

sub xenMirror
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'mirror');
}

sub _getOption # (section, option)
{
    my ($self, $section, $option) = @_;

    my $config = $self->{config}->{$section}->{$option};

    # TODO: Manage overriden options (by passing parameters, etc)
    if (defined $config) {
        return $config;
    } else {
        return $self->{default}->{$section}->{$option};
    }
}

sub _setDefaults
{
    my ($self) = @_;

    $self->{default}->{'global'}->{'system'} = 'Debian';
    $self->{default}->{'global'}->{'virtualizer'} = 'Xen';

    $self->{default}->{'paths'}->{'images'} = '/home/xen/domains';
    $self->{default}->{'paths'}->{'image-types'} = 'data/images';
    $self->{default}->{'paths'}->{'scenarios'} = 'data/scenarios';
    $self->{default}->{'paths'}->{'profiles'} = 'data/profiles';
    $self->{default}->{'paths'}->{'scripts'} = 'data/scripts';

    $self->{default}->{'ansted'}->{'port'} = '8000';

    $self->{default}->{'master'}->{'port'} = '8001';

    $self->{default}->{'comm'}->{'ip-range'} = '192.168.0';
    $self->{default}->{'comm'}->{'gateway'} = '192.168.0.1';

    $self->{default}->{'xen-options'}->{'dir'} = '/home/xen';
    $self->{default}->{'xen-options'}->{'install-method'} = 'debootstrap';
    $self->{default}->{'xen-options'}->{'size'} = '2Gb';
    $self->{default}->{'xen-options'}->{'memory'} = '512Mb';
    $self->{default}->{'xen-options'}->{'noswap'} = '1';
    $self->{default}->{'xen-options'}->{'fs'} = 'ext3';
    $self->{default}->{'xen-options'}->{'dist'} = 'sarge';
    $self->{default}->{'xen-options'}->{'image'} = 'full';
    $self->{default}->{'xen-options'}->{'kernel'} = 
        '/boot/vmlinuz-`uname -r`';
    $self->{default}->{'xen-options'}->{'initrd'} = 
        '/boot/initrd.img-`uname-r`';
    $self->{default}->{'xen-options'}->{'mirror'} =
        'http://ftp.debian.org/debian';
}

1;

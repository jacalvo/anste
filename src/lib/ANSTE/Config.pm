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
use ANSTE::Exceptions::NotFound;
use ANSTE::Exceptions::MissingConfig;
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

    my $system = $self->_getOption('global', 'system');

    if (not ANSTE::Validate::system($system)) {
        throw ANSTE::Exceptions::NotFound('System', 
                                          $system);
    }

    return $system;
}

sub virtualizer
{
    my ($self) = @_;

    my $virtualizer = $self->_getOption('global', 'virtualizer');

    if (not ANSTE::Validate::virtualizer($virtualizer)) {
        throw ANSTE::Exceptions::NotFound('Virtualizer', 
                                          $virtualizer);
    }

    return $virtualizer;
}

sub imagePath
{
    my ($self) = @_;

    my $imagePath = $self->_getOption('paths', 'images');

    if (not ANSTE::Validate::path($imagePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/images', $imagePath);
    }

    return $imagePath;
}

sub imageTypePath
{
    my ($self) = @_;

    my $imageTypePath = $self->_getOption('paths', 'image-types');

    if (not ANSTE::Validate::path($imageTypePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/image-types', $imageTypePath);
    }

    return $imageTypePath;
}

sub scenarioPath
{
    my ($self) = @_;

    my $scenarioPath = $self->_getOption('paths', 'scenarios');

    if (not ANSTE::Validate::path($scenarioPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/scenarios',
                                               $scenarioPath);
    }

    return $scenarioPath;
}

sub profilePath
{
    my ($self) = @_;

    my $profilePath = $self->_getOption('paths', 'profiles');

    if (not ANSTE::Validate::path($profilePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/profiles',
                                               $profilePath);
    }

    return $profilePath;
}

sub scriptPath
{
    my ($self) = @_;

    my $scriptPath = $self->_getOption('paths', 'scripts');

    if (not ANSTE::Validate::path($scriptPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/scripts',
                                               $scriptPath);
    }

    return $scriptPath;
}

sub testPath
{
    my ($self) = @_;

    my $testPath = $self->_getOption('paths', 'tests');

    if (not ANSTE::Validate::path($testPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/tests', $testPath);
    }

    return $testPath;
}

sub logPath
{
    my ($self) = @_;

    my $logPath = $self->_getOption('paths', 'logs');

    if (not ANSTE::Validate::directoryWritable($logPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/logs', $logPath);
    }

    return $logPath;
}

sub anstedPort
{
    my ($self) = @_;

    my $anstedPort = $self->_getOption('ansted', 'port');

    if (not ANSTE::Validate::port($anstedPort)) {
        throw ANSTE::Exceptions::InvalidConfig('ansted/port',
                                               $anstedPort);
    }
    
    return $anstedPort;
}

sub masterPort
{
    my ($self) = @_;

    my $masterPort = $self->_getOption('master', 'port');

    if (not ANSTE::Validate::port($masterPort)) {
        throw ANSTE::Exceptions::InvalidConfig('master/port',
                                               $masterPort);
    }
    
    return $masterPort;
}

sub firstAddress
{
    my ($self) = @_;

    my $firstAddress =  $self->_getOption('comm', 'first-address');

    if (not ANSTE::Validate::ip($firstAddress)) {
        throw ANSTE::Exceptions::InvalidConfig('first-address', $firstAddress);
    }

    return $firstAddress;
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

sub natIface
{
    my ($self) = @_;

    # TODO: Validate if interface exists??
    my $iface =  $self->_getOption('comm', 'nat-iface');

    return $iface;
}

sub reportWriter
{
    my ($self) = @_;

    my $writer = $self->_getOption('report', 'writer');

    return $writer;
}

sub seleniumRCjar
{
    my ($self) = @_;

    my $jar = $self->_getOption('selenium', 'rc-jar');

    if (not defined $jar) {
        throw ANSTE::Exceptions::MissingConfig('selenium/rc-jar');
    }                                          
    if (not ANSTE::Validate::fileReadable($jar)) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/rc-jar', $jar);
    }

    return $jar;
}

sub seleniumBrowser
{
    my ($self) = @_;

    my $browser = $self->_getOption('selenium', 'browser');

    # TODO: validate browser??
    #
    return $browser;
}

# TODO: validate xen options (maybe they should be in separate class 
# Virtualizer::XenConfig or similar)

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

    # TODO: Some options have to be mandatory and so don't have a default.

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
    $self->{default}->{'comm'}->{'nat-iface'} = 'eth1';

    $self->{default}->{'report'}->{'writer'} = 'Text';

    $self->{default}->{'selenium'}->{'browser'} = '*firefox';
    $self->{default}->{'selenium'}->{'result-path'} = '/tmp';

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

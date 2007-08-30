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
use ANSTE::Exceptions::InvalidOption;
use ANSTE::Exceptions::NotFound;
use ANSTE::Exceptions::MissingConfig;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Validate;

use Config::Tiny;

use constant CONFIG_FILE => 'anste.conf';

my @CONFIG_PATHS = ('/etc/anste', '/usr/local/etc/anste', 'data');
my @DATA_PATHS = ('/usr/share/anste', '/usr/local/share/anste', 'data');

my $singleton;

sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        foreach my $path (@CONFIG_PATHS) {
            my $file = "$path/" . CONFIG_FILE;
            if (-r $file) {
                $self->{config} = Config::Tiny->read($file);
                $self->{confPath} = $path;
                $self->{confFile} = $file;
                last;
            }
        }

        foreach my $path (@DATA_PATHS) {
            if (-d $path) {
                $self->{dataPath} = $path;
                last;
            }
        }
        
        $singleton = bless($self, $class);

        $singleton->_setDefaults();
    }

    return $singleton;
}

sub configPath
{
    my ($self) = @_;

    return $self->{confPath};
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
        throw ANSTE::Exceptions::InvalidConfig('paths/images', 
                                               $imagePath,
                                               $self->{confFile});
    }

    return $imagePath;
}

sub imageTypePath
{
    my ($self) = @_;

    my $imageTypePath = $self->_getOption('paths', 'image-types');

    if (not ANSTE::Validate::path($imageTypePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/image-types',
                                               $imageTypePath,
                                               $self->{confFile});
    }

    return $imageTypePath;
}

sub scenarioPath
{
    my ($self) = @_;

    my $scenarioPath = $self->_getOption('paths', 'scenarios');

    if (not ANSTE::Validate::path($scenarioPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/scenarios',
                                               $scenarioPath,
                                               $self->{confFile});
    }

    return $scenarioPath;
}

sub profilePath
{
    my ($self) = @_;

    my $profilePath = $self->_getOption('paths', 'profiles');

    if (not ANSTE::Validate::path($profilePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/profiles',
                                               $profilePath,
                                               $self->{confFile});
    }

    return $profilePath;
}

sub scriptPath
{
    my ($self) = @_;

    my $scriptPath = $self->_getOption('paths', 'scripts');

    if (not ANSTE::Validate::path($scriptPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/scripts',
                                               $scriptPath,
                                               $self->{confFile});
    }

    return $scriptPath;
}

sub deployPath
{
    my ($self) = @_;

    my $deployPath = $self->_getOption('paths', 'deploy');

    if (not ANSTE::Validate::path($deployPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/deploy',
                                               $deployPath,
                                               $self->{confFile});
    }

    return $deployPath;
}

sub testPath
{
    my ($self) = @_;

    my $testPath = $self->_getOption('paths', 'tests');

    if (not ANSTE::Validate::path($testPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/tests', 
                                               $testPath,
                                               $self->{confFile});
    }

    return $testPath;
}

sub logPath
{
    my ($self) = @_;

    my $logPath = $self->_getOption('paths', 'logs');

    if (not ANSTE::Validate::directoryWritable($logPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/logs',
                                               $logPath,
                                               $self->{confFile});
    }

    return $logPath;
}

sub setLogPath # (logPath)
{
    my ($self, $logPath) = @_;

    defined $logPath or
        throw ANSTE::Exceptions::MissingArgument('logPath');

    if (not ANSTE::Validate::directoryWritable($logPath)) {
        throw ANSTE::Exceptions::InvalidOption('paths/logs', $logPath);
    }

    $self->{override}->{'paths'}->{'logs'} = $logPath;
}

sub anstedPort
{
    my ($self) = @_;

    my $anstedPort = $self->_getOption('ansted', 'port');

    if (not ANSTE::Validate::port($anstedPort)) {
        throw ANSTE::Exceptions::InvalidConfig('ansted/port',
                                               $anstedPort,
                                               $self->{confFile});
    }
    
    return $anstedPort;
}

sub masterPort
{
    my ($self) = @_;

    my $masterPort = $self->_getOption('master', 'port');

    if (not ANSTE::Validate::port($masterPort)) {
        throw ANSTE::Exceptions::InvalidConfig('master/port',
                                               $masterPort,
                                               $self->{confFile});
    }
    
    return $masterPort;
}

sub firstAddress
{
    my ($self) = @_;

    my $firstAddress =  $self->_getOption('comm', 'first-address');

    if (not ANSTE::Validate::ip($firstAddress)) {
        throw ANSTE::Exceptions::InvalidConfig('first-address', 
                                               $firstAddress,
                                               $self->{confFile});
    }

    return $firstAddress;
}

sub gateway
{
    my ($self) = @_;

    my $gateway =  $self->_getOption('comm', 'gateway');

    if (not ANSTE::Validate::ip($gateway)) {
        throw ANSTE::Exceptions::InvalidConfig('gateway', 
                                               $gateway,
                                               $self->{confFile});
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

sub autoCreateImages
{
    my ($self) = @_;

    # TODO: Make this overridable in command line??
    my $auto = $self->_getOption('deploy', 'auto-create-images');

    if (not ANSTE::Validate::boolean($auto)) {
        throw ANSTE::Exceptions::InvalidConfig('deploy/auto-create-images', 
                                               $auto,
                                               $self->{confFile});
    }

    return $auto;
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
        throw ANSTE::Exceptions::InvalidConfig('selenium/rc-jar', 
                                               $jar,
                                               $self->{confFile});
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

sub seleniumVideo
{
    my ($self) = @_;

    my $video = $self->_getOption('selenium', 'video');

    if (not ANSTE::Validate::boolean($video)) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/video',
                                               $video,
                                               $self->{confFile});
    }

    return $video;
}

sub setSeleniumVideo # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('selenium/video', 
                                               $value);
    }

    $self->{override}->{'selenium'}->{'video'} = $value;
}

sub seleniumRecordAll
{
    my ($self) = @_;

    my $all = $self->_getOption('selenium', 'record-all');

    if (not ANSTE::Validate::boolean($all)) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/record-all',
                                               $all,
                                               $self->{confFile});
    }

    return $all;
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

    # First we check if the option has been overriden
    my $overriden = $self->{override}->{$section}->{$option};
    if(defined $overriden) {
        return $overriden;
    }

    # If not we look it in the configuration file
    my $config = $self->{config}->{$section}->{$option};
    if (defined $config) {
        return $config;
    }
    
    # If not in config, return default value.
    return $self->{default}->{$section}->{$option};
}

sub _setDefaults
{
    my ($self) = @_;

    # TODO: Some options have to be mandatory and so don't have a default.
    my $data = $self->{dataPath};

    $self->{default}->{'global'}->{'system'} = 'Debian';
    $self->{default}->{'global'}->{'virtualizer'} = 'Xen';

    $self->{default}->{'paths'}->{'images'} = '/home/xen/domains';
    $self->{default}->{'paths'}->{'image-types'} = "$data/images";
    $self->{default}->{'paths'}->{'scenarios'} = "$data/scenarios";
    $self->{default}->{'paths'}->{'profiles'} = "$data/profiles";
    $self->{default}->{'paths'}->{'scripts'} = "$data/scripts";
    $self->{default}->{'paths'}->{'deploy'} = "$data/deploy";

    $self->{default}->{'ansted'}->{'port'} = '8000';

    $self->{default}->{'master'}->{'port'} = '8001';

    $self->{default}->{'comm'}->{'ip-range'} = '192.168.0';
    $self->{default}->{'comm'}->{'gateway'} = '192.168.0.1';
    $self->{default}->{'comm'}->{'nat-iface'} = 'eth1';
    $self->{default}->{'comm'}->{'first-address'} = '192.168.0.191';

    $self->{default}->{'deploy'}->{'auto-create-images'} = 0;

    $self->{default}->{'report'}->{'writer'} = 'Text';

    $self->{default}->{'selenium'}->{'browser'} = '*firefox';
    $self->{default}->{'selenium'}->{'result-path'} = '/tmp';
    $self->{default}->{'selenium'}->{'video'} = 0;
    $self->{default}->{'selenium'}->{'record-all'} = 0;

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

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

# Class: Config
#
#   Contains the values read from the config file as long as
#   the default and overriden (by commandline options) ones.
#

use constant CONFIG_FILE => 'anste.conf';

my @CONFIG_PATHS = ('data/conf', '/etc/anste', '/usr/local/etc/anste');
my @DATA_PATHS = ('data', '/usr/share/anste', '/usr/local/share/anste');

my $singleton;

# Method: instance
#
#   Returns a reference to the singleton object of this class
#
# Returns:
#
#   ref - the class unique instance of type <ANSTE::Config>.
#
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

# Method: check
#
#   Tries to get all the options to validate them.
#   An exception is thrown if there's an invalid option.
#
# Returns:
#
#   boolean - true if all the options are correct.
#
# Exceptions:
#
#   Different exceptions can be thrown depending of the wrong option.
#
sub check
{
    my ($self) = @_;

    $self->system();
    $self->virtualizer();
    $self->verbose();
    $self->imagePath();
    $self->logPath();
    $self->deployPath();
    $self->templatePath();
    $self->anstedPort();
    $self->masterPort();
    $self->firstAddress();
    $self->gateway();
    $self->natIface();
    $self->autoCreateImages();
    $self->seleniumRCjar();
    $self->seleniumBrowser();
    $self->seleniumVideo();
    $self->seleniumRecordAll();
    $self->xenInstallMethod();
    $self->xenUseIdeDevices();
    $self->xenModules();
    $self->xenSize();
    $self->xenMemory();
    $self->xenNoSwap();
    $self->xenFS();
    $self->xenDist();
    $self->xenImage();
    $self->xenKernel();
    $self->xenInitrd();
    $self->xenMirror();
    
    return 1;
}

# Method: configPath
#
#   Gets the path of the used config file to read the values.
#
# Returns:
#
#   string - String with the path to the configuration file.
#
sub configPath
{
    my ($self) = @_;

    return $self->{confPath};
}

# Method: setUserPath
#
#   Sets an user data path alternative to the default data path.
#
# Parameters:
#
#   path - String with the path to use.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
sub setUserPath # (path)
{
    my ($self, $path) = @_;

    defined $path or
        throw ANSTE::Exceptions::MissingArgument('path');

    if (not ANSTE::Validate::path($path)) {
        throw ANSTE::Exceptions::InvalidOption('path', $path);
    }

    $self->{userPath} = $path;
}

# Method: system
#
#   Gets the value for the system option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::NotFound> - throw if system is not found
#
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

# Method: virtualizer
#
#   Gets the value for the virtualizer option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::NotFound> - throw if virtualizer is not found
#
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

# Method: verbose
#
#   Gets the value for the verbose option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub verbose
{
    my ($self) = @_;

    my $verbose = $self->_getOption('global', 'verbose');

    if (not ANSTE::Validate::boolean($verbose)) {
        throw ANSTE::Exceptions::InvalidConfig('global/verbose', 
                                               $verbose,
                                               $self->{confFile});
    }

    return $verbose;
}

# Method: setVerbose
#
#   Sets the value for the verbose option.
#
# Parameters:
#
#   value - String with the value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
sub setVerbose # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('global/verbose', 
                                               $value);
    }

    $self->{override}->{'global'}->{'verbose'} = $value;
}

# Method: imagePath
#
#   Gets the value for the images' path option. 
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: logPath
#
#   Gets the value for the logs' path option. 
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: setLogPath
#
#   Sets the value for the logs' path option.
#
# Parameters:
#
#   value - String with the value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
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

# Method: deployPath
#
#   Gets the value for the deploy path option. 
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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


# Method: imageTypeFile
#
#   Gets the full path of a given image file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub imageTypeFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("images/$file");
}

# Method: scenarioFile
#
#   Gets the full path of a given scenario file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub scenarioFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("scenarios/$file");
}

# Method: profileFile
#
#   Gets the full path of a given profile file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub profileFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("profiles/$file");
}

# Method: scriptFile
#
#   Gets the full path of a given script file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub scriptFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("scripts/$file");
}


# Method: testFile
#
#   Gets the full path of a given test file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub testFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("tests/$file");
}

# Method: templatePath
#
#   Gets the value for the templates' path option. 
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub templatePath
{
    my ($self) = @_;

    my $templatePath = $self->_getOption('paths', 'templates');

    if (not ANSTE::Validate::path($templatePath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/templates', 
                                               $templatePath,
                                               $self->{confFile});
    }

    return $templatePath;
}

# Method: anstedPort
#
#   Gets the value for the ansted listen port option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: masterPort
#
#   Gets the value for the master listen port option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: firstAddress
#
#   Gets the value for the starting IP address option for the virtual
#   machines.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: gateway
#
#   Gets the value for the default gateway option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: natIface
#
#   Gets the value for the outgoing NAT interface option.
#
# Returns:
#
#   string - Value for the option.
#
sub natIface
{
    my ($self) = @_;

    # TODO: Validate if interface exists??
    my $iface =  $self->_getOption('comm', 'nat-iface');

    return $iface;
}

# Method: autoCreateImages
#
#   Gets the value for the auto-create-images option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: seleniumRCjar
#
#   Gets the value for the path selenium-rc jar option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingConfig> - throw if option is missing
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: seleniumBrowser
#
#   Gets the value for the Selenium browser option.
#
# Returns:
#
#   string - Value for the option.
#
sub seleniumBrowser
{
    my ($self) = @_;

    my $browser = $self->_getOption('selenium', 'browser');

    # TODO: validate browser??
    #
    return $browser;
}

# Method: seleniumVideo
#
#   Gets the value for the Selenium video recording option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: setSeleniumVideo
#
#   Sets the value for the Selenium video recording option.
#
# Parameters:
#
#   value - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present 
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
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

# Method: seleniumRecordAll
#
#   Gets the value for the Selenium record all videos option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
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

# Method: xenInstallMethod
#
#   Gets the value of the Xen's install-method option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenInstallMethod
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'install-method');
}

# Method: xenUseIdeDevices
#
#
#   Gets the value of the Xen's use-ide-devices option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenUseIdeDevices
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'use-ide-devices');
}

# Method: xenModules
#
#
#   Gets the value of the Xen's modules option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenModules
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'modules');
}

# Method: xenSize
#
#
#   Gets the value of the Xen's size option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenSize
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'size');
}

# Method: xenMemory
#
#   Gets the value of the Xen's memory option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenMemory
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'memory');
}

# Method: xenNoSwap
#
#   Gets the value of the Xen's noswap option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenNoSwap
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'noswap');
}

# Method: xenFS
#
#   Gets the value of the Xen's fs option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenFS
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'fs');
}

# Method: xenDist
#
#   Gets the value of the Xen's dist option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenDist
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'dist');
}

# Method: xenImage
#
#   Gets the value of the Xen's image option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenImage
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'image');
}

# Method: xenKernel
#
#   Gets the value of the Xen's kernel option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenKernel
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'kernel');
}

# Method: xenInitrd
#
#   Gets the value of the Xen's initrd option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenInitrd
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'initrd');
}

# Method: xenMirror
#
#   Gets the value of the Xen's mirror option.
#
# Returns:
#
#   string - Value for the option.
#
sub xenMirror
{
    my ($self) = @_;

    return $self->_getOption('xen-options', 'mirror');
}

sub _filePath # (file)
{
    my ($self, $file) = @_;

    my $data = $self->{dataPath};
    my $user = $self->{userPath};

    if ($user) {
        my $userFile = "$user/$file";
        if (-r $userFile) {
            return $userFile;
        }
    }
    else {
        my $dataFile = "$data/$file";
        return $dataFile;
    }
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

    my $data = $self->{dataPath};

    $self->{default}->{'global'}->{'system'} = 'Debian';
    $self->{default}->{'global'}->{'virtualizer'} = 'Xen';
    $self->{default}->{'global'}->{'verbose'} = 1;

    $self->{default}->{'paths'}->{'images'} = '/home/xen/domains';
    $self->{default}->{'paths'}->{'deploy'} = "$data/deploy";
    $self->{default}->{'paths'}->{'templates'} = "$data/templates";

    $self->{default}->{'ansted'}->{'port'} = '8000';

    $self->{default}->{'master'}->{'port'} = '8001';

    $self->{default}->{'comm'}->{'gateway'} = '192.168.0.62';
    $self->{default}->{'comm'}->{'nat-iface'} = 'eth1';
    $self->{default}->{'comm'}->{'first-address'} = '192.168.0.191';

    $self->{default}->{'deploy'}->{'auto-create-images'} = 0;

    $self->{default}->{'selenium'}->{'browser'} = '*firefox';
    $self->{default}->{'selenium'}->{'video'} = 0;
    $self->{default}->{'selenium'}->{'record-all'} = 0;

    $self->{default}->{'xen-options'}->{'dir'} = '/home/xen';
    $self->{default}->{'xen-options'}->{'install-method'} = 'debootstrap';
    $self->{default}->{'xen-options'}->{'use-ide-devices'} = 0;
    $self->{default}->{'xen-options'}->{'modules'} = '';
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

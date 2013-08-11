# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::InvalidConfig;
use ANSTE::Exceptions::InvalidOption;
use ANSTE::Exceptions::NotFound;
use ANSTE::Exceptions::MissingConfig;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Validate;

use Config::Tiny;
use IO::Interface::Simple;

# Class: Config
#
#   Contains the values read from the config file as long as
#   the default and overriden (by commandline options) ones.
#

use constant CONFIG_FILE => 'anste.conf';

my @CONFIG_PATHS = ('conf', 'data/conf', '/etc/anste', '/usr/local/etc/anste');
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
                if (defined $self->{config}) {
                    my $stackedConfig = Config::Tiny->read($file);

                    foreach my $section (keys %{$stackedConfig}) {
                        foreach my $key (keys %{$stackedConfig->{$section}}) {
                            my $value = $stackedConfig->{$section}->{$key};
                            my $oldValue = $self->{config}->{$section}->{$key};
                            unless (defined $oldValue) {
                                $self->{config}->{$section}->{$key} = $value;
                            }
                        }
                    }
                } else {
                    $self->{config} = Config::Tiny->read($file);
                    $self->{confPath} = $path;
                    $self->{confFile} = $file;
                }
            }
        }

        unless (defined $self->{config}) {
            throw ANSTE::Exceptions::Error('Unable to find anste.conf');
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
    $self->wait();
    $self->waitFail();
    $self->imagePath();
    $self->logPath();
    $self->deployPath();
    $self->templatePath();
    $self->anstedPort();
    $self->masterPort();
    $self->firstAddress();
    $self->gateway();
    $self->natIface();
    $self->nameserverHost();
    $self->nameserver();
    $self->autoCreateImages();
    $self->vmBuilderMirror();
    $self->seleniumRCjar();
    $self->seleniumBrowser();
    $self->seleniumVideo();
    $self->seleniumRecordAll();
    $self->seleniumProtocol();
    $self->seleniumFirefoxProfile();
    $self->seleniumSingleWindow();
    $self->seleniumUserExtensions();
    $self->virtSize();
    $self->virtMemory();

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

# Method: formats
#
#   Gets the list of values for the format option.
#
# Returns:
#
#   arrayref - Values for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::NotFound> - throw if format is not found
#
sub formats
{
    my ($self) = @_;

    return $self->{format};
}

# Method: setFormat
#
#   Sets the format to be used in the report writing.
#
# Parameters:
#
#   format - String with the name of the format.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
sub setFormat # (format)
{
    my ($self, $format) = @_;

    defined $format or
        throw ANSTE::Exceptions::MissingArgument('format');

    my @formats = split (',', $format);
    foreach my $f (@formats) {
        if (not ANSTE::Validate::format($f)) {
            throw ANSTE::Exceptions::InvalidOption('format', $f);
        }
    }

    $self->{format} = \@formats;
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

# Method: wait
#
#   Gets the value for the wait option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub wait
{
    my ($self) = @_;

    my $wait = $self->_getOption('global', 'wait');

    if (not ANSTE::Validate::boolean($wait)) {
        throw ANSTE::Exceptions::InvalidConfig('global/wait',
                                               $wait,
                                               $self->{confFile});
    }

    return $wait;
}

# Method: setWait
#
#   Sets the value for the wait option.
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
sub setWait # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('global/wait',
                                               $value);
    }

    $self->{override}->{'global'}->{'wait'} = $value;
}

# Method: waitFail
#
#   Gets the value for the waitFail option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub waitFail
{
    my ($self) = @_;

    my $waitFail = $self->_getOption('global', 'wait-fail');

    if (not ANSTE::Validate::boolean($waitFail)) {
        throw ANSTE::Exceptions::InvalidConfig('global/wait-fail',
                                               $waitFail,
                                               $self->{confFile});
    }

    return $waitFail;
}

# Method: setWaitFail
#
#   Sets the value for the wait-fail option.
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
sub setWaitFail # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('global/wait-fail',
                                               $value);
    }

    $self->{override}->{'global'}->{'wait-fail'} = $value;
}

# Method: reuse
#
#   Gets the value for the reuse option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub reuse
{
    my ($self) = @_;

    my $reuse = $self->_getOption('global', 'reuse');

    if (not ANSTE::Validate::boolean($reuse)) {
        throw ANSTE::Exceptions::InvalidConfig('global/reuse',
                                               $reuse,
                                               $self->{confFile});
    }

    return $reuse;
}

# Method: setReuse
#
#   Sets the value for the reuse option.
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
sub setReuse # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('global/reuse',
                                               $value);
    }

    $self->{override}->{'global'}->{'reuse'} = $value;
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
        mkdir $imagePath or
            throw ANSTE::Exceptions::InvalidConfig('paths/images',
                                                   $imagePath,
                                                   $self->{confFile});
    }

    return $imagePath;
}

# Method: setImagePath
#
#   Sets the value for the images' path option.
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
sub setImagePath
{
    my ($self, $imagePath) = @_;

    defined $imagePath or
        throw ANSTE::Exceptions::MissingArgument('imagePath');

    unless (-w $imagePath) {
        throw ANSTE::Exceptions::InvalidOption('paths/images', $imagePath);
    }

    $self->{override}->{'paths'}->{'images'} = $imagePath;
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

# Method: snapshotsPath
#
#   Gets the value for the snapshotss' path option.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub snapshotsPath
{
    my ($self) = @_;

    my $snapshotsPath = $self->_getOption('paths', 'snapshots');

    if (not ANSTE::Validate::directoryWritable($snapshotsPath)) {
        throw ANSTE::Exceptions::InvalidConfig('paths/snapshots',
                                               $snapshotsPath,
                                               $self->{confFile});
    }

    return $snapshotsPath;
}

# Method: setSnapshotsPath
#
#   Sets the value for the snapshots path option.
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
sub setSnapshotsPath
{
    my ($self, $snapshotsPath) = @_;

    defined $snapshotsPath or
        throw ANSTE::Exceptions::MissingArgument('snapshotsPath');

    if (not ANSTE::Validate::directoryWritable($snapshotsPath)) {
        throw ANSTE::Exceptions::InvalidOption('paths/snapshots', $snapshotsPath);
    }

    $self->{override}->{'paths'}->{'snapshots'} = $snapshotsPath;
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

# Method: listsFile
#
#   Gets the full path of a given list file name.
#
# Parameters:
#
#   file - String with the file name.
#
# Returns:
#
#   string - The full path of the file.
#
sub listsFile # (file)
{
    my ($self, $file) = @_;

    return $self->_filePath("files/$file");
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

# Method: commIface
#
#   Gets the value for the name of the internal communication interface.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub commIface
{
    my ($self) = @_;

    my $iface =  $self->_getOption('comm', 'iface');

    if (not ANSTE::Validate::identifier($iface)) {
        throw ANSTE::Exceptions::InvalidConfig('iface',
                                               $iface,
                                               $self->{confFile});
    }

    return $iface;
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

sub nameserverHost
{
    my ($self) = @_;

    my $nameserver =  $self->_getOption('comm', 'nameserver-host');

    if (not ANSTE::Validate::ip($nameserver)) {
        throw ANSTE::Exceptions::InvalidConfig('nameserver-host',
                                               $nameserver,
                                               $self->{confFile});
    }

    return $nameserver;
}

sub nameserver
{
    my ($self) = @_;

    my $nameserver =  $self->_getOption('comm', 'nameserver');

    if (not ANSTE::Validate::ip($nameserver)) {
        throw ANSTE::Exceptions::InvalidConfig('nameserver',
                                               $nameserver,
                                               $self->{confFile});
    }

    return $nameserver;
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

    if (defined $jar and not ANSTE::Validate::fileReadable($jar)) {
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

# Method: seleniumProtocol
#
#   Gets the value for the default Selenium protocol (http or https)
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub seleniumProtocol
{
    my ($self) = @_;

    my $protocol = $self->_getOption('selenium', 'protocol');

    unless (($protocol eq 'http') or ($protocol eq 'https')) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/protocol',
                                               $protocol,
                                               $self->{confFile});
    }

    return $protocol;
}

# Method: seleniumFirefoxProfile
#
#   Gets the value for the path to custom firefox profile
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub seleniumFirefoxProfile
{
    my ($self) = @_;

    my $profile = $self->_getOption('selenium', 'firefox-profile');

    if ($profile and (not ANSTE::Validate::path($profile))) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/firefox-profile',
                                               $profile,
                                               $self->{confFile});
    }

    return $profile;
}

# Method: seleniumSingleWindow
#
#   Selenium runs the browser in only a window, incompatible with frames
#
# Returns:
#
#   value - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub seleniumSingleWindow
{
    my ($self) = @_;

    my $singleWindow = $self->_getOption('selenium', 'single-window');

    if (not ANSTE::Validate::boolean($singleWindow)) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/single-window',
                                               $singleWindow,
                                               $self->{confFile});
    }

    return $singleWindow;
}

# Method: seleniumUserExtensions
#
#   Gets the value for the path to user extensions for Selenium
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub seleniumUserExtensions
{
    my ($self) = @_;

    my $userExtensions = $self->_getOption('selenium', 'user-extensions');

    if ($userExtensions and
        (not ANSTE::Validate::fileReadable($userExtensions))) {
        throw ANSTE::Exceptions::InvalidConfig('selenium/user-extensions',
                                               $userExtensions,
                                               $self->{confFile});
    }

    return $userExtensions;
}

# Method: step
#
#   Sets the value for step-by-step testing mode.
#
# Returns:
#
#   string - Value for the option.
#
# Exceptions:
#
#   <ANSTE::Exceptions::InvalidConfig> - throw if option is not valid
#
sub step
{
    my ($self) = @_;

    my $video = $self->_getOption('test', 'step');

    if (not ANSTE::Validate::boolean($video)) {
        throw ANSTE::Exceptions::InvalidConfig('test/step',
                                               $video,
                                               $self->{confFile});
    }

    return $video;
}

# Method: setStep
#
#   Sets the value for step-by-step testing mode.
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
sub setStep # (value)
{
    my ($self, $value) = @_;

    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::boolean($value)) {
        throw ANSTE::Exceptions::InvalidOption('test/step',
                                               $value);
    }

    $self->{override}->{'test'}->{'step'} = $value;
}

# Method: vmBuilderMirror
#
#   Gets the value of the mirror to use when generating the images with vm-builder.
#
# Returns:
#
#   string - Value for the option.
#
sub vmBuilderMirror
{
    my ($self) = @_;

    return $self->_getOption('vm-builder-options', 'mirror');
}

# Method: virtSize
#
#
#   Gets the value of the Xen's size option.
#
# Returns:
#
#   string - Value for the option.
#
sub virtSize
{
    my ($self) = @_;

    return $self->_getOption('virt-options', 'size');
}

# Method: virtMemory
#
#   Gets the value of the Xen's memory option.
#
# Returns:
#
#   string - Value for the option.
#
sub virtMemory
{
    my ($self) = @_;

    return $self->_getOption('virt-options', 'memory');
}

# Method: setVariable
#
#   Sets a variable to be substituted on the XML files.
#
# Parameters:
#
#   name  - Contains the name of the variable.
#   value - Contains the value of the variable.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
sub setVariable # (name, value)
{
    my ($self, $name, $value) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');
    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::identifier($name)) {
        throw ANSTE::Exceptions::InvalidOption('name', $name);
    }

    $self->{variables}->{$name} = $value;
}

# Method: variables
#
#   Gets the variables to be substituted on the XML files.
#
# Returns:
#
#   hash ref - Reference to the hash of variables
#
sub variables
{
    my ($self) = @_;

    return $self->{variables};
}

# Method: env
#
#   Gets the ANSTE_* environment variables to be passed to setup scripts
#
# Returns:
#
#   string - With the form "VAR1=VAL1 VAR2=VAL2 ..."
#
sub env
{
    my ($self) = @_;

    my @keys = grep { /^ANSTE_/ } keys %ENV;

    my $env = '';
    foreach my $key (@keys) {
        $env .= "$key=\"$ENV{$key}\" ";
    }
    chop ($env);

    return $env;
}



# Method: setBreakpoint
#
#   Sets a breakpoint after a test.
#
# Parameters:
#
#   name  - Contains the name of the test.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub setBreakpoint # (name)
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    $self->{breakpoints}->{$name} = 1;
}

# Method: breakpoint
#
#   Get if there is a breakpoint for the given test name.
#
# Returns:
#
#   true  - if there is a breakpoint for the test
#   undef - otherwise
#
sub breakpoint # (name)
{
    my ($self, $name) = @_;

    return $self->{breakpoints}->{$name};
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
    my $dataFile = "$data/$file";
    return $dataFile;
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
    $self->{format} = [ 'HTML' ];

    $self->{default}->{'global'}->{'system'} = 'Debian';
    $self->{default}->{'global'}->{'virtualizer'} = 'Virt';
    $self->{default}->{'global'}->{'verbose'} = 1;
    $self->{default}->{'global'}->{'wait'} = 0;
    $self->{default}->{'global'}->{'wait-fail'} = 0;
    $self->{default}->{'global'}->{'reuse'} = 0;

    $self->{default}->{'paths'}->{'images'} = '/tmp/images';
    $self->{default}->{'paths'}->{'deploy'} = "$data/deploy";
    $self->{default}->{'paths'}->{'templates'} = "$data/templates";

    $self->{default}->{'ansted'}->{'port'} = '8000';

    $self->{default}->{'master'}->{'port'} = '8001';

    $self->{default}->{'comm'}->{'gateway'} = '10.6.7.1';
    $self->{default}->{'comm'}->{'iface'} = 'anste0';

    my $natIface = undef;
    foreach my $iface ('eth0', 'wlan0') {
        my $if = IO::Interface::Simple->new($iface);
        if ($if->address) {
            $natIface = $iface;
            last;
        }
    }
    $self->{default}->{'comm'}->{'nat-iface'} = $natIface;

    $self->{default}->{'comm'}->{'first-address'} = '10.6.7.10';

    my $nameserver = `grep ^nameserver /etc/resolv.conf | head -1 | cut -d' ' -f2`;
    chomp ($nameserver);
    if ((not $nameserver) or ($nameserver =~ /^127\.0/)) {
        $nameserver = '8.8.8.8';
    }
    $self->{default}->{'comm'}->{'nameserver-host'} = $nameserver;
    $self->{default}->{'comm'}->{'nameserver'} = $nameserver;

    $self->{default}->{'deploy'}->{'auto-create-images'} = 0;

    $self->{default}->{'selenium'}->{'browser'} = '*firefox';
    $self->{default}->{'selenium'}->{'video'} = 0;
    $self->{default}->{'selenium'}->{'record-all'} = 0;
    $self->{default}->{'selenium'}->{'protocol'} = 'http';
    $self->{default}->{'selenium'}->{'firefox-profile'} = '';
    $self->{default}->{'selenium'}->{'single-window'} = 0;
    $self->{default}->{'selenium'}->{'user-extensions'} =
        "$data/scripts/user-extensions.js";

    $self->{default}->{'test'}->{'step'} = 0;

    $self->{default}->{'virt-options'}->{'size'} = '2200';
    $self->{default}->{'virt-options'}->{'memory'} = '512';

    my $dist = $self->{config}->{'global'}->{'dist'};
    unless ($dist) {
        $dist = 'lucid';
    }
    # Default values for variables, overridable by commandline option
    $self->{variables} = {dist => $dist};

    # Breakpoints
    $self->{breakpoints} = {};
}

1;

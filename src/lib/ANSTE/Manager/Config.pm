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

package ANSTE::Manager::Config;

use strict;
use warnings;

use ANSTE::Exceptions::InvalidConfig;
use ANSTE::Exceptions::InvalidOption;
use ANSTE::Exceptions::NotFound;
use ANSTE::Exceptions::MissingConfig;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Validate;

use Config::Tiny;

use constant CONFIG_FILE => 'anste-manager.conf';

my @CONFIG_PATHS = ('data/conf', '/etc/anste', '/usr/local/etc/anste');

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

sub listenPort
{
    my ($self) = @_;

    my $listenPort = $self->_getOption('listen', 'port');

    if (not ANSTE::Validate::port($listenPort)) {
        throw ANSTE::Exceptions::InvalidConfig('listen/port',
                                               $listenPort,
                                               $self->{confFile});
    }
    
    return $listenPort;
}

sub executionLog
{
    my ($self) = @_;

    my $executionLog = $self->_getOption('logs', 'execution');

    if (not ANSTE::Validate::directoryWritable($executionLog)) {
        throw ANSTE::Exceptions::InvalidConfig('logs/execution',
                                               $executionLog,
                                               $self->{confFile});
    }

    return $executionLog;
}

sub resultLog
{
    my ($self) = @_;

    my $resultLog = $self->_getOption('logs', 'result');

    if (not ANSTE::Validate::directoryWritable($resultLog)) {
        throw ANSTE::Exceptions::InvalidConfig('logs/result',
                                               $resultLog,
                                               $self->{confFile});
    }

    return $resultLog;
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


# Overriden method
sub _setDefaults
{
    my ($self) = @_;

    # TODO: Some options have to be mandatory and so don't have a default.
    $self->{default}->{'listen'}->{'port'} = '8666';

    $self->{default}->{'logs'}->{'execution'} = '/tmp/anste-out';
    $self->{default}->{'logs'}->{'result'} = '/tmp/anste-logs';
}

1;

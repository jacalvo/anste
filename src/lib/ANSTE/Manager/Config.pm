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

# Method: instance
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
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
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub check
{
    my ($self) = @_;

    $self->clientPort();
    $self->adminPort();
    $self->mailAddress();
    $self->mailSmtp();
    $self->mailSubject();
    $self->mailTemplate();
    $self->mailTemplateFailed();
    $self->wwwDir();
    $self->wwwHost();

    return 1;
}

# Method: configPath
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub configPath
{
    my ($self) = @_;

    return $self->{confPath};
}

# Method: clientPort
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub clientPort
{
    my ($self) = @_;

    my $clientPort = $self->_getOption('client', 'port');

    if (not ANSTE::Validate::port($clientPort)) {
        throw ANSTE::Exceptions::InvalidConfig('client/port',
                                               $clientPort,
                                               $self->{confFile});
    }
    
    return $clientPort;
}

# Method: adminPort
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub adminPort
{
    my ($self) = @_;

    my $adminPort = $self->_getOption('admin', 'port');

    if (not ANSTE::Validate::port($adminPort)) {
        throw ANSTE::Exceptions::InvalidConfig('admin/port',
                                               $adminPort,
                                               $self->{confFile});
    }
    
    return $adminPort;
}

# Method: mailAddress
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub mailAddress 
{
    my ($self) = @_;

    my $email = $self->_getOption('mail', 'address');

    if (not ANSTE::Validate::email($email)) {
        throw ANSTE::Exceptions::InvalidConfig('mail/address',
                                               $email,
                                               $self->{confFile});
    }
    
    return $email;
}

# Method: mailSmtp
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub mailSmtp
{
    my ($self) = @_;

    my $smtp = $self->_getOption('mail', 'smtp');

    if (not ANSTE::Validate::host($smtp)) {
        throw ANSTE::Exceptions::InvalidConfig('mail/stmp',
                                               $smtp,
                                               $self->{confFile});
    }
    
    return $smtp;
}

# Method: mailSubject
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub mailSubject
{
    my ($self) = @_;

    my $subject = $self->_getOption('mail', 'subject');

    if (not $subject) {
        throw ANSTE::Exceptions::InvalidConfig('mail/subject',
                                               $subject,
                                               $self->{confFile});
    }
    
    return $subject;
}

# Method: mailTemplate
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub mailTemplate
{
    my ($self) = @_;

    my $template = $self->_getOption('mail', 'template');

    if (not ANSTE::Validate::template($template)) {
        throw ANSTE::Exceptions::InvalidConfig('mail/template',
                                               $template,
                                               $self->{confFile});
    }
    
    return $template;
}

# Method: mailTemplateFailed
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub mailTemplateFailed
{
    my ($self) = @_;

    my $template = $self->_getOption('mail', 'failtemplate');

    if (not ANSTE::Validate::template($template)) {
        throw ANSTE::Exceptions::InvalidConfig('mail/failtemplate',
                                               $template,
                                               $self->{confFile});
    }
    
    return $template;
}

# Method: wwwDir
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub wwwDir
{
    my ($self) = @_;

    my $dir = $self->_getOption('www', 'dir');

    if (not ANSTE::Validate::path($dir)) {
        throw ANSTE::Exceptions::InvalidConfig('www/dir',
                                               $dir,
                                               $self->{confFile});
    }
    
    return $dir;
}

# Method: wwwHost
#
#
#
# Parameters:
#
#
# Returns:
#
#
#
# Exceptions:
#
#
#
sub wwwHost
{
    my ($self) = @_;

    my $host = $self->_getOption('www', 'host');

    if (not ANSTE::Validate::host($host)) {
        throw ANSTE::Exceptions::InvalidConfig('www/host',
                                               $host,
                                               $self->{confFile});
    }
    
    return $host;
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
    $self->{default}->{'client'}->{'port'} = '8666';

    $self->{default}->{'admin'}->{'port'} = '8777';

    $self->{default}->{'mail'}->{'address'} = 'anste-noreply@foo.bar';
    $self->{default}->{'mail'}->{'smtp'} = 'localhost';
    $self->{default}->{'mail'}->{'subject'} = 'ANSTE Job Notification';
    $self->{default}->{'mail'}->{'template'} = 'mail.tmpl';
    $self->{default}->{'mail'}->{'failtemplate'} = 'failmail.tmpl';

    $self->{default}->{'www'}->{'host'} = 'localhost';
    $self->{default}->{'www'}->{'dir'} = '/var/www/anste';
}

1;

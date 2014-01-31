# Copyright (C) 2014 Rubén Durán Balda <rduran@zentyal.com>
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

package ANSTE::Virtualizer::OpenStack;

use base 'ANSTE::Virtualizer::Virtualizer';

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::NotImplemented;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::MissingConfig;
use Net::OpenStack::Networking;

# Class: OpenStack
#
#   Implementation of the Virtualizer class that interacts with OpenStack
#

# Constructor: new
#
#   Constructor for Virtualizer class and his derivated classes.
#
# Returns:
#
#   A recently created <ANSTE::Virtualizer::Virtualizer> object
#
sub new
{
    my ($class) = @_;

    my $self = $class->SUPER::new();

    my $config = ANSTE::Config->instance();
    my $user = $config->_getOption('virtualizer', 'user');
    unless (defined $user) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/user');
    }

    my $password = $config->_getOption('virtualizer', 'password');
    unless (defined $password) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/password');
    }

    my $url = $config->_getOption('virtualizer', 'url');
    unless (defined $url) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/url');
    }
    my $project_id = $config->_getOption('virtualizer', 'project_id');
    unless (defined $project_id) {
        throw ANSTE::Exceptions::MissingConfig('virtualizer/project_id');
    }

    $self->{os_networking} = Net::OpenStack::Networking->new(
                                auth_url    => $url,
                                user        => $user,
                                password    => $password,
                                project_id  => $project_id,
                            );

    # FIXME: REMOVE
    print "\n\nFOO\n\n";
    use Data::Dumper;
    print Dumper($self->{os_networking}->create_network({'name' => 'os'}));
    print "\n\nBar\n\n";

    bless($self, $class);

    return $self;
}

# Method: createNetwork
#
#   Overridden method that .........TODO........ for the network of the given scenario.
#
# Parameters:
#
#   scenario   - a <ANSTE::Scenario::Scenario> object
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType>     - throw if argument has invalid type
#
sub createNetwork
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw ANSTE::Exceptions::InvalidType('scenario',
                                            'ANSTE::Scenario::Scenario');
    }

    #TODO
}

# Method: destroyNetwork
#
#   Overridden method that destroy previously created ....TODO.... for the network of the given scenario.
#
# Parameters:
#
#   scenario   - a <ANSTE::Scenario::Scenario> object
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidType>     - throw if argument has invalid type
#
sub destroyNetwork
{
    my ($self, $scenario) = @_;

    defined $scenario or
        throw ANSTE::Exceptions::MissingArgument('scenario');

    if (not $scenario->isa('ANSTE::Scenario::Scenario')) {
        throw ANSTE::Exceptions::InvalidType('scenario',
                                            'ANSTE::Scenario::Scenario');
    }

    # TODO
}

1;


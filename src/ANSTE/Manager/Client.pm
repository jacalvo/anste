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

package ANSTE::Manager::Client;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;

use SOAP::Lite; # +trace => 'debug'; 

use constant URI => 'urn:ANSTE::Manager::Server';

# Class: Client
#
#   Client used to send jobs to anste-manager.
#

# Constructor: new
#
#   Constructor for Client class.
#
# Returns:
#
#   A recently created <ANSTE::Manager::Client> object.
#
sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{soap} = undef;

    bless $self, $class;

    return $self;
}

# Method: connect
#
#   Initialize the object used to send the commands with
#   the location of the server.
#
# Parameters:
#
#   url - URL of the server.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub connect	# (host) 
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $self->{soap} = new SOAP::Lite(uri => URI,
                                   proxy => $host,
                                   endpoint => $host); 
}

# Method: connected
#
#   Check if the client is connected.
#
# Returns:
#
#   boolean - true if the client have a valid connection with the server
#
sub connected # returns boolean
{
    my ($self) = @_;

    return defined($self->{soap});
}

# Method: addJob
#
#   Sends an add job command to the server.
#
# Parameters:
#
#   user - String with the name of the user that sends the job.
#   test - String with the name of the test to be executed.
#   mail - *optional* String with the address where the user will be notified.
#   path - *optional* String with the path of the user tests.
#
# Returns:
#
#   boolean - true if server response is OK, false otherwise
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub addJob # (params) returns boolean
{
    my ($self, %params) = @_;

    defined $params{user} or
        throw ANSTE::Exceptions::MissingArgument('user');
    defined $params{test} or
        throw ANSTE::Exceptions::MissingArgument('test');

    my $user = $params{user};        
    my $test = $params{test};
    my $mail = $params{mail};
    my $path = $params{path};

    my $soap = $self->{soap};

    my $response = $soap->addJob(SOAP::Data->name('user' => $user),
                                 SOAP::Data->name('test' => $test),
                                 SOAP::Data->name('mail' => $mail),
                                 SOAP::Data->name('path' => $path));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

1;

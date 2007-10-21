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

package ANSTE::Comm::SlaveClient;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;

use SOAP::Lite; # +trace => 'debug'; 
use Net::Domain qw(hostname);

use constant URI => "urn:ANSTE::Comm::MasterServer";

# Class: SlaveClient
#   
#   Client that runs on the slave hosts and sends notifications
#   to the master host.
#

# Constructor: new
#
#   Constructor for SlaveClient class.
#
# Returns:
#
#   A recently created <ANSTE::Comm::SlaveClient> object.
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
sub connect	# (url) 
{
    my ($self, $url) = @_;

    defined $url or
        throw ANSTE::Exceptions::MissingArgument('url');

    $self->{soap} = new SOAP::Lite(uri => URI,
                                   proxy => $url,
                                   endpoint => $url); 
}

# Method: hostReady
#
#   Notifies to the master server that this host is ready.
#
# Returns:
#
#   boolean - true if the server response is OK, false otherwise
#
sub hostReady
{
    my ($self) = @_;

    my $soap = $self->{soap};

    my $hostname = hostname(); 

    my $response = $soap->hostReady(SOAP::Data->name('host' => $hostname)); 
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

# Method: executionFinished
#
#   Notifies to the master server that this host has finished
#   its script execution with the given value.
#
# Parameters:
#
#   retValue - Integer with the return value of the script.
#
# Returns:
#
#   boolean - true if the server response is OK, false otherwise
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument not present
#
sub executionFinished # (retValue)
{
    my ($self, $retValue) = @_;

    defined $retValue or
        throw ANSTE::Exceptions::MissingArgument('retValue');

    my $soap = $self->{soap};

    my $host = hostname(); 

    my $response = 
        $soap->executionFinished(SOAP::Data->name('host' => $host),
                                 SOAP::Data->name('retValue' =>$retValue));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

1;

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

package ANSTE::Manager::AdminClient;

use strict;
use warnings;

use ANSTE::Manager::Job;
use ANSTE::Exceptions::MissingArgument;

use SOAP::Lite; # +trace => 'debug'; 

use constant URI => 'urn:ANSTE::Manager::AdminServer';

# Class: Client
#
#   Client for the administration interface of anste-manager.
#

# Constructor: new
#
#   Constructor for AdminClient class.
#
# Returns:
#
#   A recently created <ANSTE::Manager::AdminClient> object.
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

# Method: list
#
#   Sends a job list request to the server.
#
# Returns:
#
#   string - text representation of the job queue
#
sub list # returns queue string
{
    my ($self) = @_;

    my $soap = $self->{soap};

    my $response = $soap->list();
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result);
}

# Method: delete
#
#   Sends a delete job command to the server.
#
# Parameters:
#
#   id - String with the identificator of the job to delete.
#
# Returns:
#
#   boolean - true if server response is OK, false otherwise
#
sub delete # (jobID) returns boolean
{
    my ($self, $jobID) = @_;

    my $soap = $self->{soap};

    my $response = $soap->delete(SOAP::Data->name('id' => $jobID));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

1;

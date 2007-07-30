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

use SOAP::Lite; # +trace => 'debug'; 
use Net::Domain qw(hostname);

use constant URI => "urn:ANSTE::Comm::MasterServer";

sub new
{
    my $class = shift;
    my $self = {};

    $self->{soap} = undef;

    bless $self, $class;

    return $self;
}

sub connect	# (host) 
{
    my ($self, $host) = @_;

    $self->{soap} = new SOAP::Lite(uri => URI, 
                                   endpoint => $host, 
                                   proxy => $host);
}

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

sub executionFinished 
{
    my ($self, $retValue) = @_;

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

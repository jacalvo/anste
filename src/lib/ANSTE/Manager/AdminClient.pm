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

sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{soap} = undef;

    bless $self, $class;

    return $self;
}

sub connect	# (host) 
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $self->{soap} = new SOAP::Lite(uri => URI,
                                   proxy => $host,
                                   endpoint => $host); 
}

sub connected # returns boolean
{
    my ($self) = @_;

    return defined($self->{soap});
}

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

1;

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

package ANSTE::Comm::MasterServer;

use ANSTE::Comm::HostWaiter;

use strict;
use warnings;

# Class: MasterServer
#
#   This class is used by the SOAP server running in the master host
#   to handle the requests from the slave clients.
#

# Method: hostReady
#
#   Handle a host ready message from a given host.
#
# Parameters:
#
#   host - String with the name of the host.
#
# Returns:
#
#   string - OK
#
sub hostReady # (host) 
{
    my ($self, $host) = @_;

    my $waiter = ANSTE::Comm::HostWaiter->instance(); 
    $waiter->hostReady($host);

    return 'OK';
}

# Method: executionFinished
#
#   Handle a script execution finished message from a given host.
#
# Parameters:
#
#   host - String with the name of the host.
#   retValue - Integer with the return value of the script.
#
# Returns:
#
#   string - OK
#
sub executionFinished # (host, retValue) 
{
    my ($self, $host, $retValue) = @_;

    my $waiter = ANSTE::Comm::HostWaiter->instance(); 
    $waiter->executionFinished($host, $retValue);

    return 'OK';
}


1;

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

package ANSTE::Comm::WaiterServer;

use warnings;
use strict;

use ANSTE::Comm::MasterServer;
use ANSTE::Config;

use threads;
use SOAP::Transport::HTTP;

my $thread = undef;

sub new # returns new WaiterServer object
{
	my ($class) = @_;
	my $self = {};

	bless($self, $class);

	return $self;
}

sub startThread # returns thread object
{
    my ($self) = @_;

    $thread = threads->create('_startServer') unless defined $thread;
    
    return($thread);
}

sub _startServer
{
    my $port = ANSTE::Config->instance()->masterPort();

    my $server = new SOAP::Transport::HTTP::Daemon(LocalPort => $port, 
                                                   Reuse => 1);
    $server->dispatch_to('ANSTE::Comm::MasterServer');
    $server->handle();    
}

1;

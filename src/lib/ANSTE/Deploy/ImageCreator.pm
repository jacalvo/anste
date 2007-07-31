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

package ANSTE::Deploy::ImageCreator;

use warnings;
use strict;

use ANSTE::System::Commands;
use ANSTE::Comm::MasterServer;
use ANSTE::Scenario::Image;

use threads;
use SOAP::Transport::HTTP;

use constant COPY_SCRIPT => 'data/conf/copyfiles.sh';

# TODO: Read from global preferences singleton
use constant PORT => 8001;

sub new # (image) returns new ImageCreator object
{
	my ($class, $image) = @_;
	my $self = {};
	
	$self->{image} = $image;

	bless($self, $class);

	return $self;
}

sub createImage
{
    my ($self) = @_;

    my $cmd = new ANSTE::System::Commands;

    my $image = $self->{image};

    $cmd->createImage($image->name()) or die "Error creating base image.";

    $cmd->mountImage($image->name()) or die "Error mounting image.";

    $cmd->copyFiles(COPY_SCRIPT) or die "Error copying files.";

    $cmd->installBasePackages() or die "Error installing packages.";

    $cmd->umountImage() or die "Error unmounting image.";

    # Starts Master Server thread
    my $thread = threads->create('_startMasterServer');

    $cmd->prepareSystem($image) or die "Error preparing system."; 

    $cmd->shutdownImage($image->name());
}

sub _startMasterServer
{
    my $server = new SOAP::Transport::HTTP::Daemon(LocalPort => PORT, 
                                                   Reuse => 1);
    $server->dispatch_to('ANSTE::Comm::MasterServer');
    $server->handle();    
}


1;

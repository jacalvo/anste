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

package ANSTE::Virtualizer::Xen;

use base 'ANSTE::Virtualizer::Virtualizer';

use strict;
use warnings;

sub new # returns new Xen object
{
	my $class = shift;
	my $self = {};
	
	bless($self, $class);

	return $self;
}

# public overriden method
#
# named parameters: 
# - name
# - ip
# - config
sub createImage # (%params)
{
    my ($self, %params) = @_;
    my $name = $params{name};
    my $ip = $params{ip};
    my $confFile = $params{config};

    my $command = "xen-create-image --hostname=$name" .
                  " --ip='192.168.45.191' --config=$confFile"; 

    $self->execute($command);
}

# public overriden
sub shutdownImage # (image)
{
    my ($self, $image) = @_;

    $self->execute("xm destroy $image");
}

sub createVM # (name)
{
    my ($self, $name) = @_;

    $self->execute("xm create $name.cfg");
}

1;

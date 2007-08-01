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

package ANSTE::Virtualizer::Virtualizer;

use strict;
use warnings;

use ANSTE::Exceptions::NotImplemented;


sub new # returns new Virtualizer object
{
	my $class = shift;
	my $self = {};
	
	bless($self, $class);

	return $self;
}

# public method
sub execute # (command)
{
    my ($self, $command) = @_;
    return system($command) == 0;
}

# public abstract method
#
# named parameters: 
# - name
# - ip
# - config
sub createImage # (%params)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# public abstract method
sub shutdownImage # (image)
{
    throw ANSTE::Exceptions::NotImplemented();
}

# Method: createVM
#
#   Override this method to create the Virtual Machine
#   with the corresponding virtualizer program.
#
# Arguments:
#
#   name - name of the virtual machine
#
sub createVM # (name)
{
    throw ANSTE::Exceptions::NotImplemented();
}

sub imageFile # (path, name)
{
    throw ANSTE::Exceptions::NotImplemented();
}

1;

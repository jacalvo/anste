# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2005 Warp Networks S.L., DBS Servicios Informaticos S.L.
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

package ANSTE::Exceptions::Base;

use strict;
use warnings;

use base 'Error';

# Class: Base
#
#   Base class for ANSTE exceptions.
#

# Constructor: new
#
#   Constructor for Base class.
#
# Parameters:
#
#   text - String with the exception message.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::Base> object.
#
sub new # (text)
{
	my ($class, $text) = @_;

	my $self = $class->SUPER::new(-text => "$text", @_);
	bless ($self, $class);
	return $self;
}

# Method: toStderr
#
#   Prints the exception message to system's standard error.
#
sub toStderr 
{
	my ($self) = @_;
	print STDERR "[ANSTE::Exceptions] ". $self->stringify() ."\n";
}

1;

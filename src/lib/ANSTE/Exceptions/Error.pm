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

package ANSTE::Exceptions::Error;

use base 'ANSTE::Exceptions::Base';

# Class: Error
#
#   Exception to be thrown when generic errors happen.
#

# Constructor: new
#
#   Constructor for Error class.
#
# Parameters:
#
#   msg  - String with the error message.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::Error> object.
#
sub new # (msg)
{
	my ($class, $msg) = @_;

	$self = $class->SUPER::new("ERROR: $msg\n");

	bless ($self, $class);
	return $self;
}

1;
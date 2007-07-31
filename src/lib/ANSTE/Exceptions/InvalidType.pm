# Copyright (C) 2007 José Antonio Calvo Fernández <jacalvo@warp.es> 
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

package ANSTE::Exceptions::InvalidType;

use base 'ANSTE::Exceptions::Base';

# Constructor: new
#
#     This exception is taken to say the type of an argument is not
#     the correct one.
#
# Parameters:
#
#     arg  - the mistaken argument
#     type - the correct type
#
# Returns:
#
#     The newly created <ANSTE::Exceptions::InvalidType> exception
#
sub new # (arg, type)
{
    my ($class, $arg, $type) = @_;


    my $argType = ref ($arg);
    $argType = 'scalar' unless ( $argType );

    $self = $class->SUPER::new("Invalid type for argument: $arg with type " .
	             		       $argType . ', which should be this type: ' .
			                   $type);

    bless ($self, $class);

    return $self;
}

1;

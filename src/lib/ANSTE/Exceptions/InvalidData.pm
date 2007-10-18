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

package ANSTE::Exceptions::InvalidData;

use base 'ANSTE::Exceptions::Base';

# Constructor: new
#
#   Constructor for InvalidData class.
#
# Parameters:
#
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::InvalidData> object.
#
sub new # (data, value)
{
	my ($class, $data, $value) = @_;

    my ($package, undef, $line, $method) = caller(2);

	$self = $class->SUPER::new("Invalid value for $data: '$value' in " .
                               "method '$method' at '$package:$line'\n");

	bless ($self, $class);
	return $self;
}

1;

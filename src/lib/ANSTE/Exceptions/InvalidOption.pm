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

package ANSTE::Exceptions::InvalidOption;

use base 'ANSTE::Exceptions::Base';

# Constructor: new
#
#   Constructor for InvalidOption class.
#
# Parameters:
#
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::InvalidOption> object.
#
sub new # (option, value)
{
	my ($class, $option, $value) = @_;

	$self = $class->SUPER::new("Invalid value for option $option: $value\n");

	bless ($self, $class);
	return $self;
}
1;

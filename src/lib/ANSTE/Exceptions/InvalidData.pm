# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

use strict;
use warnings;

use base 'ANSTE::Exceptions::Base';

# Class: InvalidData
#
#   Exception for invalid data values.
#

# Constructor: new
#
#   Constructor for InvalidData class.
#
# Parameters:
#
#   data  - String with the name of the parameter.
#   value - String with the wrong value for the data.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::InvalidData> object.
#
sub new # (data, value)
{
	my ($class, $data, $value) = @_;

    my ($package, undef, $line, $method) = caller(2);

	my $self = $class->SUPER::new("Invalid value for $data: '$value' in " .
                                  "method '$method' at '$package:$line'\n");

	bless ($self, $class);
	return $self;
}

1;

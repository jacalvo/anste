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

package ANSTE::Exceptions::MissingArgument;

use strict;
use warnings;

use base 'ANSTE::Exceptions::Base';

# Class: MissingArgument
#
#   An exception called when a mandatory argument is missing a
#   block call
#

# Constructor: new
#
#   Constructor for MissingArgument class.
#
# Parameters:
#
#      arg - String with the missing argument's name
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::MissingArgument> object.
#
sub new 
{
    my ($class, $arg) = @_;

    my ($package, undef, $line, $method) = caller(2);

    my $self = $class->SUPER::new("Missing argument '$arg' calling " .
                                  "method '$method' at '$package:$line'\n");

    bless ($self, $class);

    return $self;
}

1;

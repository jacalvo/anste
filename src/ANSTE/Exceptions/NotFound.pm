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

package ANSTE::Exceptions::NotFound;

use strict;
use warnings;

use base 'ANSTE::Exceptions::Base';

# Class: NotFound
#
#   Exception to be thrown when something is not present.
#

# Constructor: new
#
#   Constructor for NotFound class.
#
# Parameters:
#
#   what  - String with the kind of thing that is missing.
#   value - String with the name of the missing thing.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::NotFound> object.
#
sub new
{
    my ($class, $what, $value) = @_;

    my $self = $class->SUPER::new("$what '$value' not present\n");

    $self->{what} = $what;
    $self->{value} = $value;

    bless ($self, $class);
    return $self;
}

# Method: what
#
#   Gets what is not found.
#
# Returns:
#
#   string - Contains the name of the type of element not found..
#
sub what
{
    my ($self) = @_;

    return $self->{what};
}

# Method: value
#
#   Gets the value associed with the exception.
#
# Returns:
#
#   string - Contains the value.
#
sub value
{
    my ($self) = @_;

    return $self->{value};
}

1;

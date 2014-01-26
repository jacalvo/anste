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

package ANSTE::Exceptions::InvalidFile;

use strict;
use warnings;

use base 'ANSTE::Exceptions::Base';

# Class: InvalidFile
#
#   This exception is taken to say an argument is not
#   a valid file or filehandle.
#

# Constructor: new
#
#   Constructor for InvalidFile class.
#
# Parameters:
#
#   arg  - String with the mistaken argument
#   file - String with the invalid file.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::InvalidFile> object.
#
sub new
{
    my ($class, $arg, $file) = @_;

    my ($package, undef, $line, $method) = caller(2);

    my $self = $class->SUPER::new("Argument '$arg' is not a file in " .
                                  "method '$method' at '$package:$line'\n");

    $self->{file} = $file;

    bless ($self, $class);

    return $self;
}

# Method: file
#
#   Gets the filename associed with the exception.
#
# Returns:
#
#   string - Contains the filename.
#
sub file
{
    my ($self) = @_;

    return $self->{file};
}

1;

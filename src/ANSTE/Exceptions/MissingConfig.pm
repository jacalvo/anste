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

package ANSTE::Exceptions::MissingConfig;

use strict;
use warnings;

use base 'ANSTE::Exceptions::Base';

# Class: MissingConfig
#
#   Exception for a missing mandatory configuration option.

# Constructor: new
#
#   Constructor for MissingConfig class.
#
# Parameters:
#
#   option - String with the name of the missing option.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::MissingConfig> object.
#
sub new
{
    my ($class, $option) = @_;

    my $self = $class->SUPER::new("Missing mandatory option $option " .
                                  "in configuration file\n");

    bless ($self, $class);
    return $self;
}

1;

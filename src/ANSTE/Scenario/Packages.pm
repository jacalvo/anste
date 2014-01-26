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

package ANSTE::Scenario::Packages;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

# Class: Packages
#
#   Contains the list of packages that have to be installed on a image.
#

# Constructor: new
#
#   Constructor for Packages class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::Packages> object.
#
sub new
{
    my $class = shift;
    my $self = {};

    $self->{list} = [];

    bless($self, $class);

    return $self;
}

# Method: list
#
#   Gets the list of packages.
#
# Returns:
#
#   ref - list of packages
#
sub list
{
    my ($self) = @_;

    return $self->{list};
}

# Method: add
#
#   Adds a list of packages or a single package.
#
# Parameters:
#
#   packages - List of package names.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub add
{
    my ($self, @packages) = @_;

    if (not @packages) {
        throw ANSTE::Exceptions::MissingArgument('packages');
    }

    push (@{$self->{list}}, @packages);
}

sub loadYAML
{
    my ($self, $packages) = @_;

    defined $packages or
        throw ANSTE::Exceptions::MissingArgument('packages');

    foreach my $packageOrProfile (@{$packages}) {
        my $file = ANSTE::Config->instance()->profileFile($packageOrProfile);
        my $FILE;
        if (open ($FILE, '<', $file)) {
            my @names;
            chomp (@names = <$FILE>);
            close $FILE or die "Can't close $file";
            $self->add(@names);
        } else {
            $self->add($packageOrProfile);
        }
    }
}

1;

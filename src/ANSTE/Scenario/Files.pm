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

package ANSTE::Scenario::Files;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use XML::DOM;

# Class: Files
#
#   Contains the list of files that have to be copied to a image.
#

# Constructor: new
#
#   Constructor for Files class.
#
# Returns:
#
#   A recently created <ANSTE::Scenario::Files> object.
#
sub new # returns new Files object
{
    my $class = shift;
    my $self = {};

    $self->{list} = [];

    bless($self, $class);

    return $self;
}

# Method: list
#
#   Gets the list of files.
#
# Returns:
#
#   ref - list of files
#
sub list # returns the files list
{
    my ($self) = @_;

    return $self->{list};
}

# Method: add
#
#   Adds a list of files or a single files.
#
# Parameters:
#
#   files - List of files names.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#
sub add # (files)
{
    my ($self, @files) = @_;

    if (not @files) {
        throw ANSTE::Exceptions::MissingArgument('files');
    }

    push(@{$self->{list}}, @files);
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the files list into this object.
#
# Parameters:
#
#   node - <XML::DOM::Element> object containing the test data.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidType> - throw if parameter has wrong type
#
sub load # (node)
{
    my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                                             'XML::DOM::Element');
    }

    foreach my $profile ($node->getElementsByTagName('fileslists', 0)) {
        my $name = $profile->getFirstChild()->getNodeValue();
        my $file = ANSTE::Config->instance()->listsFile($name);
        my $FILE;
        open($FILE, '<', $file) or die "Error loading $file";
        my @names;
        chomp(@names = <$FILE>);
        close $FILE or die "Can't close $file";
        $self->add(@names);
    }

    foreach my $file ($node->getElementsByTagName('file', 0)) {
        my $name = $file->getFirstChild()->getNodeValue();
        $self->add($name);
    }
}

sub loadYAML
{
    my ($self, $files) = @_;

    defined $files or
        throw ANSTE::Exceptions::MissingArgument('files');

    # FIXME
    # Add support for list of filelists check above example of xml

    foreach my $file (@{$files}) {
        $self->add($file);
    }
}

1;

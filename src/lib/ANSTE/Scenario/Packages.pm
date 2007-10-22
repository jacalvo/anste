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

package ANSTE::Scenario::Packages;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

use XML::DOM;

# Class: Packages
#
#   Contains the list of packages that have to be installed on a image.
#

# Constructor: new
#
#   Constructor for X class.
#
# Returns:
#
#   A recently created <ANSTE::> object.
#
sub new # returns new Packages object
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
sub list # returns the package list 
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
sub add # (packages)
{
	my ($self, @packages) = @_;	

    if (not @packages) {
        throw ANSTE::Exceptions::MissingArgument('packages');
    }

	push(@{$self->{list}}, @packages);
}

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the package list into this object.
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


	foreach my $profile ($node->getElementsByTagName('profile', 0)) {
		my $name = $profile->getFirstChild()->getNodeValue();
        my $file = ANSTE::Config->instance()->profileFile($name);
		open(FILE, $file) or die "Error loading $file";
		my @names;
		chomp(@names = <FILE>);
		close FILE or die "Can't close $file";
		$self->add(@names);
	}

	foreach my $package ($node->getElementsByTagName('package', 0)) {
		my $name = $package->getFirstChild()->getNodeValue();
		$self->add($name);
	}
}

1;

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

use XML::DOM;

sub new # returns new Packages object
{
	my $class = shift;
	my $self = {};
	
	$self->{list} = [];

	bless($self, $class);

	return $self;
}

sub list # returns the package list 
{
	my $self = shift;
	return $self->{list};
}

# Add a list or packages or a single package
sub add # (packages)
{
	my $self = shift;	
	my @packages = @_;
	push(@{$self->{list}}, @packages);
}

sub load # (node)
{
	my $self = shift;
	my $node = shift;

	foreach my $profile ($node->getElementsByTagName("profile",0)) {
		my $file = "data/profiles/".$profile->getFirstChild()->getNodeValue();
		open(FILE, $file) || die "Error loading $file\n";
		my @names;
		chomp(@names = <FILE>);
		close FILE;
		$self->add(@names);
	}

	foreach my $package ($node->getElementsByTagName("package",0)) {
		my $name = $package->getFirstChild()->getNodeValue();
		$self->add($name);
	}
}

1;

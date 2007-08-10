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

package ANSTE::Scenario::Network;

use strict;
use warnings;

use ANSTE::Scenario::NetworkInterface;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidType;

sub new # returns new Network object
{
	my ($class) = @_;
	my $self = {};
	
    $self->{interfaces} = [];

	bless($self, $class);

	return $self;
}

sub interfaces # returns interfaces list reference
{
    my ($self) = @_;

    return $self->{interfaces};
}

sub addInterface # (interface)
{
    my ($self, $interface) = @_;

    defined $interface or
        throw ANSTE::Exceptions::MissingArgument('interface');

    if (not $interface->isa('ANSTE::Scenario::NetworkInterface')) {
        throw ANSTE::Exceptions::InvalidType('interface', 
             'ANSTE::Scenario::NetworkInterface');
    }

    push(@{ $self->{interfaces} }, $interface);
}

sub load # (node)
{
	my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                                             'XML::DOM::Element');
    }

    foreach my $element ($node->getElementsByTagName('interface', 0)) {
        my $interface = new ANSTE::Scenario::NetworkInterface;
        $interface->load($element);
        $self->addInterface($interface);
    }
}

1;

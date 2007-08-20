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

package ANSTE::Test::Test;

use strict;
use warnings;

use ANSTE::Exceptions::MissingArgument;

use XML::DOM;

sub new # returns new Test object
{
	my ($class) = @_;
	my $self = {};

    $self->{name} = '';
    $self->{desc} = '';
    $self->{dir} = '';
    $self->{seleniumFiles} = [];
	
	bless($self, $class);

	return $self;
}

sub name # returns name string
{
	my ($self) = @_;

	return $self->{name};
}

sub setName # name string
{
	my ($self, $name) = @_;	

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

	$self->{name} = $name;
}

sub desc # returns desc string
{
	my ($self) = @_;

	return $self->{desc};
}

sub setDesc # desc string
{
	my ($self, $desc) = @_;

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

	$self->{desc} = $desc;
}

sub host # returns host string
{
	my ($self) = @_;

	return $self->{host};
}

sub setHost # host string
{
	my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

	$self->{host} = $host;
}

sub dir # returns dir string
{
	my ($self) = @_;

	return $self->{dir};
}

sub setDir # dir string
{
	my ($self, $dir) = @_;

    defined $dir or
        throw ANSTE::Exceptions::MissingArgument('dir');

	$self->{dir} = $dir;
}

sub seleniumFiles # returns list ref
{
    my ($self) = @_;

    return $self->{seleniumFiles};
}

sub addSeleniumFile # (file)
{
    my ($self, $file) = @_;

   	push(@{$self->{seleniumFiles}}, $file);
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

	my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
	my $name = $nameNode->getFirstChild()->getNodeValue();
	$self->setName($name);

	my $descNode = $node->getElementsByTagName('desc', 0)->item(0);
	my $desc = $descNode->getFirstChild()->getNodeValue();
	$self->setDesc($desc);

	my $hostNode = $node->getElementsByTagName('host', 0)->item(0);
	my $host = $hostNode->getFirstChild()->getNodeValue();
    $self->setHost($host);

	my $dirNode = $node->getElementsByTagName('dir', 0)->item(0);
	my $dir = $dirNode->getFirstChild()->getNodeValue();
    $self->setDir($dir);

	my $selenium = $node->getElementsByTagName('selenium', 0)->item(0);
    if ($selenium) {
    	foreach my $fileNode ($selenium->getElementsByTagName('file', 0)) {
            my $file = $fileNode->getFirstChild()->getNodeValue();
            $self->addSeleniumFile($file);
        }
	}
}

1;

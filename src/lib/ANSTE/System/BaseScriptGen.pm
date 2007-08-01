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

package ANSTE::System::BaseScriptGen;

use strict;
use warnings;

use ANSTE::Scenario::Image;

sub new # (image) returns new BaseScriptGen object
{
	my ($class, $image) = @_;

	my $self = {};
	
	$self->{image} = $image;

	bless($self, $class);

	return $self;
}

sub writeScript # (file)
{
	my ($self, $file) = @_;

	print $file "#!/bin/sh\n";
	my $image = $self->{image}->name();
	print $file "\n# Configuration file for image $image\n";
	print $file "# Generated by ANSTE\n\n"; 
    $self->_writePreInstall($file);
	$self->_writePackageInstall($file);
    $self->_writePostInstall($file);
}

sub _writePreInstall # (file)
{
    my ($self, $file) = @_;

    print $file "export DEBIAN_FRONTEND=noninteractive\n\n";

    my $forceConfnew = 'Dpkg::Options::=--force-confnew';
    my $forceConfdef = 'Dpkg::Options::=--force-confdef';
    print $file "OPTIONS='-o $forceConfnew -o $forceConfdef';\n\n"; 

    # TODO: Get this via System::Debian or similar
    my $command = 'apt-get update';
    
    print $file "$command\n\n";
}

sub _writePackageInstall # (file)
{
	my ($self, $file) = @_;

	print $file "# Install packages\n";
	#FIXME: my $command = $self->{system}->command("package-install");
    my $command = 'apt-get install -y $OPTIONS';
	my @packages = @{$self->{image}->packages()->list()};
	print $file "$command ".join(" ", @packages)."\n\n";
}

sub _writePostInstall # (file)
{
    my ($self, $file) = @_;

    print $file "apt-get clean\n";
}

1;

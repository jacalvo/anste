# Copyright (C) 2013 Zentyal S.L.
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

package ANSTE::Status;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::NotFound;

use JSON::XS;
use File::Slurp;

# Class: Status
#
#   Reads/writes status info to disk.
#

my $singleton;

# Method: instance
#
#   Returns a reference to the singleton object of this class
#
# Returns:
#
#   ref - the class unique instance of type <ANSTE::Status>.
#
sub instance
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};

        $self->{config} = ANSTE::Config->instance();

        $singleton = bless($self, $class);
    }

    return $singleton;
}

sub currentScenario
{
    my ($self) = @_;

    return $self->{currentScenario};
}

sub setCurrentScenario
{
    my ($self, $file) = @_;

    $self->{currentScenario} = $file;
}

sub hostsFile
{
    my ($self) = @_;

    return $self->{config}->imagePath() . '/deployed_hosts.list';
}

sub readHosts
{
    my ($self) = @_;

    my $file = $self->hostsFile();

    unless (-f $file) {
        throw ANSTE::Exceptions::NotFound('file', $file);
    }

    my $hosts = read_file($file);
    return undef unless $hosts;
    return decode_json($hosts);
}

sub writeHosts
{
    my ($self, $hosts) = @_;

    write_file($self->hostsFile(), encode_json($hosts));
}

1;

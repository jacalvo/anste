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
use TryCatch::Lite;

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

        $self->{status} = undef;

        $singleton = bless($self, $class);
    }

    return $singleton;
}

sub currentScenario
{
    my ($self) = @_;

    $self->_get('currentScenario');
}

sub setCurrentScenario
{
    my ($self, $file) = @_;

    $self->_set('currentScenario', $file);
}

sub deployedHosts
{
    my ($self) = @_;

    $self->_get('hosts');
}

sub setDeployedHosts
{
    my ($self, $hosts) = @_;

    $self->_set('hosts', $hosts);
}

sub remove
{
    my ($self) = @_;

    unlink ($self->_statusFile());
}

sub cleanNetwork
{
    my @bridges = `virsh net-list 2>/dev/null | grep anste | awk '{ print \$1 }'`;
    chomp (@bridges);
    foreach my $br (@bridges) {
        print "Destroying network $br...\n";
        system ("virsh net-destroy $br");
    }

    my @pids = `ps ax | grep dnsmasq | grep anste | awk '{ print \$1 }'`;
    foreach my $pid (@pids) {
        system ("kill -9 $pid");
    }
}

sub virtualizerStatus
{
    my ($self) = @_;

    return $self->_get('virtualizerStatus');
}

sub setVirtualizerStatus
{
    my ($self, $status) = @_;

    $self->_set('virtualizerStatus', $status);
}

sub useOpenStack
{
    my ($self) = @_;

    return $self->_get('useOpenStack');
}

sub setUseOpenStack
{
    my ($self, $status) = @_;

    $self->_set('useOpenStack', $status);
}

sub _set
{
    my ($self, $var, $value) = @_;

    unless ($self->{status}) {
        $self->{status} = $self->_readStatusFile();
    }

    $self->{status}->{$var} = $value;

    write_file($self->_statusFile(), encode_json($self->{status}));
}

sub _get
{
    my ($self, $var) = @_;

    unless ($self->{status}) {
        $self->{status} = $self->_readStatusFile();
    }

    return $self->{status}->{$var};
}

sub _readStatusFile
{
    my ($self) = @_;

    my $file = $self->_statusFile();

    return undef unless (-f $file);

    my $status;
    try {
        $status = read_file($file);
    } catch {
    }
    return undef unless $status;
    return decode_json($status);
}

sub _statusFile
{
    my ($self) = @_;

    return $self->{config}->imagePath() . '/status.json';
}

1;

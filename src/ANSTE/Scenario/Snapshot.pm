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

package ANSTE::Scenario::Snapshot;

use warnings;
use strict;

use ANSTE::Config;
use ANSTE::Status;
use ANSTE::Virtualizer::Virtualizer;
use ANSTE::Exceptions::NotFound;

use Cwd;
use JSON::XS;
use File::Slurp;
use TryCatch::Lite;

# Class: Snapshot
#
#   Set of commands for managing scenario snapshots
#

my $config = ANSTE::Config->instance();
my $status = ANSTE::Status->instance();
my $PATH = $config->snapshotsPath();
my $virt = ANSTE::Virtualizer::Virtualizer->instance();

# Method: save
#
#   Save snapshot of the given scenario
#
sub save
{
    my ($self, $name, $desc) = @_;

    system ("mkdir -p $PATH");

    my $config = ANSTE::Config->instance();
    my $hosts = $status->deployedHosts();

    foreach my $host (keys %{$hosts}) {
        print "taking snapshot of $host...\n";
        $virt->createSnapshot($host, $name, $desc);
    }

    my $json = encode_json({ name => $name, desc => $desc, hosts => $hosts });

    write_file("$PATH/$name", $json);
}

# Method: list
#
#   List available snapshots
#
sub list
{
    my ($self) = @_;

    my @files = glob ("$PATH/*");
    my @snapshots = map { decode_json(read_file($_)) } @files;

    return \@snapshots;
}

# Method: restore
#
#   Restore a saved snapshot
#
sub restore
{
    my ($self, $name) = @_;

    my $snapshot = $self->_loadSnapshot($name);

    print "Restoring $name...\n";

    foreach my $host (keys %{$snapshot->{hosts}}) {
        print "Restoring host $host...\n";
        $virt->revertSnapshot($host, $name);
    }
}

# Method: remove
#
#   Delete a saved snapshot
#
sub remove
{
    my ($self, $name) = @_;

    my $snapshot = $self->_loadSnapshot($name);

    print "Removing $name...\n";

    foreach my $host (keys %{$snapshot->{hosts}}) {
        print "Removing snapshot for host $host...\n";
        $virt->deleteSnapshot($host, $name);
    }

    unlink ("$PATH/$name");
}

sub _loadSnapshot
{
    my ($self, $name) = @_;

    my $file = "$PATH/$name";

    unless (-f $file) {
        throw ANSTE::Exceptions::NotFound('snapshot', $name);
    }

    return decode_json(read_file($file));
}

1;

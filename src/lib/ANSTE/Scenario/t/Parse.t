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

use strict;
use warnings;

use Scenario::Scenario;

use Test::More tests => 37;

use constant SCENARIO => "data/test.xml";

sub testServer # (server)
{
	my ($server) = @_;
	my $name = $server->name();
    is($name, "serverName", "name = serverName");
	my $desc = $server->desc();
    is($desc, "serverDesc", "name = serverName");

	testNetwork($server->network());
	testPackages($server->packages());
}

sub testNetwork # (network)
{
    my ($network) = @_;
	foreach my $interface ($network->interfaces()) {
		testInterface($interface);
	}
}

sub testInterface # (interface)
{
	my ($iface) = @_;
	my $type = ($iface->type() == 
                Scenario::NetworkInterface::IFACE_TYPE_DHCP) ? 
                "dhcp" : 
                "static";
    my $name = $iface->name();
    like($name, qr/^eth/, "interface name matchs /^eth/"); 
    if ($type eq "static") {
        my $address = $iface->address();
        like($address, qr/^192/, "interface name matchs /^192/"); 
        my $netmask = $iface->netmask();
        like($netmask, qr/^255/, "interface name matchs /^255/"); 
        my $gateway = $iface->gateway();
        like($gateway, qr/^192/, "gateway matchs /^192/");
    }
}

sub testPackages # (packages)
{
	my $packages = shift;

	print "Showing Packages...\n";
	my @packages = $packages->list();
    ok(length(@packages) > 0, "packages count test");
    my $count = 0;
	foreach my $package (@packages) {
        ok(defined($package), "package defined");
        unlike($package, qr/^$/, "package not empty");
        $count++;
        if ($count == 2) {
            last;
        }
	}
}

sub testVirtualizer # (virtualizer)
{
	my $virtualizer = shift;
	
	print "\nShowing Virtualizer...\n";

	my $name = $virtualizer->name();
    is($name, "virtualizerName", "virtualizer name = virtualizerName");
	my $desc = $virtualizer->desc();
    is($desc, "virtualizerDesc", "virtualizer desc = virtualizerDesc");

	my %commands = $virtualizer->commands();
    ok(length(%commands) > 0, "virtualizer commands count test");
	for my $commandName (keys %commands) {
		my $command = $commands{$commandName}; 
        ok(defined($command), "virtualizer command defined");
        unlike($command, qr/^$/, "virtualizer command not empty");
	}
}

sub testSystem # (system)
{
	my $system = shift;

	print "\nShowing System...\n";

	my $name = $system->name();
    is($name, "systemName", "system name = systemName");
	my $desc = $system->desc();
    is($desc, "systemDesc", "system desc = systemDesc");


	my %commands = $system->commands();
    ok(length(%commands) > 0, "system commands test");
	for my $commandName (keys %commands) {
		my $command = $commands{$commandName}; 
        ok(defined($command), "system command defined");
        unlike($command, qr/^$/, "system command not empty");
	}
}

sub test # (scenario)
{
	my $scenario = shift; 
	my $name = $scenario->name();
    is($name, "scenarioName", "scenario name = scenarioName");
	my $desc = $scenario->desc();
    is($desc, "scenarioDesc", "scenario desc = scenarioDesc");

	testVirtualizer($scenario->virtualizer());
	testSystem($scenario->system());

	foreach my $server ($scenario->servers()) {
		testServer($server);
	}
}

my $scenario = new Scenario::Scenario;
$scenario->loadFromFile(SCENARIO);
test($scenario);

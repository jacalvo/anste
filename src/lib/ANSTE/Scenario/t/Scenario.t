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

use ANSTE::Scenario::Scenario;
use ANSTE::Config;

use Test::More tests => 47;

use constant SCENARIO => 'test.xml';

sub testServer # (host)
{
	my ($host) = @_;
	my $name = $host->name();
    is($name, 'hostName', 'name = hostName');
	my $desc = $host->desc();
    is($desc, 'hostDesc', 'desc = hostDesc');

	testNetwork($host->network());
	testPackages($host->packages());
    testBaseImage($host->baseImage());
}

sub testNetwork # (network)
{
    my ($network) = @_;
	foreach my $interface (@{$network->interfaces()}) {
		testInterface($interface);
	}
}

sub testInterface # (interface)
{
	my ($iface) = @_;
	my $type = ($iface->type() == 
                ANSTE::Scenario::NetworkInterface::IFACE_TYPE_DHCP) ? 
                'dhcp' : 
                'static';
    my $name = $iface->name();
    like($name, qr/^eth/, 'interface name matchs /^eth/'); 
    if ($type eq "static") {
        my $address = $iface->address();
        like($address, qr/^192/, 'interface name matchs /^192/');
        my $netmask = $iface->netmask();
        like($netmask, qr/^255/, 'interface name matchs /^255/'); 
        my $gateway = $iface->gateway();
        like($gateway, qr/^192/, 'gateway matchs /^192/');
    }
}

sub testBaseImage # (image)
{
    my ($image) = @_;

	my $name = $image->name();
    is($name, 'imageName', 'name = imageName');
	my $desc = $image->desc();
    is($desc, 'imageDesc', 'desc = imageDesc');
	my $memory = $image->memory();
    is($memory, 'imageMemory', 'memory = imageMemory');
	my $size = $image->size();
    is($size, 'imageSize', 'size = imageSize');

	testPackages($image->packages());

    is(scalar(@{$image->preScripts()}), 2, 'pre-script count test');

    is(scalar(@{$image->postScripts()}), 3, 'post-script count test');
}

sub testPackages # (packages)
{
	my ($packages) = @_;

	print "Showing Packages...\n";
    ok(length(@{$packages->list()}) > 0, 'packages count test');
    my $count = 0;
	foreach my $package (@{$packages->list()}) {
        ok(defined($package), 'package defined');
        unlike($package, qr/^$/, 'package not empty');
        $count++;
        if ($count == 2) {
            last;
        }
	}
}

sub test # (scenario)
{
	my ($scenario) = @_;
	my $name = $scenario->name();
    is($name, 'scenarioName', 'scenario name = scenarioName');
	my $desc = $scenario->desc();
    is($desc, 'scenarioDesc', 'scenario desc = scenarioDesc');

	foreach my $host (@{$scenario->hosts()}) {
		testServer($host);
	}
}

my $scenario = new ANSTE::Scenario::Scenario();
$scenario->loadFromFile(SCENARIO);
test($scenario);

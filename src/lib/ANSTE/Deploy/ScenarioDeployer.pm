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

package ANSTE::Deploy::ScenarioDeployer;

use strict;
use warnings;

use ANSTE::Scenario::Scenario;
use ANSTE::Deploy::HostDeployer;

sub new # (scenario) returns new ScenarioDeployer object
{
	my ($class, $scenario) = @_;
	my $self = {};
	
	$self->{scenario} = $scenario;

	bless($self, $class);

	return $self;
}

sub deploy 
{
    my ($self) = @_;

    my $scenario = $self->{scenario};
    my $system = $scenario->system();
    my $virtualizer = $scenario->virtualizer();

    foreach my $host ($scenario->hosts()) {
        my $deployer = new ANSTE::Deploy::HostDeployer($host, 
                                                       $system, 
                                                       $virtualizer);
        $deployer->deploy();
    }
}

1;

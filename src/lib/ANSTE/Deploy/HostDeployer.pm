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

package ANSTE::Deploy::HostDeployer;

use strict;
use warnings;

use ANSTE::Scenario::Host;
use ANSTE::Scenario::HostScriptGen;
use ANSTE::Comm::MasterClient;

use constant SETUP_SCRIPT => 'setup.sh';

sub new # (host, system, virtualizer) returns new HostDeployer object
{
	my ($class, $host, $system, $virtualizer) = @_;
	my $self = {};

	$self->{host} = $host;
	$self->{system} = $system;
	$self->{virtualizer} = $virtualizer;

	bless($self, $class);

	return $self;
}

sub deploy 
{
    my ($self) = @_;

    my $ip = $self->_createVirtualMachine();
    $self->_generateCommScript(SETUP_SCRIPT);
    $self->_executeCommScript($ip, SETUP_SCRIPT);
}

sub _createVirtualMachine # returns IP address string
{
    my ($self) = @_;

    my $host = $self->{host};
    my $system = $self->{system};
    my $virtualizer = $self->{virtualizer};

    my $name = $host->name();
    # FIXME: Hardcoded!!! (Get the ip of the secret communications interface)
    my $ip = '192.168.45.191';

    print "Creating virtual machine for host $name...\n"; 
    print "It will be accesible under $ip.\n"; 
    print "System = ".$system->name()."\n";
    print "Virtualizer = ".$virtualizer->name()."\n";
    print "\n";

    return $ip;
}

sub _generateCommScript # (script)
{
    my ($self, $script) = @_;
    
    my $host = $self->{host};
    my $system = $self->{system};

    print "Generating setup script...\n";
    my $generator = new ANSTE::Scenario::HostScriptGen($host, $system);
    open(my $file, '>', $script);
    $generator->writeScript($file);
    close($file);
}

sub _executeCommScript # (host, script)
{
    my ($self, $host, $script) = @_;

    my $system = $self->{system};

    my $client = new ANSTE::Comm::MasterClient;
    # TODO: Read PORT from preferences singleton
    my $PORT = 8000;
    $client->connect("http://$host:$PORT");
    print "Uploading script...\n";
    $client->put($script);
    print "Executing script...\n";
    $client->exec($script, "$script.out");
    print "Script executing with the following output:\n";
    $client->get("$script.out");
    $self->_printOutput("$script.out");
    print "Deleting generated files...\n";
    $client->del($script);
    $client->del("$script.out");
    unlink($script);
    unlink("$script.out");
}

sub _printOutput # (file)
{
    my ($self, $file) = @_;

    my $FILE;
    open($FILE, '<', $file);
    my @lines = <$FILE>;
    foreach (@lines) {
        print;
    }
    print "\n";
    close($FILE);
}

1;

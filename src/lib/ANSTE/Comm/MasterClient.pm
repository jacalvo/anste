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

package ANSTE::Comm::MasterClient;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::InvalidFile;

use SOAP::Lite; # +trace => 'debug'; 

use constant URI => 'urn:ANSTE::Comm::SlaveServer';

sub new
{
    my ($class) = @_;
    my $self = {};

    $self->{soap} = undef;

    bless $self, $class;

    return $self;
}

sub connect	# (host) 
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $self->{soap} = new SOAP::Lite(uri => URI,
                                   proxy => $host,
                                   endpoint => $host); 
}

sub connected # returns boolean
{
    my ($self) = @_;

    return defined($self->{soap});
}

sub put	# (file) returns boolean
{
    my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    if (not -r $file) {
        throw ANSTE::Exceptions::InvalidFile('file');
    }

    my $soap = $self->{soap};

    my $size = -s $file;
    # Reads the data
    open(FILE, "<", $file) or die "Can't open(): $!";
    my $content;
    read(FILE, $content, $size);
    close(FILE);

    my $response = $soap->put(SOAP::Data->name('name' => $file),
		                      SOAP::Data->name('content' => $content));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

sub get	# (file)
{
    my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    my $soap = $self->{soap};
    my $config = ANSTE::Config->instance();

    # Sends the request 
    my $response = $soap->get(SOAP::Data->name('name' => $file));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $content = $response->result;
    if ($content eq 'ERR'){
        return 0;
    } else {
    	# Writes the file
    	open(FILE, ">", $file) or die "Can't open(): $!";
    	print FILE $content;
    	close FILE;
    	print "File $file written\n" if $config->verbose();
        return 1;
    }
}

sub exec # (command, log) # - log optional
{
    my ($self, $command, $log) = @_;

    defined $command or
        throw ANSTE::Exceptions::MissingArgument('command');

    my $soap = $self->{soap};

    my @args = (SOAP::Data->name('name' => $command));
    if (defined($log)) {
        push(@args, SOAP::Data->name('log' => $log));
    }
    my $response = $soap->exec(@args);
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

sub del	# (file)
{
    my ($self, $file) = @_;

    defined $file or
        throw ANSTE::Exceptions::MissingArgument('file');

    my $soap = $self->{soap};

    my $response = $soap->del(SOAP::Data->name('name' => $file));
    if ($response->fault) {
    	die "SOAP request failed: $!";
    }
    my $result = $response->result;
    return($result eq 'OK');
}

1;

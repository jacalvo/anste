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

package ANSTE::Comm::HostWaiter;

use strict;
use warnings;

use threads;
use threads::shared;

use ANSTE::Exceptions::MissingArgument;

# Class: HostWaiter
#
# Informates when a slave host ends its boot process and finishes
# the execution of a command.
# This is done by blocking methods that waits for the event of a
# given host.

my $singleton;

my $lock : shared;

my %ready : shared;
my %executed : shared;

my $returnValue : shared;

sub instance 
{
    my $class = shift;
    unless (defined $singleton) {
        my $self = {};
        
        $singleton = bless($self, $class);
    }

    return $singleton;
}

sub hostReady # (host)
{
    my ($self, $host) = @_; 
    lock($lock);
    $ready{$host} = 1;
    cond_signal($lock);
}

sub executionFinished # (host, retValue)
{
    my ($self, $host, $retValue) = @_; 

    lock($lock);
    $executed{$host} = 1;
    $returnValue = $retValue;
    cond_signal($lock);
}

sub waitForReady # (host)
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $ready{$host} = 0;
    until ($ready{$host}) {
        _waitForEvent();
    }
    return(1);
}

sub waitForExecution # (host) returns retValue
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $executed{$host} = 0;
    until ($executed{$host}) {
        _waitForEvent();
    }
    return($returnValue);
}

sub _waitForEvent
{
    lock($lock);
    cond_wait($lock);
}

1;

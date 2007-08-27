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

package ANSTE::Comm::SlaveServer;

use strict;
use warnings;

use File::Basename;

my $DIR = '/tmp';

sub put	# (file, content)
{
    my ($self, $file, $content) = @_;

    my $name = fileparse($file);

    if (open(FILE, '>', "$DIR/$name")) { 
    	print FILE $content;
    	close FILE or die "Can't close: $!";
    	return 'OK';
    } else {
	    return 'ERR\n';
    }
}

sub get	# (file)
{
    my ($self, $file) = @_;

    my $name = fileparse($file); 

    if (open(FILE, '<', "$DIR/$name")) {
	    chomp(my @lines = <FILE>);
	    close FILE;
	    return join("\n", @lines)."\n";
    } else {
	    return 'ERR';
    }
}

sub exec # (file, log?)
{
    my ($self, $file, $log) = @_;

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif($pid == 0){
        my $name = fileparse($file); 
        chmod 0700, "$DIR/$name";
        my $command = "$DIR/$name";
        my $ret;
        if (defined $log) {
            my $log = fileparse($log);
            my $logfile = "$DIR/$log";
            $ret = $self->_executeSavingLog($command, $logfile);
        }
        else {
            $ret = $self->_execute($command);
        }
        # FIXME: This isn't cool.
        exec("/usr/local/bin/anste-slave finished $ret");
        exit(0);
    }
    else {
        return 'OK';
    }
}

sub del	# (file)
{
    my ($self, $file) = @_;

    my $name = fileparse($file); 

    if(unlink "$DIR/$name") {
    	return 'OK';
    } else {
	    return 'ERR';
    }
}

sub _execute # (command)
{
    my ($self, $command) = @_;

    return system($command);
}

sub _executeSavingLog # (command, log)
{
    my ($self, $command, $log) = @_;

    # Take copies of the file descriptors
    open(OLDOUT, '>&STDOUT')   or return 1;
    open(OLDERR, '>&STDERR')   or return 1;

    # Redirect stdout and stderr
    open(STDOUT, "> $log")     or return 1;
    open(STDERR, '>&STDOUT')   or return 1;

    my $ret = system($command);

    # Close the redirected filehandles
    close(STDOUT)              or return 1;
    close(STDERR)              or return 1;

    # Restore stdout and stderr
    open(STDERR, '>&OLDERR')   or return 1;
    open(STDOUT, '>&OLDOUT')   or return 1;

    # Avoid leaks by closing the independent copies
    close(OLDOUT)              or return 1;
    close(OLDERR)              or return 1;

    return $ret;
}

1;

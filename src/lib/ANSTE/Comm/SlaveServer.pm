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

my $DIR = "/tmp";

sub put	# (name, content)
{
    my ($self, $name, $content) = @_;

    if (open(FILE, '>', "$DIR/$name")) { 
    	print FILE $content;
    	close FILE or die "Can't close: $!";
    	return 'OK';
    } else {
	    return 'ERR\n';
    }
}

sub get	# (name)
{
    my ($self, $name) = @_;

    # TODO: Check and forbid paths, only allow filenames stored in CWD
    if (open(FILE, '<', "$DIR/$name")) {
	    chomp(my @lines = <FILE>);
	    close FILE;
	    return join("\n", @lines)."\n";
    } else {
	    return 'ERR';
    }
}

sub exec # (name, log)
{
    my ($self, $name, $log) = @_;

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif($pid == 0){
        chmod 0700, "$DIR/$name";
        my $command = "$DIR/$name";
        my $logfile = defined($log) ? "$DIR/$log" : "$DIR/out.log"; 
        my $ret = _executeSavingLog($command, $logfile);
        # FIXME: This isn't cool.
        exec("/usr/local/bin/anste-slave finished $ret");
        exit(0);
    }
    else {
        return 'OK';
    }
}

sub del	# (name)
{
    my ($self, $name) = @_;

    if(unlink "$DIR/$name") {
    	return 'OK';
    } else {
	    return 'ERR';
    }
}

sub _executeSavingLog # (command, log)
{
    my ($command, $log) = @_;

    # Take copies of the file descriptors
    open(OLDOUT, '>&STDOUT');
    open(OLDERR, '>&STDERR');

    # Redirect stdout and stderr
    open(STDOUT, "> $log");
    open(STDERR, '>&STDOUT');

    my $ret = system($command);

    # Close the redirected filehandles
    close(STDOUT);
    close(STDERR);

    # Restore stdout and stderr
    open(STDERR, '>&OLDERR');
    open(STDOUT, '>&OLDOUT');

    # Avoid leaks by closing the independent copies
    close(OLDOUT);
    close(OLDERR);

    return $ret;
}

1;

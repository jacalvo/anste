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
use MIME::Base64;

# Class: SlaveServer
#
#   This class is used by the SOAP server running in the slave hosts
#   to handle the requests from the master client.
#

my $DIR = '/var/local/anste';
my $LOGPATH = '/var/log/anste';

# Method: put
#
#   Handles a file put command, writing the contents of the file to disk.
#   TODO: Do this with attachments?
#
# Parameters:
#
#   file - String with the name of the file.
#   content - String with the data of the file.
#
# Returns:
#
#   string - OK if everything goes well, ERR if not
#
sub put	# (file, content)
{
    my ($self, $file, $content) = @_;

    my $name = fileparse($file);

    my $FILE;
    if (open($FILE, '>', "$DIR/$name")) { 
    	print $FILE $content;
    	close $FILE or die "Can't close: $!";
    	return 'OK';
    } else {
	    return 'ERR';
    }
}

# Method: get
#
#   Handles a file get command, reading and returning the contents of the 
#   file from disk.
#
# Parameters:
#
#   file - String with the name of the file.
#
# Returns:
#
#   string - String with the contents of the file or ERR if fails.
#
sub get	# (file)
{
    my ($self, $file) = @_;

    my $name = fileparse($file); 

    my $FILE;
    if (open($FILE, '<', "$DIR/$name")) {
	    chomp(my @lines = <$FILE>);
	    close $FILE;
	    return encode_base64(join("\n", @lines) . "\n");
    } else {
	    return 'ERR';
    }
}

# Method: exec
#
#   Handles a execution command, executing the specified file and optionally
#   writing its output to a log.
#   This is non-blocking, the execution is done in a separate process
#   and when it finishes the master is notified through anste-slave command.
#
#
# Parameters:
#
#   file   - String with the name of the file to be executed.
#   log    - *optional* String with the name of the file to save the log.
#   env    - *optional* String with the environment variables.
#   params - *optional* String with the parameters of the program.
#
# Returns:
#
#   string - OK
#
sub exec # (file, log?, env?, params?)
{
    my ($self, $file, $log, $env, $params) = @_;

    unless(defined $env) {
        $env = '';
    }
    unless(defined $params) {
        $params = '';
    }

    my $pid = fork();
    if (not defined $pid) {
        die "Can't fork: $!";
    }
    elsif ($pid == 0){
        my $name = fileparse($file); 
        chmod 700, "$DIR/$name";
        my $command = "$DIR/$name";
        my $ret;
        if (defined $log) {
            my $log = fileparse($log);
            my $logfile = "$DIR/$log";
            $ret = $self->_executeSavingLog($command, $logfile, 
                                            $env, $params);
        }
        else {
            $ret = $self->_execute($command);
        }
        sleep 1; # Avoid notification before starting to wait for finish
        exec("/usr/local/bin/anste-slave finished $ret");
        exit(0);
    }
    else {
        return 'OK';
    }
}

# Method: del
#
#   Handles a file delete command, deleting the given file from disk.
#
# Parameters:
#
#   file - String with the name of the file to be deleted.
#
# Returns:
#
#   string - OK if removed correctly, ERR if not
#
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

    my $name = fileparse($command);
    my $date = `date +%y%m%d-%H-%M-%S`;
    chomp($date);

    system("cp $command '$LOGPATH/$name-$date'");
    return system("$command > $LOGPATH/$name-$date.log 2>&1");
}

sub _executeSavingLog # (command, log, env, params)
{
    my ($self, $command, $log, $env, $params) = @_;

    my $name = fileparse($command);
    my $date = `date +%y%m%d-%H-%M-%S`;
    chomp($date);
    my $ret = system("$env $command $params > '$log' 2>&1");

    # Save the script and the log for debug purposes
    system("cp $command '$LOGPATH/$name-$date'");
    system("cp '$log' '$LOGPATH/$name-$date.log'");

    return $ret;
}

1;

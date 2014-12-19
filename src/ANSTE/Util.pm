# Copyright (C) 2014 Rubén Durán Balda <rduran@zentyal.com>
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

package ANSTE::Util;

use File::Slurp;
use File::Basename;

use ANSTE::Config;
use ANSTE::Exceptions::Error;

use strict;
use warnings;

# Function: readChar
#
#   Reads a whole line from the standard input and returns the first character
#
# Returns:
#
#   char - first character read from the standard input
#
sub readChar
{
    my $line = <STDIN>;
    return substr($line, 0, 1);
}

# Function: processYamlFile
#
#   Processes a YAML *file* using CPP and returns the output file path
#
# Returns:
#
#   char - path to the processed YAML file
#
sub processYamlFile
{
    my ($pathToFile) = @_;

    if (not -r $pathToFile) {
        throw ANSTE::Exceptions::Error("$pathToFile file does not exist");
    }

    my($file, $dir) = fileparse($pathToFile);
    my $outputFilePath = "/tmp/$file";

    # Check that there are no comments at the YAML file
    my @cppKeywords = qw(include if elif else endif);

    my @input = read_file($pathToFile);
    foreach my $line (@input) {
        if (index($line, "#") != -1) {
            my $isComment = 1;
            foreach my $keyword (@cppKeywords) {
                if (index($line, "#$keyword") != -1) {
                    $isComment = 0;
                    last;
                }
            }

            if ($isComment) {
                die("There was a comment line at $pathToFile file.\n$line\nCPP would have failed.");
            }
        }
    }

    # CPP process
    my $dataPath = ANSTE::Config->instance()->{dataPath};
    $dataPath = "$dataPath/tests";
    my $failure = system("cpp -w -I $dataPath -I tests/ $pathToFile $outputFilePath");

    if ($failure) {
        die "Couldn't process the file $pathToFile using CPP";
    }

    return $outputFilePath;
}

1;

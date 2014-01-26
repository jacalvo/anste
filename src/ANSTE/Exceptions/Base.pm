# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
# Copyright (C) 2005 Warp Networks S.L., DBS Servicios Informaticos S.L.
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

package ANSTE::Exceptions::Base;

use strict;
use warnings;

use Devel::StackTrace;

use overload (
    '""'     => 'stringify',
    fallback => 1
);

# Class: Base
#
#   Base class for ANSTE exceptions.
#

# Constructor: new
#
#   Constructor for Base class.
#
# Parameters:
#
#   text - String with the exception message.
#
# Returns:
#
#   A recently created <ANSTE::Exceptions::Base> object.
#
sub new
{
    my $class = shift;
    my $text = shift;
    my (%opts) = @_;

    my $self = { text => $text };
    if (exists $opts{silent} and $opts{silent}) {
        $self->{silent} = 1;
    } else {
        $self->{silent} = 0;
    }

    bless ($self, $class);
    return $self;
}

sub text
{
    my ($self) = @_;

    return $self->{text};
}

sub stringify
{
    my ($self) = @_;
    return $self->{text} ? $self->{text} : 'Died';
}

sub stacktrace
{
    my ($self) = @_;

    my $trace = new Devel::StackTrace();
    my $msg = $self->{text};
    $msg .= ' at ';
    $msg .= $trace->as_string();

    return $msg;
}

sub throw
{
    my $self = shift;

    unless (ref $self) {
        $self = $self->new(@_);
    }

    die $self;
}

sub toStderr
{
    my ($self) = @_;
    print STDERR "[ANSTE::Exceptions] ". $self->stringify() ."\n";
}

1;

# Copyright (C) 2014 Julio José García Martín <jjgarcia@zentyal.com>
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

package ANSTE::Virtualizer::OpenStack::Test;

use ANSTE::Virtualizer::OpenStack;

use parent 'Test::Class';

use Test::MockModule;
use Test::MockObject::Extends;
use Test::Exception;
use Test::More;

sub test_calculateInstanceSize_mini : Test
{
    my ($self) = @_;

    is(ANSTE::Virtualizer::OpenStack->_calculateInstanceSize(256), 0);
}

sub test_calculateInstanceSize_small_low_limit : Test
{
    my ($self) = @_;

    is(ANSTE::Virtualizer::OpenStack->_calculateInstanceSize(513), 1);
}

sub test_calculateInstanceSize_small : Test
{
    my ($self) = @_;

    is(ANSTE::Virtualizer::OpenStack->_calculateInstanceSize(1024), 1);
}

sub test_calculateInstanceSize_medium_low_limit : Test
{
    my ($self) = @_;

    is(ANSTE::Virtualizer::OpenStack->_calculateInstanceSize(1025), 2);
}

sub test_calculateInstanceSize_medium : Test
{
	my ($self) = @_;

    is(ANSTE::Virtualizer::OpenStack->_calculateInstanceSize(1500), 2);
}


END {
    ANSTE::Virtualizer::OpenStack::Test->runtests();
}
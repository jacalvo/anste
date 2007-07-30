#!/usr/bin/perl

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

use warnings;
use strict;

use System::Commands;

use Test::More tests => 5;

use constant IMAGE_NAME => 'baseimage';
use constant COPY_SCRIPT => 'data/conf/copyfiles.sh';

my $cmd = new System::Commands;

ok($cmd->createImage(IMAGE_NAME), "create base image");

ok($cmd->mountImage(IMAGE_NAME), "mount image");

ok($cmd->copyFiles(COPY_SCRIPT), "copy files");

ok($cmd->installBasePackages(), "install packages");

ok($cmd->umountImage(), "unmount image");

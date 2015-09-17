# Copyright (C) 2007-2011 José Antonio Calvo Fernández <jacalvo@zentyal.com>
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

use ANSTE::Scenario::BaseImage;
use ANSTE::Config;

use Test::More tests => 28;

sub testImage # (image)
{
    my ($image) = @_;
    my $name = $image->name();
    is($name, 'imageName', 'image name = imageName');
    my $desc = $image->desc();
    is($desc, 'imageDesc', 'image desc = imageDesc');

    my $memory = $image->memory();
    is($memory, 'imageMemory', 'image memory = imageMemory');
    my $size = $image->size();
    is($size, 'imageSize', 'image size = imageSize');
    my $arch = $image->arch();
    is($arch, 'imageArch', 'image arch = imageArch');
    my $swap = $image->swap();
    is($swap, 'imageSwap', 'image swap = imageSwap');
    my $cpus = $image->cpus();
    is($cpus, 'imageCpus', 'image cpus = imageCpus');

    my $installMethod = $image->installMethod();
    is($installMethod, 'copy', 'image installMethod = copy');
    my $installSource = $image->installSource();
    is($installSource, '/tmp', 'image installSource = /tmp');

    my $preScripts = $image->preScripts();
    is(scalar @{$preScripts}, 2, 'size pre-install scripts = 2');
    _checkScripts($preScripts);

    my $postScripts = $image->postScripts();
    is(scalar @{$postScripts}, 3, 'size post-install scripts = 3');
    _checkScripts($postScripts);

    my $packages = $image->packages();
    is(scalar @{$packages->list()}, 4, 'size packages = 4');
    _checkPackages($packages);

    my $mirror = $image->mirror();
    is($mirror, 'imageMirror', 'image mirror = imageMirror');

    my $files = $image->files();
    is(scalar @{$files->list()}, 2, 'size files = 2');
    _checkFiles($files);

    my $postTestsScripts = $image->postTestsScripts();
    is(scalar @{$postTestsScripts}, 2, 'size files = 2');
    _checkScripts($postTestsScripts);

}

sub _checkScripts # (scriptsToCheck)
{
    my ($scriptsToCheck) = @_;
    my $counter = 1;
    foreach my $script (@{$scriptsToCheck}) {
        is($script, 'script'.$counter, 'script'.$counter.' = script'.$counter);
        $counter++;
    }
}

sub _checkPackages # (packagesToCheck)
{
    my ($packagesToCheck) = @_;
    is(${$packagesToCheck->list()}[0], 'package1', 'package 1 = package1');
    is(${$packagesToCheck->list()}[1], 'package2', 'package 2 = package2');
    is(${$packagesToCheck->list()}[2], 'package3', 'package 3 = package3');
    is(${$packagesToCheck->list()}[3], 'postfix', 'package 4 = postfix');
}

sub _checkFiles# (filesToCheck)
{
    my ($filesToCheck) = @_;
    is(${$filesToCheck->list()}[0], 'file1', 'file 1 = file1');
    is(${$filesToCheck->list()}[1], 'file2', 'file 2 = file2');
}

my $imageYaml = new ANSTE::Scenario::BaseImage();
$imageYaml->loadFromFile("test.yaml");
testImage($imageYaml);

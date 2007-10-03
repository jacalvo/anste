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

package ANSTE::Manager::RSSWriter;

use strict;
use warnings;

use ANSTE::Manager::Config;
use ANSTE::Manager::Job;

use XML::RSS;

sub new # () returns new RSSWriter object
{
	my ($class) = @_;
	my $self = {};
	
	bless($self, $class);

	return $self;
}

sub write # (job, result)
{
    my ($self, $job, $result) = @_;

    my $user = $job->user();
    my $test = $job->test();

    my $rss = new XML::RSS(version => '2.0');

    my $config = ANSTE::Manager::Config->instance();
    my $host = $config->wwwHost();
    my $path = $config->wwwDir();

    my $file = "$path/$user/feed.xml";
    my $url = "http://$host/anste/$user";
    my $title = "Your test $test has finished";

    if (-r $file) {
        $rss->parsefile($file);
        $rss->add_item(title => $title, link => "$url/$test", mode => 'insert');
    }
    else {

        $rss->channel(title => "ANSTE tests for user $user",
                      link => $url,
                      description => "Tests results for user $user");
        $rss->add_item(title => $title, link => "$url/$result");
    }


    $rss->save($file);
}


1;

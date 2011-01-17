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

package ANSTE::Manager::MailNotifier;

use strict;
use warnings;

use ANSTE::Config;
use ANSTE::Manager::Job;
use ANSTE::Manager::Config;

use Mail::Sender;
use Text::Template;

# Class: MailNotifier
#
#   Notifies a user via email when his job has finished or failed.
#

# Constructor: new
#
#   Constructor for MailNotifier class.
#
# Returns:
#
#   A recently created <ANSTE::Manager::MailNotifier> object.
#
sub new # () returns new MailNotifier object
{
	my ($class) = @_;
	my $self = {};
	
	bless($self, $class);

	return $self;
}

# Method: sendNotify
#
#   Sends a notification of the given job with the given results url.
#
# Parameters:
#
#   job    - <ANSTE::Manager::Job> object.
#   result - String with the location of the result reports.
#
sub sendNotify # (job, result)
{    
    my ($self, $job, $result) = @_;

    my $user = $job->user();
    my $test = $job->test();
    my $email = $job->email();
    my $failed = $job->failed();

    my $config = ANSTE::Manager::Config->instance();
    my $subject = $config->mailSubject();
    my $address = $config->mailAddress();
    my $smtp = $config->mailSmtp();
    my $templFile = $failed ? $config->mailTemplateFailed() : 
                              $config->mailTemplate();
    my $wwwHost = $config->wwwHost();

    my $sender = new Mail::Sender {from => $address, smtp => $smtp};
    ref($sender) or 
        die "Error($sender) : $Mail::Sender::Error\n";

    ref($sender->Open({to => $email, subject => $subject})) or
        die "Error: $Mail::Sender::Error\n";

    my $tmplPath = ANSTE::Config->instance()->templatePath();
    my $template = new Text::Template(SOURCE => "$tmplPath/$templFile")
        or die "Couldn't construct template: $Text::Template::ERROR";

    my $results = "http://$wwwHost/anste/$user/$result/";

    if ($failed) {
        $results .= 'out.log';
    }

    my %vars = (user => $user,
                test => $test,
                results => $results);

    my $body = $template->fill_in(HASH => \%vars)
        or die "Couldn't fill in the template: $Text::Template::ERROR";

    print {$sender->GetHandle()} $body;
     
    $sender->Close;
}

1;

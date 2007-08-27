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

package ANSTE::Report::Writer;

use strict;
use warnings;

use ANSTE::Report::Report;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Exceptions::NotImplemented;

sub new # (report) returns new Write object
{
	my ($class, $report) = @_;
	my $self = {};

    defined $report or
        throw ANSTE::Exceptions::MissingArgument('report');

    $self->{report} = $report;
    $self->{file} = undef;

	bless($self, $class);

	return $self;
}

sub write # (file) 
{
    my ($self, $file) = @_;

    $self->{file} = $file; 

    $self->writeHeader();

    my $report = $self->{report};

    foreach my $suite (@{$report->suites()}) {
        my $name = $suite->suite()->name();
        my $desc = $suite->suite()->desc();
        $self->writeSuiteHeader($name, $desc);
        foreach my $test (@{$suite->tests()}) {
            $name = $test->test()->name();
            $desc = $test->test()->desc();
            $self->writeTestResult(name => $name,
                                   desc => $desc,
                                   value => $test->value(),
                                   log => $test->log(),
                                   video => $test->video());
        }
        $self->writeSuiteEnd();
    }

    $self->writeEnd();
}

sub writeHeader
{
    throw ANSTE::Exceptions::NotImplemented();
}    

sub writeEnd
{
    throw ANSTE::Exceptions::NotImplemented();
}    

sub writeSuiteHeader # (name, desc)
{
    throw ANSTE::Exceptions::NotImplemented();
}    

sub writeSuiteEnd
{
    throw ANSTE::Exceptions::NotImplemented();
}    

# Parameters:
# name
# desc
# value
# log
# video
sub writeTestResult # (%params)
{
    throw ANSTE::Exceptions::NotImplemented();
}    

1;

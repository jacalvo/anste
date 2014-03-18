# Copyright (C) 2014 Zentyal S.L.
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

package ANSTE::Image::Commands::Test;

use parent 'Test::Class';

use Test::MockModule;
use Test::MockObject::Extends;
use Test::Exception;
use Test::More;

use ANSTE::Image::Image;
use ANSTE::Image::Commands;
use ANSTE::Exceptions::Error;

our $alreadyReturned = 0;

sub test_setup : Test(setup)
{
	my ($self) = @_;
    $self->{image} = new ANSTE::Image::Image(name => 'Name',
                                    ip => '192.168.0.150',
                                    memory => '256M');
}

sub _mock_config_false
{
    my ($self) = @_;
    my $mockConfig = Test::MockObject->new();
    $mockConfig->set_false('wait')
               ->set_false('waitFail');
    return $mockConfig;
}

sub _mock_config_true
{
    my $mockConfig = Test::MockObject->new();
    $mockConfig->set_true('wait')
               ->set_true('waitFail');
    return $mockConfig;
}


sub test_executeScripts_with_wait_false_and_fail : Test(2)
{
	my ($self) = @_;

    my $system = new Test::MockModule('ANSTE::System::System');
    $system->mock('instance', undef);	
    my $virtualizer = new Test::MockModule('ANSTE::Virtualizer::Virtualizer');
    $virtualizer->mock('instance', undef);	
    
  
    my $config = new Test::MockModule('ANSTE::Config');
    $config->mock('instance', _mock_config_false);	
    
    my $cmd = new ANSTE::Image::Commands($self->{image}); 
    $cmd = Test::MockObject::Extends->new( $cmd );
    $cmd->mock('_executeSetupScript', sub { throw ANSTE::Exceptions::Error("Test error"); });
    
    throws_ok { $cmd->_executeSetup() } 'ANSTE::Exceptions::Error';
    $cmd->called_ok('_executeSetupScript');
}

sub test_executeScripts_with_wait_true_and_ok : Test(2)
{
    my ($self) = @_;

    my $system = new Test::MockModule('ANSTE::System::System');
    $system->mock('instance', undef);   
    my $virtualizer = new Test::MockModule('ANSTE::Virtualizer::Virtualizer');
    $virtualizer->mock('instance', undef);  
  
    my $config = new Test::MockModule('ANSTE::Config');
    $config->mock('instance', _mock_config_true);   
    
    my $cmd = new ANSTE::Image::Commands($self->{image}); 
    $cmd = Test::MockObject::Extends->new( $cmd );
    $cmd->mock('_executeSetupScript', sub { return 1; });
    
    cmp_ok($cmd->_executeSetup(), '==', 1);
    $cmd->called_ok('_executeSetupScript');
}

sub test_executeScripts_with_one_repetition_and_continue : Test(2)
{
    my ($self) = @_;

    my $system = new Test::MockModule('ANSTE::System::System');
    $system->mock('instance', undef);   
    my $virtualizer = new Test::MockModule('ANSTE::Virtualizer::Virtualizer');
    $virtualizer->mock('instance', undef);  
    my $anste = new Test::MockModule('ANSTE');
    $anste ->mock('askForRepeat', sub { return 0; });
    
  
    my $config = new Test::MockModule('ANSTE::Config');
    $config->mock('instance', _mock_config_true);   
    
    my $cmd = new ANSTE::Image::Commands($self->{image}); 
    $cmd = Test::MockObject::Extends->new( $cmd );
    $cmd->mock('_executeSetupScript', sub {
                throw ANSTE::Exceptions::Error("Test error");   
    });
    
    cmp_ok($cmd->_executeSetup(), '==', 1);
    $cmd->called_ok('_executeSetupScript');
}

sub test_executeScripts_with_one_repetition_and_repeat : Test(2)
{
    my ($self) = @_;

    my $system = new Test::MockModule('ANSTE::System::System');
    $system->mock('instance', undef);   
    my $virtualizer = new Test::MockModule('ANSTE::Virtualizer::Virtualizer');
    $virtualizer->mock('instance', undef);  
    my $anste = new Test::MockModule('ANSTE');
    $anste ->mock('askForRepeat', sub { return 1; });
    
  
    my $config = new Test::MockModule('ANSTE::Config');
    $config->mock('instance', _mock_config_true);   
    
    my $cmd = new ANSTE::Image::Commands($self->{image}); 
    $cmd = Test::MockObject::Extends->new( $cmd );
    $cmd->mock('_executeSetupScript', sub {
    	   if ( not $ANSTE::Image::Commands::Test::alreadyReturned )
    	   {
                $ANSTE::Image::Commands::Test::alreadyReturned = 1;
                throw ANSTE::Exceptions::Error("Test error");   
    	   }
    	   return 1;
    });
    
    cmp_ok($cmd->_executeSetup(), '==', 1);
    $cmd->called_pos_ok(2,'_executeSetupScript');
}

END {
    ANSTE::Image::Commands::Test->runtests();
}
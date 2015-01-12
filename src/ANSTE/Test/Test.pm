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

package ANSTE::Test::Test;

use strict;
use warnings;

use ANSTE::Exceptions::Error;
use ANSTE::Exceptions::MissingArgument;
use ANSTE::Config;

use YAML::XS;

# Class: Test
#
#   Contains the information of a test.
#

# Constructor: new
#
#   Constructor for Test class.
#
# Returns:
#
#   A recently created <ANSTE::Test::Test> object.
#
sub new
{
    my ($class, $suite) = @_;
    my $self = {};

    $self->{suite} = $suite;
    $self->{name} = '';
    $self->{desc} = '';
    $self->{script} = '';
    $self->{params} = '';
    $self->{env} = '';
    $self->{variables} = {};
    $self->{assert} = 'passed';
    $self->{type} = '';
    $self->{critical} = 0;
    $self->{executeAlways} = 0;
    $self->{reuseOnly} = 0;
    $self->{precondition} = 1;
    $self->{tries} = 1;

    bless($self, $class);

    return $self;
}

# Method: name
#
#   Gets the name of the test.
#
# Returns:
#
#   string - Name of the test.
#
sub name
{
    my ($self) = @_;

    return $self->{name};
}

# Method: setName
#
#   Sets the name for this test object to the given value.
#
# Parameters:
#
#   name - String with the name for the test.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setName
{
    my ($self, $name) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');

    $self->{name} = $name;
}

# Method: desc
#
#   Gets the description of the test.
#
# Returns:
#
#   string - Description of the test.
#
sub desc
{
    my ($self) = @_;

    return $self->{desc};
}

# Method: setDesc
#
#   Sets the description for this test object to the given value.
#
# Parameters:
#
#   name - String with the description for the test.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setDesc
{
    my ($self, $desc) = @_;

    defined $desc or
        throw ANSTE::Exceptions::MissingArgument('desc');

    $self->{desc} = $desc;
}

# Method: assert
#
#   Gets the assertion type of the test.
#
# Returns:
#
#   string - Name of the assertectory of this test.
#
sub assert
{
    my ($self) = @_;

    return $self->{assert};
}

# Method: setAssert
#
#   Sets the assertion type of the test.
#
# Parameters:
#
#   assert - String with 'passed' or 'failed'.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setAssert
{
    my ($self, $assert) = @_;

    defined $assert or
        throw ANSTE::Exceptions::MissingArgument('assert');

    $self->{assert} = $assert;
}

# Method: tries
#
#   Gets the number of times the test should be executed until it passes.
#
# Returns:
#
#   string - Name of the triesectory of this test.
#
sub tries
{
    my ($self) = @_;

    return $self->{tries};
}

# Method: setTries
#
#   Sets the number of times the test should be executed until it passes.
#
# Parameters:
#
#   tries - number of tries
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setTries
{
    my ($self, $tries) = @_;

    defined $tries or
        throw ANSTE::Exceptions::MissingArgument('tries');

    $self->{tries} = $tries;
}

# Method: host
#
#   Gets the host where the test have to be executed.
#
# Returns:
#
#   string - Hostname where execute the test.
#
sub host
{
    my ($self) = @_;

    return $self->{host};
}

# Method: setHost
#
#   Sets the execution host for this test object to the given value.
#
# Parameters:
#
#   name - String with the hostname where the test have to be executed.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setHost
{
    my ($self, $host) = @_;

    defined $host or
        throw ANSTE::Exceptions::MissingArgument('host');

    $self->{host} = $host;
}

# Method: externalHost
#
#   Gets a boolean value telling if the host is external to ANSTE
#
# Returns:
#
#   string - Whether the host is external or not
#
sub externalHost
{
    my ($self) = @_;

    return $self->{externalHost};
}

# Method: setExternalHost
#
#   Sets the boolean value telling if the host is external to ANSTE
#
# Parameters:
#
#   external - True if the host is external
#
sub setExternalHost
{
    my ($self, $external) = @_;

    $self->{externalHost} = $external;
}

# Method: port
#
#   Gets the port where the test have to be executed (web only).
#
# Returns:
#
#   string - port number of the web server to be tested
#
sub port
{
    my ($self) = @_;

    return $self->{port};
}

# Method: setPort
#
#   Sets the execution port for this test object to the given value.
#
# Parameters:
#
#   name - String with the port number of the webserver
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setPort
{
    my ($self, $port) = @_;

    defined $port or
        throw ANSTE::Exceptions::MissingArgument('port');

    $self->{port} = $port;
}

# Method: protocol
#
#   Gets the protocol (http or https) to be used (web only).
#
# Returns:
#
#   string - contains the protocol
#
sub protocol
{
    my ($self) = @_;

    return $self->{protocol};
}

# Method: setProtocol
#
#   Sets the protocol for this test object to the given value.
#
# Parameters:
#
#   name - String with the protocol (http or https)
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setProtocol
{
    my ($self, $protocol) = @_;

    defined $protocol or
        throw ANSTE::Exceptions::MissingArgument('protocol');

    $self->{protocol} = $protocol;
}

# Method: relativeURL
#
#   Gets the relative url to be used for the web test
#
# Returns:
#
#   string - contains the relative url
#
sub relativeURL
{
    my ($self) = @_;

    return $self->{relativeURL};
}

# Method: setRelativeUrl
#
#   Sets the relativeURL for this test object to the given value.
#
# Parameters:
#
#   name - String with the relative url
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setRelativeUrl
{
    my ($self, $relativeURL) = @_;

    defined $relativeURL or
        throw ANSTE::Exceptions::MissingArgument('relativeURL');

    $self->{relativeURL} = $relativeURL;
}

# Method: script
#
#   Gets the directory of the test scripts.
#
# Returns:
#
#   string - Name of the directory of this test.
#
sub script
{
    my ($self) = @_;

    return $self->{script};
}

# Method: setScript
#
#   Sets the directory for this test object to the given value.
#
# Parameters:
#
#   name - String with the relative path of the test directory.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setScript
{
    my ($self, $script) = @_;

    defined $script or
        throw ANSTE::Exceptions::MissingArgument('script');

    $self->{script} = $script;
}

# Method: shellcmd
#
#   Gets the directory of the test shellcmds.
#
# Returns:
#
#   string - Name of the directory of this test.
#
sub shellcmd
{
    my ($self) = @_;

    return $self->{shellcmd};
}

# Method: setShellCmd
#
#   Sets the directory for this test object to the given value.
#
# Parameters:
#
#   name - String with the relative path of the test directory.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setShellCmd
{
    my ($self, $shellcmd) = @_;

    defined $shellcmd or
        throw ANSTE::Exceptions::MissingArgument('shellcmd');

    $self->{shellcmd} = $shellcmd;
}

# Method: params
#
#   Gets the execution params for the test script.
#
# Returns:
#
#   string - String with the params to be pased to the test script.
#
sub params
{
    my ($self) = @_;

    return $self->{params};
}

# Method: setParams
#
#   Sets the execution params for the test script.
#
# Parameters:
#
#   params - String with the params to be pased to the test script.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#
sub setParams
{
    my ($self, $params) = @_;

    defined $params or
        throw ANSTE::Exceptions::MissingArgument('params');

    $self->{params} = $params;
}

# Method: env
#
#   Gets the environment string to be set before the test execution.
#
# Parameters:
#
#   sep - *optional* Separator character, usually ' ' or '\n'
#
# Returns:
#
#   string - String containing list of variables (FOO=bar BAR=foo)
#
sub env
{
    my ($self, $sep) = @_;

    unless ($sep) {
        $sep = ' ';
    }

    my $env = '';

    while (my ($name, $value) = each(%{$self->{variables}})) {
        $env .= "$name=\"$value\"$sep";
    }

    if ($env) {
        # Remove last space
        $env =~ s/ $//;
    }

    return $env;
}

# Method: setVariable
#
#   Sets a variable to be substituted on the template files.
#
# Parameters:
#
#   name  - Contains the name of the variable.
#   value - Contains the value of the variable.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if argument is not present
#   <ANSTE::Exceptions::InvalidOption> - throw if option is not valid
#
sub setVariable
{
    my ($self, $name, $value) = @_;

    defined $name or
        throw ANSTE::Exceptions::MissingArgument('name');
    defined $value or
        throw ANSTE::Exceptions::MissingArgument('value');

    if (not ANSTE::Validate::identifier($name)) {
        throw ANSTE::Exceptions::InvalidOption('name', $name);
    }

    $self->{variables}->{$name} = $value;
}

# Method: addVariables
#
#     Add a set of variables and values
#
#   Parameters:
#
#     vars - hashref with variables as keys
#
sub addVariables
{
    my ($self, $vars) = @_;

    foreach my $name (keys %{$vars}) {
        my $value = $vars->{$name};
        unless ($value) {
            $value = '';
        }
        if (substr ($value, 0, 1) eq '$') {
            my $var = substr ($value, 1, length ($value));
            if (exists $self->{variables}->{$var}) {
                $value = $self->{variables}->{$var};
            }
        }
        $self->setVariable($name, $value);
    }
}

# Method: variables
#
#   Gets the variables to be substituted on the template files.
#
# Returns:
#
#   hash ref - Reference to the hash of variables
#
sub variables
{
    my ($self) = @_;

    return $self->{variables};
}

# Method: type
#
#   Gets the type of the test
#
# Returns:
#
#   string - the type of the test
#
sub type
{
    my ($self) = @_;

    return $self->{type};
}

# Method: setType
#
#   Specifies the type of this test
#
sub setType
{
    my ($self, $type) = @_;
    $self->{type} = $type;
}

# Method: critical
#
#   Gets if the test is critical and should interrupt the process
#
# Returns:
#
#   boolean - true if the test is critical, false if not
#
sub critical
{
    my ($self) = @_;

    return $self->{critical};
}

# Method: setCritical
#
#   Specifies if the test is critical and should interrupt the process
#
sub setCritical
{
    my ($self, $critical) = @_;
    $self->{critical} = $critical;
}

# Method: executeAlways
#
#   Gets if the test should be executed always
#
# Returns:
#
#   boolean - true if the test should be executed always
#
sub executeAlways
{
    my ($self) = @_;

    return $self->{executeAlways};
}

# Method: setExecuteAlways
#
#   Specifies if the test should be executed always
#
sub setExecuteAlways
{
    my ($self, $executeAlways) = @_;
    $self->{executeAlways} = $executeAlways;
}

# Method: reuseOnly
#
#   Gets if the test should be executed only with -reuse
#
# Returns:
#
#   boolean - true if the test should be only in reuse mode
#
sub reuseOnly
{
    my ($self) = @_;

    return $self->{reuseOnly};
}

# Method: setReuseOnly
#
#   Specifies if the test should be executed only in reuse mode
#
sub setReuseOnly
{
    my ($self, $reuseOnly) = @_;
    $self->{reuseOnly} = $reuseOnly;
}

# Method: precondition
#
#   Gets if this test has passed the required precondition
#
# Returns:
#
#   boolean - true if passed, false if not
#
sub precondition
{
    my ($self) = @_;

    return $self->{precondition};
}

# Method: setPrecondition
#
#   Sets this test passes the required precondition
#
# Parameters:
#
#   ok - boolean that indicates precondition passe
#
sub setPrecondition
{
    my ($self, $ok) = @_;

    $self->{precondition} = $ok;
}

sub reloadVars
{
    my ($self) = @_;

    my $suite = $self->{suite};
    return unless defined ($suite);

    my $file = $suite->{file};
    my $varfile = $suite->{varfile};

    my $tempProcessedFile = ANSTE::Util::processYamlFile($file);

    my ($suiteYAML) = YAML::XS::LoadFile($tempProcessedFile);
    system("rm -f $tempProcessedFile");

    my $global = $suiteYAML->{global};
    my $newGlobal = undef;
    my $newVars = undef;

    if ($varfile) {
        my ($vars) = YAML::XS::LoadFile($varfile);
        $newGlobal = $vars->{global};

        foreach my $element (@{$vars->{tests}}) {
            if ($element->{name} eq $self->{name}) {
                $newVars = $element->{vars};
                last;
            }
        }
    }

    foreach my $test (@{$suiteYAML->{tests}}) {
        if ($test->{name} eq $self->{name}) {
            $self->addVariables($global);
            $self->addVariables($newGlobal) if $newGlobal;
            $self->loadYAML($test);
            $self->addVariables($newVars) if $newVars;
            last;
        }
    }
}

sub loadYAML
{
    my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    my $type = $test->{type};
    if ($type) {
        $self->setType($type);
    }
    my $critical = ($test->{critical} or $test->{setup});
    if ($critical) {
        $self->setCritical(1);
    }
    if ($test->{'execute-always'}) {
        $self->setExecuteAlways(1);
    }
    if ($test->{'reuse-only'}) {
        $self->setReuseOnly(1);
    }

    my $name = $test->{name};
    $self->setName($name);
    my $desc = $test->{desc};
    if ($desc) {
        $self->setDesc($desc);
    } else {
        $self->setDesc('');
    }

    my $host = $test->{host};
    if (defined ($type) and ($type eq 'host')) {
        $host = 'localhost';
    }
    $self->setHost($host);
    my $validHost = defined ($host);

    unless ($validHost or ($type eq 'host')) {
        throw ANSTE::Exceptions::Error("No valid host found for test $name.");
    }

    my $externalHost = $test->{external_host};
    if ($externalHost) {
        $self->setExternalHost($externalHost);
    }

    my $port = $test->{port};
    if ($port) {
        $self->setPort($port);
    }

    my $protocol = $test->{protocol};
    if ($protocol) {
        unless (($protocol eq 'http') or ($protocol eq 'https')) {
            throw ANSTE::Exceptions::Error("Invalid protocol for test $name.");
        }
        $self->setProtocol($protocol);
    }

    my $relativeURL = $test->{relative_url};
    if ($relativeURL) {
        $self->setRelativeUrl($relativeURL);
    }

    my $script = $test->{script};
    if ($script) {
        $self->setScript($script);
    }

    my $shellcmd = $test->{shellcmd};
    if ($shellcmd) {
        $self->setShellCmd($shellcmd);
    }

    if ($script and $shellcmd) {
        throw ANSTE::Exceptions::Error("Both script and shellcmd defined for test $name.");
    }

    my $assert = $test->{assert};
    if ($assert) {
        $self->setAssert($assert);
    }

    my $tries = $test->{tries};
    if ($tries) {
        $self->setTries($tries);
    }

    my $params = $test->{params};
    if ($params) {
        if ($type eq 'web') {
            throw ANSTE::Exceptions::Error("Wrong <params> element in $name. Web tests can't receive params, just variables.");
        }
        $self->setParams($params);
    }

    $self->addVariables($test->{vars});

    my $config = ANSTE::Config->instance();
    my $configVars = $config->variables();
    foreach my $name (keys %{$configVars}) {
        my $value = $configVars->{$name};
        if ($value) {
            $name =~ tr/-/_/;
            $self->setVariable("GLOBAL_$name", $value);
        }
    }

    # Add also comm/gateway and comm/first-address as a variable
    my $gateway = $config->gateway();
    $self->setVariable("COMM_gateway", $gateway);
    my $firstAddress = $config->firstAddress();
    $self->setVariable("COMM_firstAddress", $firstAddress);
    my $commIface = $config->commIface();
    $self->setVariable("COMM_commIface", $commIface);
}

1;

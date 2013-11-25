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

use XML::DOM;

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
sub new # returns new Test object
{
    my ($class) = @_;
    my $self = {};

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
    $self->{precondition} = 1;

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
sub name # returns name string
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
sub setName # name string
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
sub desc # returns desc string
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
sub setDesc # desc string
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
sub assert # returns assert string
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
sub setAssert # assert string
{
    my ($self, $assert) = @_;

    defined $assert or
        throw ANSTE::Exceptions::MissingArgument('assert');

    $self->{assert} = $assert;
}

# Method: host
#
#   Gets the host where the test have to be executed.
#
# Returns:
#
#   string - Hostname where execute the test.
#
sub host # returns host string
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
sub setHost # host string
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
sub setExternalHost # host string
{
    my ($self, $external) = @_;

    $self->{externalHost} = $external;
}

# Method: port
#
#   Gets the port where the test have to be executed (selenium only).
#
# Returns:
#
#   string - port number of the web server to be tested
#
sub port # returns port string
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
sub setPort # port string
{
    my ($self, $port) = @_;

    defined $port or
        throw ANSTE::Exceptions::MissingArgument('port');

    $self->{port} = $port;
}

# Method: protocol
#
#   Gets the protocol (http or https) to be used (selenium only).
#
# Returns:
#
#   string - contains the protocol
#
sub protocol # returns protocol string
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
sub setProtocol # protocol string
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
sub script # returns script string
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
sub setScript # script string
{
    my ($self, $script) = @_;

    defined $script or
        throw ANSTE::Exceptions::MissingArgument('script');

    $self->{script} = $script;
}

# Method: params
#
#   Gets the execution params for the test script.
#
# Returns:
#
#   string - String with the params to be pased to the test script.
#
sub params # returns params string
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
sub setParams # params string
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
# Returns:
#
#   string - String containing list of variables (FOO=bar BAR=foo)
#
sub env # returns params string
{
    my ($self) = @_;

    my $env = '';

    while (my ($name, $value) = each(%{$self->{variables}})) {
        $env .= "$name=\"$value\" ";
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
sub setVariable # (name, value)
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

# Method: precondition
#
#   Gets if this test has passed the required precondition
#
# Returns:
#
#   boolean - true if passed, false if not
#
sub precondition # returns boolean
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

# Method: load
#
#   Loads the information contained in the given XML node representing
#   the test into this object.
#
# Parameters:
#
#   node - <XML::DOM::Element> object containing the test data.
#
# Exceptions:
#
#   <ANSTE::Exceptions::MissingArgument> - throw if parameter is not present
#   <ANSTE::Exceptions::InvalidType> - throw if parameter has wrong type
#
sub loadXML
{
    my ($self, $node) = @_;

    defined $node or
        throw ANSTE::Exceptions::MissingArgument('node');

    if (not $node->isa('XML::DOM::Element')) {
        throw ANSTE::Exceptions::InvalidType('node',
                'XML::DOM::Element');
    }

    my $configVars = ANSTE::Config->instance()->variables();

    my $type = $node->getAttribute('type');
    if ($type) {
        $self->setType($type);
    }
    my $critical = $node->getAttribute('critical');
    if ($critical) {
        $self->setCritical(1);
    }

    my $nameNode = $node->getElementsByTagName('name', 0)->item(0);
    my $name = $nameNode->getFirstChild()->getNodeValue();
    $self->setName($name);

    my $descNode = $node->getElementsByTagName('desc', 0)->item(0);
    my $nodeDesc= $descNode->getFirstChild();
    my $desc='';
    if (defined $nodeDesc) {
        $desc = $nodeDesc->getNodeValue();
    }
    $self->setDesc($desc);

    my $validHost = 0;
    my $hostNodes = $node->getElementsByTagName('host', 0);
    for (my $i = 0; $i < $hostNodes->getLength(); $i++) {
        my $hostNode = $hostNodes->item($i);
        my $hostPrecondition = 1;
        my $var = $hostNode->getAttribute('var');
        if ($var) {
            my $expectedValue = $hostNode->getAttribute('eq');
            my $value = $configVars->{$var};
            unless (defined $value) {
                $value = 0;
            }
            $hostPrecondition = $expectedValue eq $value;
        }
        if ($hostPrecondition) {
            my $host = $hostNode->getFirstChild()->getNodeValue();
            $self->setHost($host);
            $validHost = 1;
            last;
        }
    }
    unless ($validHost or ($type eq 'host')) {
        throw ANSTE::Exceptions::Error("No valid host found for test $name.");
    }

    my $portNode = $node->getElementsByTagName('port', 0)->item(0);
    if ($portNode) {
        my $port = $portNode->getFirstChild()->getNodeValue();
        $self->setPort($port);
    }

    my $protocolNode = $node->getElementsByTagName('protocol', 0)->item(0);
    if ($protocolNode) {
        my $protocol = $protocolNode->getFirstChild()->getNodeValue();
        unless (($protocol eq 'http') or ($protocol eq 'https')) {
            throw ANSTE::Exceptions::Error("Invalid protocol for test $name.");
        }
        $self->setProtocol($protocol);
    }

    my $scriptNode = $node->getElementsByTagName('script', 0)->item(0);
    if ($scriptNode) {
        my $script = $scriptNode->getFirstChild()->getNodeValue();
        $self->setScript($script);
    }

    my $assertNode = $node->getElementsByTagName('assert', 0)->item(0);
    if ($assertNode) {
        my $assert = $assertNode->getFirstChild()->getNodeValue();
        $self->setAssert($assert);
    }

    my $paramsNode = $node->getElementsByTagName('params', 0)->item(0);
    if ($paramsNode) {
        if ($type eq 'web') {
            throw ANSTE::Exceptions::Error("Wrong <params> element in $name. Web tests can't receive params, just variables.");
        }
        my $params = $paramsNode->getFirstChild()->getNodeValue();
        $self->setParams($params);
    }

    my $varNodes = $node->getElementsByTagName('var', 0);
    for (my $i = 0; $i < $varNodes->getLength(); $i++) {
        my $name = $varNodes->item($i)->getAttribute('name');
        my $value = $varNodes->item($i)->getAttribute('value');
        $self->setVariable($name, $value);
    }

    # Check if all preconditions are satisfied
    my $preconditionNodes = $node->getElementsByTagName('precondition', 0);
    for (my $i = 0; $i < $preconditionNodes->getLength(); $i++) {
        my $var = $preconditionNodes->item($i)->getAttribute('var');
        my $expectedValue = $preconditionNodes->item($i)->getAttribute('eq');
        my $value = $configVars->{$var};
        unless (defined $value) {
            $value = 0;
        }
        if ($value ne $expectedValue) {
            $self->setPrecondition(0);
            last;
        }
    }
}

sub loadYAML
{
    my ($self, $test) = @_;

    defined $test or
        throw ANSTE::Exceptions::MissingArgument('test');

    my $configVars = ANSTE::Config->instance()->variables();

    my $type = $test->{type};
    if ($type) {
        $self->setType($type);
    }
    my $critical = $test->{critical};
    if ($critical) {
        $self->setCritical(1);
    }

    my $name = $test->{name};
    $self->setName($name);
    my $desc = $test->{desc};
    if ($desc) {
        $self->setDesc($desc);
    } else {
        $self->setDesc('');
    }

    # FIXME: preconditions not yet supported (they will have a new syntax)
    my $host = $test->{host};
    $self->setHost($host);
    my $validHost = defined ($host);
#    my $validHost = 0;
#    my $hostNodes = $node->getElementsByTagName('host', 0);
#    for (my $i = 0; $i < $hostNodes->getLength(); $i++) {
#        my $hostNode = $hostNodes->item($i);
#        my $hostPrecondition = 1;
#        my $var = $hostNode->getAttribute('var');
#        if ($var) {
#            my $expectedValue = $hostNode->getAttribute('eq');
#            my $value = $configVars->{$var};
#            unless (defined $value) {
#                $value = 0;
#            }
#            $hostPrecondition = $expectedValue eq $value;
#        }
#        if ($hostPrecondition) {
#            my $host = $hostNode->getFirstChild()->getNodeValue();
#            $self->setHost($host);
#            $validHost = 1;
#            last;
#        }
#    }
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

    my $assert = $test->{assert};
    if ($assert) {
        $self->setAssert($assert);
    }

    my $params = $test->{params};
    if ($params) {
        if ($type eq 'web') {
            throw ANSTE::Exceptions::Error("Wrong <params> element in $name. Web tests can't receive params, just variables.");
        }
        $self->setParams($params);
    }

    my $vars = $test->{vars};
    foreach my $name (keys %{$vars}) {
        my $value = $vars->{$name};
        if ($value) {
            $self->setVariable($name, $value);
        } else {
            $self->setVariable($name, "");
        }
    }

    #FIXME
    # Check if all preconditions are satisfied
#    my $preconditionNodes = $node->getElementsByTagName('precondition', 0);
#    for (my $i = 0; $i < $preconditionNodes->getLength(); $i++) {
#        my $var = $preconditionNodes->item($i)->getAttribute('var');
#        my $expectedValue = $preconditionNodes->item($i)->getAttribute('eq');
#        my $value = $configVars->{$var};
#        unless (defined $value) {
#            $value = 0;
#        }
#        if ($value ne $expectedValue) {
#            $self->setPrecondition(0);
#            last;
#        }
#    }
}

1;

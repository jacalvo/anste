#!/bin/sh

# Wait for ebox start
sleep 10

# FIXME: Change this to only add rules that enable anste communication
for i in INPUT OUTPUT FORWARD
do
    iptables -P $i ACCEPT
done

iptables -I INPUT -j ACCEPT

# Temporary workaround
cat << EOF > /usr/share/ebox/stubs/apache.mas
<%args>
        \$port
        \$group
        \$user
        \$serverroot
        \$debug => 'no'
</%args>

ServerType standalone
ServerRoot <% \$serverroot %>
LockFile /var/lock/apache-perl.lock
PidFile /var/run/apache-perl.pid
ScoreBoardFile /var/run/apache-perl.scoreboard

Timeout 300
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 15
MinSpareServers 1
MaxSpareServers 2
StartServers 2
MaxClients 3
MaxRequestsPerChild 100
AddDefaultCharset utf-8

# begin modules
ClearModuleList
AddModule mod_so.c
AddModule mod_macro.c
LoadModule config_log_module /usr/lib/apache/1.3/mod_log_config.so
LoadModule mime_magic_module /usr/lib/apache/1.3/mod_mime_magic.so
LoadModule mime_module /usr/lib/apache/1.3/mod_mime.so
LoadModule dir_module /usr/lib/apache/1.3/mod_dir.so
LoadModule cgi_module /usr/lib/apache/1.3/mod_cgi.so
LoadModule alias_module /usr/lib/apache/1.3/mod_alias.so
LoadModule rewrite_module /usr/lib/apache/1.3/mod_rewrite.so
LoadModule access_module /usr/lib/apache/1.3/mod_access.so
LoadModule auth_module /usr/lib/apache/1.3/mod_auth.so
LoadModule expires_module /usr/lib/apache/1.3/mod_expires.so
LoadModule setenvif_module /usr/lib/apache/1.3/mod_setenvif.so
#LoadModule ssl_module /usr/lib/apache/1.3/mod_ssl.so
AddModule mod_perl.c
#AddModule mod_ssl.c
# end modules

Port <% 80 %>
User <% \$user %>
Group <% \$group %>

ServerAdmin webmaster@localhost
ServerName localhost

DocumentRoot /usr/share/ebox/www/

<Directory />
    Options SymLinksIfOwnerMatch
    AllowOverride None
</Directory>


<Directory /usr/share/ebox/www/>
    Options Indexes MultiViews
    AllowOverride None
    Order allow,deny
    Allow from all
</Directory>

UseCanonicalName Off
TypesConfig /etc/mime.types
DefaultType text/plain

<IfModule mod_mime_magic.c>
    MIMEMagicFile /usr/share/misc/file/magic.mime
</IfModule>

HostnameLookups Off

ErrorLog /var/lib/ebox/log/error.log
LogLevel warn

LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" \"%{fore
nsic-id}n\"" combined

CustomLog /var/lib/ebox/log/access.log combined

<IfModule mod_backtrace.c>
 EnableExceptionHook On
</IfModule>

<IfModule mod_whatkilledus.c>
 EnableExceptionHook On
</IfModule>

ServerSignature Off
ServerTokens Min
AddDefaultCharset on

<IfModule mod_ssl.c>
SSLEngine on
SSLProtocol all
SSLCipherSuite HIGH:MEDIUM

SSLCertificateFile /etc/ebox/ssl.crt/ebox.cert
SSLCertificateKeyFile /etc/ebox/ssl.key/ebox.key
</IfModule>

<IfModule mod_setenvif.c>
    BrowserMatch "Mozilla/2" nokeepalive
    BrowserMatch "MSIE 4\.0b2;" nokeepalive downgrade-1.0 force-response-1.0
    BrowserMatch "RealPlayer 4\.0" force-response-1.0
    BrowserMatch "Java/1\.0" force-response-1.0
    BrowserMatch "JDK/1\.0" force-response-1.0
</IfModule>

Alias /data/ /usr/share/ebox/www/
ScriptAlias /ebox/ /usr/share/ebox/cgi/

% if (\$debug eq 'yes') {
PerlInitHandler Apache::Reload
% }
PerlWarn On

PerlRequire "startup.pl"

PerlModule EBox::Auth
PerlSetVar EBoxPath /
PerlSetVar EBoxLoginScript /ebox/Login/Index
PerlSetVar EBoxSatisfy Any
PerlSetVar AuthCookieDebug 0
<Files LOGIN>
        AuthType EBox::Auth
        AuthName EBox
        SetHandler perl-script
        PerlHandler EBox::Auth->login
</Files>

<Directory /usr/share/ebox/cgi/>
   <IfModule mod_ssl.c>
           SSLOptions +StdEnvVars
   </IfModule>

#        AuthType EBox::Auth
#        AuthName EBox
#        PerlModule      EBox::Auth
#        PerlAuthenHandler EBox::Auth->authenticate
#        PerlAuthzHandler  EBox::Auth->authorize
#        require valid-user
        SetHandler perl-script
        PerlHandler Apache::Registry
        PerlSendHeader On
        AllowOverride None
        Options +ExecCGI
        Order allow,deny
        Allow from all
</Directory>

RewriteEngine On

RewriteRule ^/ebox$ /ebox/ [R]
RewriteRule ^/$ /ebox/ [R]
RewriteRule ^/ebox/ebox.cgi$ [S,PT]
RewriteRule ^/ebox/(.*) /ebox/ebox.cgi [E=script:\$1,PT,L]
EOF

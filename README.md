  ANSTE
==========
Copyright &copy; 2007-2014 José Antonio Calvo Fernández <jacalvo@zentyal.com>

About
-----
Advanced Network Services Testing Environment is a tool to create complex network scenarios using virtual machines and run script or WebDriver tests on them.

You can find more information at http://www.anste.org

Install
-------

From PPA repository:

* `echo 'deb http://ppa.launchpad.net/zentyal/anste/ubuntu precise main' > /etc/apt/sources.list.d/anste.list`
* `apt-get update`
* `apt-get install anste`

Building from source:

* Download the code, from [Github](https://github.com/Zentyal/anste)
* Check build dependencies with `dpkg-checkbuilddeps` and install them with `apt-get install` tool
* Add zentyal/anste PPA repository if dependencies are missing (libtrycatch-lite-perl libattempt-perl)
* Execute `make installdeb` in the root of the folder
* Install the missing dependencies using `apt-get -f install`

Bug tracker
-----------

Found a bug? Don't hesitate to open an issue at:

https://github.com/Zentyal/anste/issues


  ANSTE
==========
Copyright &copy; 2007-2012 José Antonio Calvo Fernández <jacalvo@zentyal.com>

About
-----
Advanced Network Services Testing Environment, that create scenarios using kvm and libvirt and run scripts or selenium tests on them.

Install
-------

Install guide:

* Download the code, from [Github](https://github.com/Zentyal/anste)
* Add `deb http://ppa.launchpad.net/zentyal/anste/ubuntu precise main` to your sources.list
* Check build dependencies with `dpkg-checkbuilddeps` and install them with `apt-get install` tool
* Execute `make deb` in the root of the folder
* Install with `dpkg -i anste_0.9_all.deb` the debian package generated
* Install the dependencies needed using `apt-get -f install`
* Download [Selenium RC](http://seleniumhq.org/projects/remote-control/) and modify the configuration to search for it in the folder you have it.

Bug tracker
-----------

Have a bug? Please create an issue here on GitHub

https://github.com/Zentyal/anste/issues


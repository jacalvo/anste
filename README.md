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
* Execute `make deb` in the root of the folder
* Install with `dpkg -i anste_0.9_all.deb` the debian package generated
* Install the dependencies needed using `apt-get -f install`
* Install [Selenium WebDriver](http://seleniumhq.org/docs/03_webdriver.html) for python. Our recomendation it's to use `pip install selenium`

Additionally, you'll have to install the [Attempt CPAN Module](http://search.cpan.org/~markf/Attempt-1.01/lib/Attempt.pm). Use `cpan Attempt`
We will remove this last dependency and integrate the module with the project properly.

Bug tracker
-----------

Have a bug? Please create an issue here on GitHub

https://github.com/Zentyal/anste/issues


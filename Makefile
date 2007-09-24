PREFIX = /usr/local
DATADIR = $(PREFIX)/share/anste
LIBDIR = $(PREFIX)/lib
SBINDIR = $(PREFIX)/sbin
BINDIR = $(PREFIX)/bin
CONFDIR = /etc/anste
LIBPERL = $(PREFIX)/share/perl5
VERSION = `cat VERSION`
EXPORT = anste-$(VERSION)

distclean:
	rm -rf $(EXPORT)
	rm -f anste-$(VERSION).tar.gz

export:
	svn export . $(EXPORT) 
	find $(EXPORT)/src/lib -name 't' -print | xargs rm -rf

dist: export
	tar cvvzf anste-$(VERSION).tar.gz $(EXPORT)

install-anste:
	install -d $(DESTDIR)$(SBINDIR)
	install -m755 src/bin/anste $(DESTDIR)$(SBINDIR)
	install -d $(DESTDIR)$(CONFDIR)
	install -m644 src/data/anste.conf $(DESTDIR)$(CONFDIR)
	install -m644 src/data/xen-config.tmpl $(DESTDIR)$(CONFDIR)
	install -d $(DESTDIR)$(DATADIR)
	install -d src/data/images $(DESTDIR)$(DATADIR)/images
	install -m644 src/data/images/* $(DESTDIR)$(DATADIR)/images
	install -d $(DESTDIR)$(DATADIR)/profiles
	install -m644 src/data/profiles/* $(DESTDIR)$(DATADIR)/profiles
	install -d $(DESTDIR)$(DATADIR)/scenarios
	install -m644 src/data/scenarios/* $(DESTDIR)$(DATADIR)/scenarios
	install -d $(DESTDIR)$(DATADIR)/scripts
	install -m755 src/data/scripts/* $(DESTDIR)$(DATADIR)/scripts
	install -d $(DESTDIR)$(DATADIR)/tests
	cp -a src/data/tests/ebox $(DESTDIR)$(DATADIR)/tests
	cp -a src/data/tests/sample $(DESTDIR)$(DATADIR)/tests
	install -d $(DESTDIR)$(LIBPERL)/ANSTE
	install -m644 src/lib/ANSTE/Config.pm $(DESTDIR)$(LIBPERL)/ANSTE
	install -m644 src/lib/ANSTE/Validate.pm $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Comm $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Deploy $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Image $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Report $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Scenario $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/ScriptGen $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Test $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/System $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Virtualizer $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/lib/ANSTE/Exceptions $(DESTDIR)$(LIBPERL)/ANSTE
	install -d $(DESTDIR)$(DATADIR)/deploy
	install -d $(DESTDIR)$(DATADIR)/deploy/modules
	ln -s $(DESTDIR)$(LIBPERL)/ANSTE $(DESTDIR)$(DATADIR)/deploy/modules/ANSTE
	install -d $(DESTDIR)$(DATADIR)/deploy/bin
	install -m755 src/data/deploy/bin/* $(DESTDIR)$(DATADIR)/deploy/bin
	install -d $(DESTDIR)$(DATADIR)/deploy/scripts
	install -m755 src/data/deploy/scripts/* $(DESTDIR)$(DATADIR)/deploy/scripts

install-anste-manager:
	install -d $(DESTDIR)$(SBINDIR)
	install -m755 src/bin/anste-manager $(DESTDIR)$(SBINDIR)
	install -d $(DESTDIR)$(CONFDIR)
	install -m644 src/data/anste-manager.conf $(DESTDIR)$(CONFDIR)
	install -d $(DESTDIR)$(LIBPERL)/ANSTE
	install -d $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/JobLauncher.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/Job.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/JobWaiter.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/MailNotifier.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/Server.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/Config.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager

install-anste-job: 
	install -d $(DESTDIR)$(BINDIR)
	install -m755 src/bin/anste-job $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(LIBPERL)/ANSTE
	install -d $(DESTDIR)$(LIBPERL)/ANSTE/Manager
	install -m644 src/lib/ANSTE/Manager/Client.pm $(DESTDIR)$(LIBPERL)/ANSTE/Manager

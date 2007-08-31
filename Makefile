PREFIX = /usr/local
DATADIR = $(PREFIX)/share/anste
LIBDIR = $(PREFIX)/lib
BINDIR = $(PREFIX)/sbin
CONFDIR = /etc/anste
LIBPERL = $(PREFIX)/share/perl5
EXPORT = /tmp/anste

dist:
	svn export src $(EXPORT) 
	find $(EXPORT)/lib -name 't' -print | xargs rm -rf

cleandist:
	rm -rf $(EXPORT)

install: dist
	install -d $(DESTDIR)$(BINDIR)
	install -m755 $(EXPORT)/bin/anste $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(CONFDIR)
	install -m644 $(EXPORT)/data/anste.conf $(DESTDIR)$(CONFDIR)
	install -m644 $(EXPORT)/data/xen-config.tmpl $(DESTDIR)$(CONFDIR)
	install -d $(DESTDIR)$(DATADIR)
	install -d $(EXPORT)/data/images $(DESTDIR)$(DATADIR)/images
	install -m644 $(EXPORT)/data/images/* $(DESTDIR)$(DATADIR)/images
	install -d $(DESTDIR)$(DATADIR)/profiles
	install -m644 $(EXPORT)/data/profiles/* $(DESTDIR)$(DATADIR)/profiles
	install -d $(DESTDIR)$(DATADIR)/scenarios
	install -m644 $(EXPORT)/data/scenarios/* $(DESTDIR)$(DATADIR)/scenarios
	install -d $(DESTDIR)$(DATADIR)/scripts
	install -m755 $(EXPORT)/data/scripts/* $(DESTDIR)$(DATADIR)/scripts
	install -d $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/data/tests/ebox $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/data/tests/sample $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/lib $(DESTDIR)$(LIBPERL)
	install -d $(DESTDIR)$(DATADIR)/deploy
	install -d $(DESTDIR)$(DATADIR)/deploy/modules
	ln -s $(DESTDIR)$(LIBPERL)/ANSTE $(DESTDIR)$(DATADIR)/deploy/modules/ANSTE
	install -d $(DESTDIR)$(DATADIR)/deploy/bin
	install -m755 $(EXPORT)/data/deploy/bin/* $(DESTDIR)$(DATADIR)/deploy/bin
	install -d $(DESTDIR)$(DATADIR)/deploy/scripts
	install -m755 $(EXPORT)/data/deploy/scripts/* $(DESTDIR)$(DATADIR)/deploy/scripts

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
	install $(EXPORT)/bin/anste $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(CONFDIR)
	install $(EXPORT)/data/anste.conf $(DESTDIR)$(CONFDIR)
	install $(EXPORT)/data/xen-config.tmpl $(DESTDIR)$(CONFDIR)
	install -d $(DESTDIR)$(DATADIR)
	install -d $(EXPORT)/data/images $(DESTDIR)$(DATADIR)/images
	install $(EXPORT)/data/images/* $(DESTDIR)$(DATADIR)/images
	install -d $(DESTDIR)$(DATADIR)/profiles
	install $(EXPORT)/data/profiles/* $(DESTDIR)$(DATADIR)/profiles
	install -d $(DESTDIR)$(DATADIR)/scenarios
	install $(EXPORT)/data/scenarios/* $(DESTDIR)$(DATADIR)/scenarios
	install -d $(DESTDIR)$(DATADIR)/scripts
	install $(EXPORT)/data/scripts/* $(DESTDIR)$(DATADIR)/scripts
	install -d $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/data/tests/ebox $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/data/tests/sample $(DESTDIR)$(DATADIR)/tests
	cp -a $(EXPORT)/lib $(DESTDIR)$(LIBPERL)

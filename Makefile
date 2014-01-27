PREFIX = /usr/local
DATADIR = $(PREFIX)/share/anste
LIBDIR = $(PREFIX)/lib
SBINDIR = $(PREFIX)/sbin
BINDIR = $(PREFIX)/bin
VERSION = $(shell head -1 ChangeLog)
EXPORT = ../anste-$(VERSION)

ifeq ($(PREFIX),/usr/local)
	LIBPERL = $(PREFIX)/lib/site_perl
else
	LIBPERL = $(PREFIX)/share/perl5
endif

tests:
	src/tools/check-syntax
	prove -r --timer -l -Isrc

distclean:
	@rm -f anste-$(VERSION).tar.gz
	@rm -f anste-$(VERSION)
	@rm -f anste_$(VERSION)*
	@rm -f *anste_*.deb

export: distclean
	rm -rf $(EXPORT)/
	mkdir -p $(EXPORT)/
	cp -r * $(EXPORT)/
	find $(EXPORT)/src -name 't' -print | xargs rm -rf

dist: export
	tar cvvzf anste-$(VERSION).tar.gz $(EXPORT)

deb: tests dist
	cd $(EXPORT) && dpkg-buildpackage -rfakeroot -uc -us
	mv ../*anste_*.deb .

installdeb: deb
	dpkg -i *anste_*.deb
	$(MAKE) distclean

install:
	install -d $(DESTDIR)$(SBINDIR)
	install -m755 src/bin/anste $(DESTDIR)$(SBINDIR)
	install -m755 src/bin/anste-clean $(DESTDIR)$(SBINDIR)
	install -m755 src/bin/anste-snapshot $(DESTDIR)$(SBINDIR)
	install -d $(DESTDIR)$(BINDIR)
	install -m755 src/bin/anste-connect $(DESTDIR)$(BINDIR)
	install -d $(DESTDIR)$(DATADIR)
	install -d data/images $(DESTDIR)$(DATADIR)/images
	install -m644 data/images/* $(DESTDIR)$(DATADIR)/images
	install -d $(DESTDIR)$(DATADIR)/profiles
	install -m644 data/profiles/* $(DESTDIR)$(DATADIR)/profiles
	install -d $(DESTDIR)$(DATADIR)/scenarios
	cp -a data/scenarios/* $(DESTDIR)$(DATADIR)/scenarios
	install -d data/files $(DESTDIR)$(DATADIR)/files
	cp -a data/files/* $(DESTDIR)$(DATADIR)/files
	install -d $(DESTDIR)$(DATADIR)/scripts
	install -m755 data/scripts/* $(DESTDIR)$(DATADIR)/scripts
	install -d $(DESTDIR)$(DATADIR)/tests
	cp -a data/tests/sample $(DESTDIR)$(DATADIR)/tests
	cp -a data/tests/websample $(DESTDIR)$(DATADIR)/tests
	cp -a data/tests/routers $(DESTDIR)$(DATADIR)/tests
	install -d $(DESTDIR)$(DATADIR)/common
	install -d $(DESTDIR)$(LIBPERL)/ANSTE
	install -m644 src/ANSTE/Config.pm $(DESTDIR)$(LIBPERL)/ANSTE
	install -m644 src/ANSTE/Status.pm $(DESTDIR)$(LIBPERL)/ANSTE
	install -m644 src/ANSTE/Validate.pm $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Comm $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Deploy $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Image $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Report $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Scenario $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/ScriptGen $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Test $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/System $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Virtualizer $(DESTDIR)$(LIBPERL)/ANSTE
	cp -a src/ANSTE/Exceptions $(DESTDIR)$(LIBPERL)/ANSTE
	install -d $(DESTDIR)$(DATADIR)/deploy
	install -d $(DESTDIR)$(DATADIR)/deploy/modules
	install -d $(DESTDIR)$(DATADIR)/deploy/bin
	install -m755 data/deploy/bin/* $(DESTDIR)$(DATADIR)/deploy/bin
	install -d $(DESTDIR)$(DATADIR)/deploy/scripts
	install -m755 data/deploy/scripts/* $(DESTDIR)$(DATADIR)/deploy/scripts
# Create symlink if we're not building the debian package
ifneq (,$(findstring debian,$(DESTDIR)))
	ln -sf $(DESTDIR)$(LIBPERL)/ANSTE \
		   $(DESTDIR)$(DATADIR)/deploy/modules/ANSTE
endif

uninstall:
	rm -f $(DESTDIR)$(SBINDIR)/anste
	rm -rf $(DESTDIR)$(DATADIR)/images
	rm -rf $(DESTDIR)$(DATADIR)/profiles
	rm -rf $(DESTDIR)$(DATADIR)/scenarios
	rm -rf $(DESTDIR)$(DATADIR)/files
	rm -rf $(DESTDIR)$(DATADIR)/scripts
	rm -rf $(DESTDIR)$(DATADIR)/tests
	rm -rf $(DESTDIR)$(DATADIR)/common
	rm -f $(DESTDIR)$(LIBPERL)/ANSTE/Config.pm
	rm -f $(DESTDIR)$(LIBPERL)/ANSTE/Validate.pm
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Comm
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Deploy
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Image
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Report
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Scenario
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/ScriptGen
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Test
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/System
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Virtualizer
	rm -rf $(DESTDIR)$(LIBPERL)/ANSTE/Exceptions
	rm -rf $(DESTDIR)$(DATADIR)/deploy

pkg: tests dist
	cd $(EXPORT) &&  dpkg-buildpackage -rfakeroot -uc -us


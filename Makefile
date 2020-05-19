PREFIX=/usr
UDEVDIR=$(shell pkg-config --variable=udevdir udev)
SBINDIR=$(PREFIX)/sbin
CONFDIR=/etc/mdevctl.d
MANDIR=$(PREFIX)/share/man
NAME=mdevctl
VERSION=0.$(shell git rev-list --count HEAD)
NVFMT=$(NAME)-$(VERSION)

files: mdevctl 60-mdevctl.rules mdevctl.8 \
	Makefile COPYING README.md mdevctl.spec.in

archive: files mdevctl.spec
	git archive --prefix=$(NVFMT)/ HEAD > $(NVFMT).tar
	gzip -f -9 $(NVFMT).tar

mdevctl.spec: tag mdevctl.spec.in files
	sed -e 's:#VERSION#:$(VERSION):g' < mdevctl.spec.in > mdevctl.spec
	PREV=""; \
	for TAG in `git tag | sort -Vr`; do \
	    if [ -n "$$PREV" ]; then \
	    git log --format="- %h (\"%s\")" $$TAG..$$PREV >> mdevctl.spec; \
	    fi; \
	    isodate=`git log -1 --format="%cd" --date=iso`; \
	    changelog_date=`date --date="$$isodate" +"%a %b %d %Y"`; \
	    git log -1 --format="%n* $$changelog_date %aN <%ae> - $$TAG-1" $$TAG >> mdevctl.spec; \
	    PREV=$$TAG; \
	done; \
	git log --format="- %h (\"%s\")" $$TAG >> mdevctl.spec

srpm: mdevctl.spec archive
	rpmbuild -bs --define "_sourcedir $(PWD)" --define "_specdir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)" mdevctl.spec

rpm: mdevctl.spec archive
	rpmbuild -bb --define "_sourcedir $(PWD)" --define "_specdir $(PWD)" --define "_builddir $(PWD)" --define "_srcrpmdir $(PWD)" --define "_rpmdir $(PWD)" mdevctl.spec

install:
	mkdir -p $(DESTDIR)$(CONFDIR)
	mkdir -p $(DESTDIR)$(UDEVDIR)/rules.d/
	install -m 644 60-mdevctl.rules $(DESTDIR)$(UDEVDIR)/rules.d/
	mkdir -p $(DESTDIR)$(SBINDIR)
	install -m 755 mdevctl $(DESTDIR)$(SBINDIR)/
	ln -sf mdevctl $(DESTDIR)$(SBINDIR)/lsmdev
	mkdir -p $(DESTDIR)$(MANDIR)/man8
	install -m 644 mdevctl.8 $(DESTDIR)$(MANDIR)/man8/
	ln -sf mdevctl.8  $(DESTDIR)$(MANDIR)/man8/lsmdev.8

clean:
	rm -f mdevctl.spec *.src.rpm noarch/*.rpm *.tar.gz

tag:
	git tag -l $(VERSION) | grep -q $(VERSION) || git tag $(VERSION)

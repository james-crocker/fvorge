# This Makefile builds and signs the debian package for cloud-orchestrator and updates the apt repo
TARGET = fvorge
JOB = fvorge
DISTRO = everest
RM = /bin/rm
SHELL = /bin/bash
SHOWSHELL = $(shell echo $$0)
REPO = $(shell echo $${REPO:-/data/repo})
OFFICIAL_VERSION_FILE = /var/lib/jenkins/jobs/$(JOB)/workspace/ubuntu/version
OFFICIAL_VERSION = $(shell cat $(OFFICIAL_VERSION_FILE))

.PHONY: clean pkgprep

all: repotgt

# handle version strings like:
# 1.0.50-1234~alpha
# 1.0.50-1234~beta
# 1.0.50-1234
# OFFICIAL_PLUS_DATE versions will be like:
# 1.0.50-1234~alpha.1395067931
# 1.0.50-1234.1395067931
bumpversion:
	@if [ -n "$$OFFICIAL_PLUS_DATE" ] ; \
	then \
		if [ -z "$(OFFICIAL_VERSION)" ] ; \
		then \
			echo -e "\nERROR: cannot find official build package version file: $(OFFICIAL_VERSION_FILE)\n" ; \
			exit 1 ; \
		fi ; \
		epoch=`date +'%s'` ; \
		echo "$(OFFICIAL_VERSION).$$epoch" > version ; \
		exit 0 ; \
	fi; \
	[ ! -f version ] && echo "1.0.0-1" > version || true ; \
	s=`cat version | sed -n 's/^.*\(~.*\)/\1/p'` ; \
	echo "suffix: $$s" ; \
	m=`cat version | sed "s/^.*-\([[:digit:]]*\)$$s$$/\1/"` ; \
	echo "previous revision: $$m" ; \
	n=`expr "$$m" + 1` ; \
	echo "current revision: $$n" ; \
	sed -i "s/^\(.*\)-\([[:digit:]]*\)$$s$$/\1-$$n$$s/" version

modversion: bumpversion
	v=`cat version` ; \
	sed "s/%VERSION%/$$v/g" < $(TARGET)/DEBIAN/control.in > $(TARGET)/DEBIAN/control

pkgprep:
	[ -x pkgprep ] && ./pkgprep $(TARGET)

package: pkgprep modversion
	dpkg-deb --build $(TARGET)

sign: package
	@dpkg-sig -s builder $(TARGET).deb ; \
	if [ $$? -ne 0 ] ; \
	then \
		echo -e "\nERROR: dpkg-sig failed, do you need to 'gpg --gen-key' ?\n" ; \
		exit 1 ; \
	fi

backup: sign
	@[ -z "$$PKG_BACKUP_DIR" ] && exit 0 ; \
	find $$PKG_BACKUP_DIR -type f -name $(TARGET)_\* -mtime +30 -exec rm {} \; ; \
	cp $(TARGET).deb $$PKG_BACKUP_DIR/$(TARGET)_`cat version`.deb

# these are split purposely, so that 'make repo' can run standalone, e.g., on repo.us.sios.com
repotgt: backup repo

repo:
	reprepro -Vb $(REPO) includedeb $(DISTRO) $(TARGET).deb ; \
	if [ $$? -ne 0 ] ; \
	then \
		echo -e "\ndo you need to modify the line 'DebOverride: /data/repo/override/override' in $(REPO)/conf/distributions ?\n" ; \
		exit 1 ; \
	fi ; \
	apt-ftparchive release $(REPO) ; \
	for f in `find $(REPO) -name Release` ; \
	do \
		d=`dirname $$f` ; \
		rm -f $$d/InRelease ; \
		gpg --clearsign -o $$d/InRelease $$d/Release ; \
		rm -f $$d/Release.gpg ; \
		gpg -abs -o $$d/Release.gpg $$d/Release ; \
	done

clean:
	$(RM) -f $(TARGET).deb
	$(RM) -f $(TARGET)/DEBIAN/control
	[ -x pkgclean ] && ./pkgclean $(TARGET)

#
# below are helpful utilities for checking/setting up repos
#
showrepo:
	@echo Your shell is: $(SHOWSHELL)
	@echo Your apt repo target is: $(REPO)
	@echo To change this, set the REPO env var in your .bashrc and . .bashrc
	@echo Typically you would set REPO to $$HOME/repo

# make a copy of the official repo (only works on ci.sc.steeleye.com build server)
mkrepo:
	@if [ $(REPO) == /data/repo ]; \
	then \
		echo "Can't overwrite main repo in /data/repo. Set REPO env var to change your repo dir." ; \
		exit 1 ; \
	fi ; \
	if [ ! -d /data/repo ]; \
	then \
		echo "Sorry, can't copy from main repo /data/repo, not found." ; \
		echo "Please create your repo from an existing remote repo with 'make copyrepo'" ; \
		exit 1 ; \
	fi ; \
	mkdir -p $(REPO) ; \
	cp -a /data/repo/conf $(REPO)/ ; \
	cp -a /data/repo/override $(REPO)/ ; \
	sed -i 's@^DebOverride:.*@DebOverride: '$(REPO)/override/override'@' $(REPO)/conf/distributions ; \
	echo Your repo in $(REPO) is ready for builds

# copy a local repo to a remote system via scp
copyrepo:
	@if [ ! -d "$$LOCALREPO" ]; \
	then \
		echo "Please set LOCALREPO to the local repo directory that you wish to copy" ; \
		exit 1 ; \
	fi ; \
	if [ -z "$$REMOTEREPOURL" ]; \
	then \
		echo "Please set REMOTEREPOURL to the remote repo URL, e.g., $$USER@remote:$$HOME/repo" ; \
		exit 1 ; \
	fi ; \
	mkdir -p /tmp/make-copyrepo.$$$$ ; \
	cp -a $$LOCALREPO/conf /tmp/make-copyrepo.$$$$/ ; \
	REMOTESSH=$$(echo $$REMOTEREPOURL | cut -d: -f1) ; \
	REMOTEDIR=$$(echo $$REMOTEREPOURL | cut -d: -f2-) ; \
	sed -i 's@^DebOverride:.*@DebOverride: '$$REMOTEDIR/override/override'@' /tmp/make-copyrepo.$$$$/conf/distributions ; \
	ssh $$REMOTESSH mkdir -p $$REMOTEDIR ; \
	scp -r /tmp/make-copyrepo.$$$$/conf $$REMOTEREPOURL/ ; \
	scp -r $$LOCALREPO/override $$REMOTEREPOURL/ ; \
	rm -rf /tmp/make-copyrepo.$$$$ ; \
	echo "Remote repo created for $$REMOTESSH in $$REMOTEDIR"

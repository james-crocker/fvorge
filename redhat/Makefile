# Copyright (c) 2013 SIOS Technology Corp.  All rights reserved.

# This file is part of FVORGE.

# FVORGE is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# FVORGE is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with FVORGE.  If not, see <http://www.gnu.org/licenses/>.
    
include make.incl

SPEC=fvorge.spec

PKGVER=$(shell git --git-dir=../../fvorge/.git tag | tail -n 1)
PKGREL=1

PKGS=\
	fvorge-$(PKGVER)-$(PKGREL).noarch.rpm

all:
	@echo "Nothing to do for '$@' in `pwd`"

debug:
	echo $(PKGVER)
	echo $(PKGS)

package: $(PKGS)
	mkdir -p $(BINDIR)
	cp $(PKGS) $(BINDIR)

$(PKGS):
	mkdir -p $(BUILDDIR)
	rm -rf /var/tmp/pkgbuild-$(shell whoami)
	$(RPMBUILD) -bb --define "_sourcedir `pwd`/../fvorge" \
		--define "_prefix /opt/fvorge" \
		--define "_tmppath /var/tmp/pkgbuild-$(shell whoami)" \
		--define "version $(PKGVER)" \
		--define "release $(PKGREL)" \
		$(RPM_OPT) $(LOCAL_RPM_OPT) $(SPEC)
	DEST=`pwd`;(cd $(BINDIR);cp $(PKGS) $$DEST)

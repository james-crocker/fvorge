#!/bin/sh

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

ROOT=${ROOT:-`pwd`}
export ROOT

#
# Remove old package so we don't copy them into the repo
#

rm -rf $ROOT/rpm/RPMS/noarch/*rpm

#
# Build the package
#

(cd redhat;make -s package)

#
# Copy package to the yum repo
#

REPODEST=$ROOT/latest

# Clean out old packages
rm -rf $REPODEST
mkdir -m 0755 -p $REPODEST

# Copy the package over from the build tree
cd $ROOT/rpm/RPMS
for rpm in `find . -name '*rpm'`
do
        cp -u $rpm $REPODEST
done

# Make sure the packages are readable
chmod -R ugo+r $REPODEST

# Create the repo files
if [ -x /usr/bin/createrepo ]
then
	createrepo -q $REPODEST
fi

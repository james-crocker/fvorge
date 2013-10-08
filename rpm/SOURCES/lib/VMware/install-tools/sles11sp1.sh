#!/bin/sh

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

VMKEYS=/opt/fvorge/lib/VMware/install-tools/keys
VMESXVER=latest
DISTRO=sles11.1
ARCH=x86_64

mkdir -p ${VMKEYS}
cd ${VMKEYS}
#wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub
#wget http://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub
rpm --import VMWARE-PACKAGING-GPG-DSA-KEY.pub
rpm --import VMWARE-PACKAGING-GPG-RSA-KEY.pub
zypper addservice --type YUM http://packages.vmware.com/tools/esx/${VMESXVER}/${DISTRO}/${ARCH} vmware-tools-collection
zypper --non-interactive install vmware-tools-esx-kmods-default vmware-tools-esx-nox

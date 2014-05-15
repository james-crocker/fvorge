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

#
# chkconfig: - 99 01
# description: Apply FVORGE OVF Properties 
#
### BEGIN INIT INFO
# Provides: fvorge
# Required-Start: $syslog
# Required-Stop: $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Apply FVORGE OVF Properties
# Short-Description: Apply FVORGE OVF Properties
### END INIT INFO

RETVAL=0
FVORGE_BIN=/opt/fvorge/sbin/fvorge

# See how we were called.
case "$1" in
  start|reload)
	if [ -x ${FVORGE_BIN} ]; then
		${FVORGE_BIN}
	else
		RETVAL=2
	fi
	echo
	;;
  *)
	echo "Usage: fvorge {start|reload}"
	exit 2
esac
exit ${RETVAL}

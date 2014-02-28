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

package OVF::Service::Security::AppArmor::Vars;

use strict;
use warnings;

our %apparmor;
my %common;

$common{'SLES'} = {
	'files' => {
		'apparmor-syslog' => {
			path  => '/etc/apparmor.d/sbin.syslog-ng',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					before => {
						1 => {
							regex   => q{^\s*/dev/log\s+\S+\s*,},
							content => q{  /var/run/utmp kr,}
						}
					  }
				}
			}
		}
	},
	'init' => {
		'apparmor' => {
			path  => '/etc/init.d/boot.apparmor',
			stop  => '/etc/init.d/boot.apparmor stop',
			start => '/etc/init.d/boot.apparmor start',
			off   => 'yast2 --ncurses runlevel delete service="boot.apparmor" runlevels=B',
			on    => 'yast2 --ncurses runlevel add service="boot.apparmor" runlevels=B'
		}
	},
	'task' => { 'reparse' => [ 'apparmor_parser -r /etc/apparmor.d/sbin.syslog-ng' ] }
};

$apparmor{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$apparmor{'SLES'}{11}{0}{'x86_64'} = $common{'SLES'};
$apparmor{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$apparmor{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

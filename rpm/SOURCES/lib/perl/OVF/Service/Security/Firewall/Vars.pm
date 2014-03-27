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

package OVF::Service::Security::Firewall::Vars;

use strict;
use warnings;

our %firewall;
my %common;

$common{'RHEL'} = {
	'init' => {
		'iptables' => {
			path  => '/etc/init.d/iptables',
			stop  => '/etc/init.d/iptables stop',
			start => '/etc/init.d/iptables start',
			off   => 'chkconfig iptables off',
			on    => 'chkconfig iptables on',
		},
		'ip6tables' => {
			path  => '/etc/init.d/ip6tables',
			stop  => '/etc/init.d/ip6tables stop',
			start => '/etc/init.d/ip6tables start',
			off   => 'chkconfig ip6tables off',
			on    => 'chkconfig ip6tables on',
		}
	}
};

$common{'SLES'} = {
	'init' => {
		'firewall' => {
			path  => '',
			stop  => 'rcSuSEfirewall2 stop',
			start => 'rcSuSEfirewall2 start',
			off   => 'yast2 --ncurses firewall startup manual',
			on    => 'yast2 --ncurses firewall startup atboot',
		}
	}
};

$common{'Ubuntu'} = {
    'init' => {
        'ufw' => {
            path  => '/usr/sbin/ufw',
            stop  => '/usr/sbin/ufw disable',
            start => '/usr/sbin/ufw enable',
            off   => '/usr/sbin/ufw disable',
            on    => '/usr/sbin/ufw enable',
        }
    }
};

$firewall{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$firewall{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$firewall{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$firewall{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$firewall{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$firewall{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$firewall{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$firewall{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$firewall{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$firewall{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$firewall{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$firewall{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$firewall{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$firewall{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$firewall{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$firewall{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$firewall{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$firewall{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$firewall{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

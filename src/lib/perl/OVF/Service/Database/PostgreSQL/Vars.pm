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

package OVF::Service::Database::PostgreSQL::Vars;

use strict;
use warnings;

use Storable;

use lib '../../../../../perl';
use OVF::Vars::Common;

our %pgsql;
my %common;

$common{'RHEL'} = {
	'packages'    => [ 'postgresql-server', 'postgresql', 'postgresql-libs' ],
	'directories' => {
		'database' => {
			path  => '<PGSQL_DATA_DIRECTORY>',
			save  => 0,
			chmod => 755,
			chown => 'postgres',
			chgrp => 'postgres'
		},
	},
	'files' => {
		'pg_hba.conf' => {
			path  => '<PGSQL_DATA_DIRECTORY>/pg_hba.conf',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					tail    => 1,
					content => q{host    all         all         0.0.0.0/0             trust
host    all         all         ::/0                  trust}
				}
			}
		},
		'start-pgsql' => {
			path    => $OVF::Vars::Common::sysVars{'fvorge'}{bin} . '/start-pgsql',
			save    => 0,
			replace => 1,
			chmod   => 750,
			apply   => {
				1 => {
					replace => 1,
					content => q(
ip addr add `host <PGSQL_VIRTUAL_IP> | awk '{print $4;}'`/<PGSQL_VIRTUAL_IP_PREFIX> dev <PGSQL_VIRTUAL_IP_DEV>
su - postgres -c "postgres -D <PGSQL_DATA_DIRECTORY> -i -h <PGSQL_VIRTUAL_IP> -p <PGSQL_PORT> &")
				}
			}
		}
	},
	'mount' => {
		'source' => '<PGSQL_DEVICE>',
		'target' => '<PGSQL_DATA_DIRECTORY>',
		'fstype' => '<PGSQL_FS_TYPE>',
	},
	'init' => {
		'postgresql' => {
			path  => '/etc/init.d/postgresql',
			stop  => '/etc/init.d/postgresql stop',
			start => '/etc/init.d/postgresql start',
			off   => 'chkconfig postgresql off',
			on    => 'chkconfig postgresql on',
		}
	},
	'task' => {
		'cleardir'      => [ 'cd <PGSQL_DATA_DIRECTORY>; rm -rf * .*' ],
		'chgattr'       => [ 'chown postgres <PGSQL_DATA_DIRECTORY>; chgrp postgres <PGSQL_DATA_DIRECTORY>' ],
		'initdb'        => [ 'su - postgres -c "initdb -D <PGSQL_DATA_DIRECTORY>"' ],
		'start'         => [ 'su - postgres -c "postgres -D <PGSQL_DATA_DIRECTORY> -i -h <PGSQL_VIRTUAL_IP> -p <PGSQL_PORT> &"' ],
		'open-firewall' => [
			q{iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport <PGSQL_PORT> -j ACCEPT;ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport <PGSQL_PORT> -j ACCEPT},
			q{/etc/init.d/iptables save;/etc/init.d/ip6tables save}
		],
		'close-firewall' => [
			q{iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport <PGSQL_PORT> -j ACCEPT;ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport <PGSQL_PORT> -j ACCEPT},
			q{/etc/init.d/iptables save;/etc/init.d/ip6tables save}
		]
	},
	'virtualip' => {
		'ip'     => q(<PGSQL_VIRTUAL_IP>),
		'prefix' => q(<PGSQL_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<PGSQL_VIRTUAL_IP_DEV>)
	}
};

$common{'SLES'}                         = Storable::dclone( $common{'RHEL'} );
$common{'SLES'}{task}{'open-firewall'}  = [ 'yast2 --ncurses firewall services add service=service:postgresql zone=EXT' ];
$common{'SLES'}{task}{'close-firewall'} = [ 'yast2 --ncurses firewall services remove service=service:postgresql zone=EXT' ];

$pgsql{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$pgsql{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$pgsql{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$pgsql{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$pgsql{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pgsql{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pgsql{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$pgsql{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$pgsql{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$pgsql{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$pgsql{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pgsql{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pgsql{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pgsql{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pgsql{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$pgsql{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$pgsql{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

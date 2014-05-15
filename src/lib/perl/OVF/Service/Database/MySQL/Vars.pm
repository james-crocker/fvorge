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

package OVF::Service::Database::MySQL::Vars;

use strict;
use warnings;
use Storable;

use lib '../../../../../perl';
use OVF::Vars::Common;

our %mysql;
my %common;

$common{'RHEL'} = {
	'packages'    => [ 'mysql-server', 'mysql', 'mysql-libs' ],
	'directories' => {
		'database' => {
			path  => '<MYSQL_DATA_DIRECTORY>',
			save  => 0,
			chmod => 755,
			chown => 'mysql',
			chgrp => 'mysql'
		}
	},
	'files' => {
		'my.cnf' => {
			path  => '/etc/my.cnf',
			save  => 1,
			apply => {
				1 => {
					replace => 1,
					content => q([mysqld]
bind-address=<MYSQL_VIRTUAL_IP>
port=<MYSQL_PORT>
datadir=<MYSQL_DATA_DIRECTORY>/data
socket=<MYSQL_SOCKET_PATH>
user=mysql
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

[mysqld_safe]
log-error=<MYSQL_LOG_ERROR_PATH>
pid-file=<MYSQL_PID_FILE_PATH>)
				}
			}
		},
		'start-mysql' => {
			path  => $OVF::Vars::Common::sysVars{'fvorge'}{bin} . '/start-mysql',
			save  => 0,
			chmod => 750,
			apply => {
				1 => {
					replace => 1,
					content => q(
ip addr add `host <MYSQL_VIRTUAL_IP> | awk '{print $4;}'`/<MYSQL_VIRTUAL_IP_PREFIX> dev <MYSQL_VIRTUAL_IP_DEV>
su - mysql -c "mysqld_safe &")
				}
			}
		}
	},
	'mount' => {
		'source' => '<MYSQL_DEVICE>',
		'target' => '<MYSQL_DATA_DIRECTORY>',
		'fstype' => '<MYSQL_FS_TYPE>',
	},
	'init' => {
		'mysqld' => {
			path  => '/etc/init.d/mysqld',
			stop  => '/etc/init.d/mysqld stop',
			start => '/etc/init.d/mysqld start',
			off   => 'chkconfig mysqld off',
			on    => 'chkconfig mysqld on',
		}
	},
	'task' => {
		'cleardir'       => [ 'cd <MYSQL_DATA_DIRECTORY>; rm -rf * .*' ],
		'chgattr'        => [ 'chown mysql <MYSQL_DATA_DIRECTORY>; chgrp mysql <MYSQL_DATA_DIRECTORY>' ],
		'initdb'         => [ 'mysql_install_db --user=mysql --datadir=<MYSQL_DATA_DIRECTORY>/data' ],
		'start'          => [ 'mysqld_safe &' ],
		'open-firewall'  => [ q{iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport <MYSQL_PORT> -j ACCEPT;ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport <MYSQL_PORT> -j ACCEPT}, q{/etc/init.d/iptables save;/etc/init.d/ip6tables save} ],
		'close-firewall' => [ q{iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport <MYSQL_PORT> -j ACCEPT;ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport <MYSQL_PORT> -j ACCEPT}, q{/etc/init.d/iptables save;/etc/init.d/ip6tables save} ]
	},
	'virtualip' => {
		'ip'     => q(<MYSQL_VIRTUAL_IP>),
		'prefix' => q(<MYSQL_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<MYSQL_VIRTUAL_IP_DEV>)
	}
};

$common{'RHEL'}{5}{packages} = [ 'mysql-server', 'mysql' ];

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );
$common{'SLES'}{packages} = [ 'mysql', 'mysql-client' ];
$common{'SLES'}{task}{'open-firewall'}  = [ 'yast2 --ncurses firewall services add service=service:mysql zone=EXT' ];
$common{'SLES'}{task}{'close-firewall'} = [ 'yast2 --ncurses firewall services remove service=service:mysql zone=EXT' ];
$common{'SLES'}{init}                   = {
	'mysql' => {
		path  => '/etc/init.d/mysql',
		stop  => '/etc/init.d/mysql stop',
		start => '/etc/init.d/mysql start',
		off   => 'chkconfig mysql off',
		on    => 'chkconfig mysql on',
	}
};

$mysql{'RHEL'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$mysql{'RHEL'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$mysql{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$mysql{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$mysql{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$mysql{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$mysql{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$mysql{'CentOS'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$mysql{'CentOS'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$mysql{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$mysql{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$mysql{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$mysql{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$mysql{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$mysql{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$mysql{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$mysql{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$mysql{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$mysql{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

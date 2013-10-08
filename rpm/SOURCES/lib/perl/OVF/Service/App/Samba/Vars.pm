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

package OVF::Service::App::Samba::Vars;

use strict;
use warnings;
use Storable;

use lib '../../../../../perl';
use OVF::Vars::Common;

our %samba;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'samba', 'samba-client' ],
	'groups' => { 'sp-smbgrp' => { gid => 6002 } },
	'users'  => {
		'sp-smbusr' => {
			uid     => 6002,
			gid     => 6002,
			homeDir => '/home/sp-smbusr',
			passwd  => 'mysmbpass',
			shell   => '/bin/false',
			comment => 'SIOS SAMBA User'
		}
	},
	'directories' => {
		'lockdir' => {
			path  => '<SAMBA_LOCK_PATH>',
			save  => 0,
			chmod => 755,
			chgrp => 'root',
			chown => 'root',
		},
		'sharedir' => {
			path  => '<SAMBA_SHARE_PATH>',
			save  => 0,
			chmod => 755,
			chgrp => 'sp-smbgrp',
			chown => 'sp-smbusr',
		},
		'piddir' => {
			path  => '<SAMBA_PID_PATH>',
			save  => 0,
			chmod => 755,
			chgrp => 'root',
			chown => 'root',
		},
	},
	'files' => {
		'smb.conf' => {
			path  => '/etc/samba/smb.conf',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'sp-smb.conf' => {
			path  => '<SAMBA_SMB_CONF_PATH>',
			save  => 0,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{[global]
workgroup = <SAMBA_SERVER_WORKGROUP>
netbios name = <SAMBA_NETBIOS_NAME>
interfaces = <SAMBA_VIRTUAL_IP>
bind interfaces only = yes
lock directory = <SAMBA_LOCK_PATH>
pid directory = <SAMBA_PID_PATH>
log file = <SAMBA_LOG_PATH>
security = user
passdb backend = tdbsam
read only = no
name resolve order = host bcast
printing = bsd

[<SAMBA_SHARE_NAME>]
path = <SAMBA_SHARE_PATH>
valid users = sp-smbusr
guest ok = no
}
				}
			}
		},
		'start-smb' => {
			path  => $OVF::Vars::Common::sysVars{'fvorge'}{bin} . '/start-smb',
			save  => 0,
			chmod => 750,
			apply => {
				1 => {
					replace => 1,
					content => q(ip addr add `host <SAMBA_VIRTUAL_IP> | awk '{print $4;}'`/<SAMBA_VIRTUAL_IP_PREFIX> dev <SAMBA_VIRTUAL_IP_DEV>
smbd -D -s <SAMBA_SMB_CONF_PATH>
nmbd -D -s <SAMBA_SMB_CONF_PATH>)
				}
			}
		}
	},
	'mount' => {
		'source' => '<SAMBA_DEVICE>',
		'target' => '<SAMBA_SHARE_PATH>',
		'fstype' => '<SAMBA_FS_TYPE>',
	},
	'task' => {
		'cleardir'      => [ 'cd <SAMBA_SHARE_PATH>; rm -rf * .*' ],
		'rmdistrofile'  => [ q{rm /etc/samba/smb.conf} ],
		'touchprintcap' => [ q{touch /etc/printcap} ],
		'smbpasswd'     => [ q{echo -e "mysmbpass\nmysmbpass" | smbpasswd -s -c <SAMBA_SMB_CONF_PATH> -a sp-smbusr} ],
		'start'         => {
			'smbd' => [ q{smbd -D -s <SAMBA_SMB_CONF_PATH>} ],
			'nmbd' => [ q{nmbd -D -s <SAMBA_SMB_CONF_PATH>} ]
		},
		'open-firewall' => [
			q{iptables -A INPUT -p udp -m udp --dport 137 -j ACCEPT},
			q{iptables -A INPUT -p udp -m udp --dport 138 -j ACCEPT},
			q{iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT},
			q{iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT},
			q{ip6tables -A INPUT -p udp -m udp --dport 137 -j ACCEPT},
			q{ip6tables -A INPUT -p udp -m udp --dport 138 -j ACCEPT},
			q{ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT},
			q{ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT},
			q{/etc/init.d/iptables save;/etc/init.d/ip6tables save}
		],
		'close-firewall' => [
			q{iptables -D INPUT -p udp -m udp --dport 137 -j ACCEPT},
			q{iptables -D INPUT -p udp -m udp --dport 138 -j ACCEPT},
			q{iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT},
			q{iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT},
			q{ip6tables -D INPUT -p udp -m udp --dport 137 -j ACCEPT},
			q{ip6tables -D INPUT -p udp -m udp --dport 138 -j ACCEPT},
			q{ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport 139 -j ACCEPT},
			q{ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport 445 -j ACCEPT},
			q{/etc/init.d/iptables save;/etc/init.d/ip6tables save}
		]
	},
	'virtualip' => {
		'ip'     => q(<SAMBA_VIRTUAL_IP>),
		'prefix' => q(<SAMBA_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<SAMBA_VIRTUAL_IP_DEV>)
	},
	'init' => {
		'smb' => {
			path  => '/etc/init.d/smb',
			stop  => '/etc/init.d/smb stop',
			start => '/etc/init.d/smb start',
			off   => 'chkconfig smb off',
			on    => 'chkconfig smb on',
		},
		'nmb' => {
			path  => '/etc/init.d/nmb',
			stop  => '/etc/init.d/nmb stop',
			start => '/etc/init.d/nmb start',
			off   => 'chkconfig nmb off',
			on    => 'chkconfig nmb on',
		}
	}
};

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );
$common{'RHEL'}{5} = Storable::dclone( $common{'RHEL'} );
delete $common{'RHEL'}{5}{init}{nmb};

$common{'SLES'}{init} = {
	'smb' => {
		path  => '/etc/init.d/smb',
		stop  => '/etc/init.d/smb stop',
		start => '/etc/init.d/smb start',
		off   => 'yast2 --ncurses samba-server service disable',
		on    => 'yast2 --ncurses samba-server service enable',
	},
	'nmb' => {
		path  => '/etc/init.d/nmb',
		stop  => '/etc/init.d/nmb stop',
		start => '/etc/init.d/nmb start',
		off   => 'yast2 --ncurses samba-server service disable',
		on    => 'yast2 --ncurses samba-server service enable',
	}
};

$common{'SLES'}{task}{'setrole'}        = [ 'yast2 --ncurses samba-server role <SAMBA_SERVER_ROLE>' ];
$common{'SLES'}{task}{'setworkgroup'}   = [ 'yast2 --ncurses samba-server configure workgroup=<SAMBA_SERVER_WORKGROUP>' ];
$common{'SLES'}{task}{'open-firewall'}  = [ 'yast2 --ncurses firewall services add service=service:samba-server zone=EXT' ];
$common{'SLES'}{task}{'close-firewall'} = [ 'yast2 --ncurses firewall services remove service=service:samba-server zone=EXT' ];

$samba{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$samba{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$samba{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$samba{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$samba{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$samba{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$samba{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$samba{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$samba{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$samba{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$samba{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$samba{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$samba{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$samba{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$samba{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$samba{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$samba{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

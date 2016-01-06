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

package OVF::Service::App::NFS::Vars;

use strict;
use warnings;
use Storable;

our %nfs;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'nfs-utils' ],
	'init'     => {
		'rpcbind' => {
			path  => '/etc/init.d/rpcbind',
			stop  => '/etc/init.d/rpcbind stop',
			start => '/etc/init.d/rpcbind start',
			off   => 'chkconfig rpcbind off',
			on    => 'chkconfig rpcbind on'
		},
		'rpcidmapd' => {
			path  => '/etc/init.d/rpcidmapd',
			stop  => '/etc/init.d/rpcidmapd stop',
			start => '/etc/init.d/rpcidmapd start',
			off   => 'chkconfig rpcidmapd off',
			on    => 'chkconfig rpcidmapd on'
		},
		'nfs' => {
			path  => '/etc/init.d/nfs',
			stop  => '/etc/init.d/nfs stop',
			start => '/etc/init.d/nfs start',
			off   => 'chkconfig nfs off',
			on    => 'chkconfig nfs on'
		}
	},
	'virtualip' => {
		'ip'     => q(<NFS_VIRTUAL_IP>),
		'prefix' => q(<NFS_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<NFS_VIRTUAL_IP_DEV>)
	},
	'task' => {
		'open-firewall'  => [ q{iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT}, q{iptables -A INPUT -m state --state NEW -m udp -p udp --dport 111 -j ACCEPT}, q{iptables -A INPUT -m state --state NEW -m udp -p udp --dport 10000:10006 -j ACCEPT}, q{ip6tables -A INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT}, q{ip6tables -A INPUT -m state --state NEW -m udp -p udp --dport 111 -j ACCEPT}, q{ip6tables -A INPUT -m state --state NEW -m udp -p udp --dport 10000:10006 -j ACCEPT}, q{/etc/init.d/iptables save;/etc/init.d/ip6tables save} ],
		'close-firewall' => [ q{iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT}, q{iptables -D INPUT -m state --state NEW -m udp -p udp --dport 111 -j ACCEPT}, q{iptables -D INPUT -m state --state NEW -m udp -p udp --dport 10000:10006 -j ACCEPT}, q{ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport 2049 -j ACCEPT}, q{ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport 111 -j ACCEPT}, q{ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport 10000:10006 -j ACCEPT}, q{/etc/init.d/iptables save;/etc/init.d/ip6tables save} ]
	},
	'mount' => {
		'source' => '<NFS_DEVICE>',
		'target' => '<NFS_DATA_DIRECTORY>',
		'fstype' => '<NFS_FS_TYPE>'
	}
};

$common{'RHEL'}{4} = Storable::dclone( $common{'RHEL'} );
$common{'RHEL'}{3} = Storable::dclone( $common{'RHEL'} );
$common{'SLES'}    = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{packages} = [ 'nfs-kernel-server' ];

$common{'SLES'}{init} = {
	'rpcbind' => {
		path  => '/etc/init.d/rpcbind',
		stop  => '/etc/init.d/rpcbind stop',
		start => '/etc/init.d/rpcbind start',
		off   => 'chkconfig rpcbind off',
		on    => 'chkconfig rpcbind on'
	},
	'nfsserver' => {
		path  => '/etc/init.d/nfsserver',
		stop  => '/etc/init.d/nfsserver stop',
		start => '/etc/init.d/nfsserver start',
		off   => 'chkconfig nfsserver off',
		on    => 'chkconfig nfsserver on'
	}
};

$common{'SLES'}{task} = {
	'open-firewall'  => [ 'yast2 --ncurses firewall services add service=service:nfs-kernel-server zone=EXT' ],
	'close-firewall' => [ 'yast2 --ncurses firewall services remove service=service:nfs-kernel-server zone=EXT' ]
};

$common{'RHEL'}{4}{directories} = {
	'fsid0' => {
		path  => '<NFS_DATA_DIRECTORY>/nfs4',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	},
	'bind1' => {
		path  => '<NFS_DATA_DIRECTORY>/source-bind1',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	},
	'bind2' => {
		path  => '<NFS_DATA_DIRECTORY>/source-bind2',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	}
};

$common{'RHEL'}{4}{bind1} = {
	'source' => '<NFS_DATA_DIRECTORY>/source-bind1',
	'target' => '<NFS_DATA_DIRECTORY>/nfs4/target-bind1',
	'fstype' => 'bind'
};

$common{'RHEL'}{4}{bind2} = {
	'source' => '<NFS_DATA_DIRECTORY>/source-bind2',
	'target' => '<NFS_DATA_DIRECTORY>/nfs4/target-bind2',
	'fstype' => 'bind'
};
$common{'RHEL'}{4}{files} = {
	'exports' => {
		path  => '/etc/exports',
		save  => 1,
		chmod => 644,
		apply => {
			1 => {
				replace => 1,
				content => q{<NFS_DATA_DIRECTORY>/nfs4 *(rw,sync,insecure,root_squash,no_subtree_check,fsid=0,crossmnt)
<NFS_DATA_DIRECTORY>/nfs4/target-bind1 *(rw,sync,insecure,root_squash,no_subtree_check)
<NFS_DATA_DIRECTORY>/nfs4/target-bind2 *(rw,sync,insecure,root_squash,no_subtree_check)}
			}
		}
	}
};

$common{'RHEL'}{4}{task} = { 'cleardir' => [ q{cd <NFS_DATA_DIRECTORY>; rm -rf * .*} ] };

$common{'RHEL'}{3}{directories} = {
	'root' => {
		path  => '<NFS_DATA_DIRECTORY>/nfs3',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	},
	'dir1' => {
		path  => '<NFS_DATA_DIRECTORY>/nfs3/dir1',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	},
	'dir2' => {
		path  => '<NFS_DATA_DIRECTORY>/nfs3/dir2',
		save  => 0,
		chmod => 1777,
		chown => 'nobody',
		chgrp => 'nobody'
	}
};

$common{'RHEL'}{3}{files} = {
	'exports' => {
		path  => '/etc/exports',
		save  => 1,
		chmod => 644,
		apply => {
			1 => {
				replace => 1,
				content => q{<NFS_DATA_DIRECTORY>/nfs3/dir1 1*(rw,sync)
<NFS_DATA_DIRECTORY>/nfs3/dir2 *(rw,sync)}
			}
		}
	}
};

$common{'RHEL'}{3}{task} = { 'cleardir' => [ q{cd <NFS_DATA_DIRECTORY>; rm -rf * .*} ] };

$common{'RHEL'}{5}{init} = {
	'rpcbind' => {
		path  => '/etc/init.d/rpcgssd',
		stop  => '/etc/init.d/rpcgssd stop',
		start => '/etc/init.d/rpcgssd start',
		off   => 'chkconfig rpcgssd off',
		on    => 'chkconfig rpcgssd on'
	},
	'rpcidmapd' => {
		path  => '/etc/init.d/rpcidmapd',
		stop  => '/etc/init.d/rpcidmapd stop',
		start => '/etc/init.d/rpcidmapd start',
		off   => 'chkconfig rpcidmapd off',
		on    => 'chkconfig rpcidmapd on'
	},
	'nfs' => {
		path  => '/etc/init.d/nfs',
		stop  => '/etc/init.d/nfs stop',
		start => '/etc/init.d/nfs start',
		off   => 'chkconfig nfs off',
		on    => 'chkconfig nfs on'
	}
};

$common{'SLES'}{4} = Storable::dclone( $common{'RHEL'}{4} );
$common{'SLES'}{3} = Storable::dclone( $common{'RHEL'}{3} );

$nfs{'RHEL'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$nfs{'RHEL'}{5}{9}{'x86_64'}{init} = $common{'RHEL'}{5}{init};

$nfs{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$nfs{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$nfs{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$nfs{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$nfs{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$nfs{'CentOS'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$nfs{'CentOS'}{5}{9}{'x86_64'}{init} = $common{'RHEL'}{5}{init};

$nfs{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$nfs{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$nfs{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$nfs{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$nfs{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$nfs{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$nfs{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$nfs{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$nfs{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$nfs{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

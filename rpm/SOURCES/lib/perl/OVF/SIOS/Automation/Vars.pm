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

package OVF::SIOS::Automation::Vars;

use strict;
use warnings;

our %automate;
my %common;

$common{'RHEL'}{sps} = {
	'defaults' => { 'fstabOptions' => qq(defaults,_netdev\t\t0 0) },
	'packages' => [ 'telnet', 'telnet-server' ],
	'users'    => {
		'qe_auto' => {
			uid          => 0,
			gid          => 0,
			homeDir      => '/home/qe_auto',
			passwd       => 'myqeautopass',
			shell        => '/bin/bash',
			comment      => 'SIOS QE_AUTO User',
			'extra-args' => '--non-unique'
		}
	},
	'files' => {
		'remote' => {
			path  => '/etc/pam.d/remote',
			save  => 1,
			apply => {
				1 => {
					substitute => {
						1 => {
							regex   => q{^#auth\s+required\s+pam_securetty.so},
							content => q{auth       required     pam_securetty.so}
						}
					}
				}
			  }
		},
		'securetty' => {
			path  => '/etc/securetty',
			save  => 1,
			apply => {
				1 => {
					tail    => 1,
					content => q{pts/0
pts/1
pts/2
		}
				}
			}
		},
		'fstab' => {
			'path' => '/etc/fstab',
			'save' => 1,
			apply  => {
				1 => {
					tail      => 1,
					'content' => qq{<FS_DEVICE>\t<FS_PATH>\t<FS_FS_TYPE>\t<FS_FSTAB_OPTIONS>}
				}
			}
		}
	},
	'mount' => {
		'source' => 'castro.sc.steeleye.com:/home/qe_auto',
		'target' => '/home/qe_auto',
		'fstype' => 'nfs'
	},
	'init' => {
		'xinetd' => {
			path  => '/etc/init.d/xinetd',
			stop  => '/etc/init.d/xinetd stop',
			start => '/etc/init.d/xinetd start',
			off   => 'chkconfig xinetd off',
			on    => 'chkconfig xinetd on',
		},
		'telnet' => {
			path  => '/etc/init.d/xinetd',
			stop  => '/etc/init.d/xinetd stop',
			start => '/etc/init.d/xinetd start',
			off   => 'chkconfig telnet off',
			on    => 'chkconfig telnet on',
		}
	}
};

$automate{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$automate{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$automate{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$automate{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$automate{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$automate{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$automate{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$automate{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$automate{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$automate{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$automate{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$automate{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$automate{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$automate{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$automate{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$automate{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$automate{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

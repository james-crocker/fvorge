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

package OVF::Service::Storage::ISCSI::Vars;

use strict;
use warnings;
use Storable;

our %iscsi;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'iscsi-initiator-utils' ],
	'files'    => {
		'initiatorname.iscsi' => {
			path  => '/etc/iscsi/initiatorname.iscsi',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{InitiatorName=<ISCSI_INITIATOR_NAME>}
				}
			}
		},
		'iscsid.conf' => {
			path  => '/etc/iscsi/iscsid.conf',
			save  => 'once',
			apply => {
				1 => {
					'substitute' => {
						1 => {
							regex   => q{^\s*node.startup\s*=\s*},
							content => q{node.startup = manual}
						}
					}
				}
			}
		}
	},
	'init' => {
		'iscsid' => {
			path  => '/etc/init.d/iscsid',
			stop  => '/etc/init.d/iscsid stop',
			start => '/etc/init.d/iscsid start',
			off   => 'chkconfig iscsid off',
			on    => 'chkconfig iscsid on',
		},
		'iscsi' => {
			path  => '/etc/init.d/iscsi',
			stop  => '/etc/init.d/iscsi stop',
			start => '/etc/init.d/iscsi start',
			off   => 'chkconfig iscsi off',
			on    => 'chkconfig iscsi on',
		}
	},
	'task' => {
		'logout'    => [ 'iscsiadm -m node --logoutall=all' ],
		'discover'  => [ 'iscsiadm -m discovery --type sendtargets --portal <ISCSI_PORTAL>' ],
		'login'     => [ 'iscsiadm -m node --targetname "<ISCSI_TARGET_IQN>" --portal <ISCSI_PORTAL> --login' ],
		'autonodes' => [ 'iscsiadm -m node --targetname "<ISCSI_TARGET_IQN>" --op=update --name=node.startup --value=automatic' ]
	}
};

#------------SLES
# ?? need to mess with boot.open-iscsi ??
$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{'packages'} = [ 'open-iscsi' ];
$common{'SLES'}{'init'}     = {
	'open-iscsi' => {
		path  => '/etc/init.d/open-iscsi',
		stop  => '/etc/init.d/open-iscsi stop',
		start => '/etc/init.d/open-iscsi start',
		off   => 'chkconfig open-iscsi off',
		on    => 'chkconfig open-iscsi on',
	}
};

$iscsi{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$iscsi{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$iscsi{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$iscsi{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$iscsi{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$iscsi{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$iscsi{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$iscsi{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$iscsi{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$iscsi{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$iscsi{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$iscsi{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$iscsi{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$iscsi{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$iscsi{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$iscsi{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$iscsi{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

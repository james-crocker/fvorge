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

package OVF::Service::Storage::MD::Vars;

use strict;
use warnings;
use Storable;

our %md;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'md-initiator-utils' ],
	'files'    => {
		'initiatorname.md' => {
			path  => '/etc/md/initiatorname.md',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{InitiatorName=<MD_INITIATOR_NAME>}
				}
			}
		},
		'mdd.conf' => {
			path  => '/etc/md/mdd.conf',
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
		'mdd' => {
			path  => '/etc/init.d/mdd',
			stop  => '/etc/init.d/mdd stop',
			start => '/etc/init.d/mdd start',
			off   => 'chkconfig mdd off',
			on    => 'chkconfig mdd on',
		},
		'md' => {
			path  => '/etc/init.d/md',
			stop  => '/etc/init.d/md stop',
			start => '/etc/init.d/md start',
			off   => 'chkconfig md off',
			on    => 'chkconfig md on',
		}
	},
	'task' => {
		'logout'    => [ 'mdadm -m node --logoutall=all' ],
		'discover'  => [ 'mdadm -m discovery --type sendtargets --portal <MD_PORTAL>' ],
		'login'     => [ 'mdadm -m node --targetname "<MD_TARGET_IQN>" --portal <MD_PORTAL> --login' ],
		'autonodes' => [ 'mdadm -m node --targetname "<MD_TARGET_IQN>" --op=update --name=node.startup --value=automatic' ]
	}
};

#------------SLES
# ?? need to mess with boot.open-md ??
$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{'packages'} = [ 'open-md' ];
$common{'SLES'}{'init'}     = {
	'open-md' => {
		path  => '/etc/init.d/open-md',
		stop  => '/etc/init.d/open-md stop',
		start => '/etc/init.d/open-md start',
		off   => 'chkconfig open-md off',
		on    => 'chkconfig open-md on',
	}
};

$md{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$md{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$md{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$md{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$md{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$md{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$md{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$md{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$md{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$md{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$md{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$md{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$md{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$md{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$md{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$md{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$md{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

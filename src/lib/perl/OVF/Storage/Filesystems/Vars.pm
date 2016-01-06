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

package OVF::Storage::Filesystems::Vars;

use strict;
use warnings;

our %fs;
my %common;

$common{'RHEL'} = {
	'defaults' => {
		'target'         => '/srv/sp-fs',
		'fstype'         => 'ext3',
		'addFstab'       => 0,
		'fstabOptions'   => 'defaults',
		'mount'			 => 1,
		'randomPercent'  => 0,
		'randomFileSize' => 0
	},
	'files' => {
		'fstab' => {
			'path' => '/etc/fstab',
			'save' => 'once',
			apply  => {
				1 => {
					tail      => 1,
					'content' => qq{<FS_DEVICE>\t<FS_PATH>\t<FS_FS_TYPE>\t<FS_FSTAB_OPTIONS>}
				}
			  }
		}
	},
	'mount' => {
		'source' => '<FS_DEVICE>',
		'target' => '<FS_PATH>',
		'fstype' => '<FS_FS_TYPE>',
	}
};

$fs{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$fs{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$fs{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$fs{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$fs{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$fs{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$fs{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$fs{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$fs{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$fs{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$fs{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$fs{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$fs{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$fs{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$fs{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$fs{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$fs{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

$fs{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'RHEL'};
$fs{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'RHEL'};

1;

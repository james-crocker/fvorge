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

package OVF::Storage::LVM::Vars;

use strict;
use warnings;

use Storable;

our %lvm;
my %common;

# Part of all distro's BASE images. Shouldn't have to enable/disable.
# If package management needed then touch Packages.pm and include LVMVars and declarations
# for installing/removing the lvm pacakages.
#$common{'RHEL'}{packages} = [ 'lvm2' ];

$common{'RHEL'} = {
	'defaults' => {
		'target'         => '/srv/fvorge-lvm',
		'vgname'         => 'fvorge-vg',
		'lvname'         => 'fvorge-lv',
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
					'content' => qq{<LVM_LV_PATH>\t<LVM_PATH>\t<LVM_FS_TYPE>\t<LVM_FSTAB_OPTIONS>}
				}
			  }
		}
	},
	'mount' => {
		'source' => '<LVM_LV_PATH>',
		'target' => '<LVM_PATH>',
		'fstype' => '<LVM_FS_TYPE>',
	},
	'task' => {
		'pvcreate' => [ q{pvcreate -y <LVM_PV_DEVICE>} ],
		'pvremove' => [ q{pvremove -y -ff <LVM_PV_DEVICE>} ],
		'vgcreate' => [ q{vgcreate -f <LVM_VG_NAME> <LVM_PV_DEVICES>} ],
		'vgremove' => [ q{vgremove -f <LVM_VG_NAME>} ],
		'vgavaily' => [ q{vgchange --available y <LVM_VG_NAME>} ],
		'vgavailn' => [ q{vgchange --available n <LVM_VG_NAME>} ],
		'freepe'   => [ q(vgdisplay <LVM_VG_NAME> | grep "Free" | awk '{print $5}') ],
		'lvavaily' => [ q{lvchange --available y <LVM_LV_PATH>} ],
		'lvavailn' => [ q{lvchange --available n <LVM_LV_PATH>} ],
		'lvcreate' => [ q(lvcreate -l <LVM_PHYSICAL_EXTENT> -n<LVM_LV_NAME> <LVM_VG_NAME>) ],
		'lvremove' => [ q(lvremove -f <LVM_LV_PATH>) ]
	}
};

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{'init'} = {
		'boot.lvm' => {
			path  => '/etc/init.d/boot.lvm',
			stop  => '/etc/init.d/boot.lvm stop',
			start => '/etc/init.d/boot.lvm start',
			off   => 'yast2 --ncurses runlevel delete service="boot.lvm runlevels=B"',
			on    => 'yast2 --ncurses runlevel add service="boot.lvm" runlevels=B'
		}
	};

$lvm{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$lvm{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$lvm{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$lvm{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$lvm{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lvm{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lvm{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$lvm{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$lvm{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$lvm{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$lvm{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lvm{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lvm{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lvm{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lvm{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$lvm{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$lvm{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

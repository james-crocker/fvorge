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

package OVF::Service::Storage::Multipath::Vars;

use strict;
use warnings;
use Storable;

our %multipath;
my %common;

# RHEL 5.x Multipath is /dev/mapper/mpath#, and multipath getuid_callout is old format
# RHEL 6.x Multipath is /dev/mapper/mpathA

$common{'RHEL'} = {
	'packages' => [ 'sg3_utils', 'device-mapper-multipath' ],
	'files'    => {
		'multipath.conf' => {
			path  => '/etc/multipath.conf',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{blacklist {
    device {
        vendor "QEMU"
        product "*"
    }
}
defaults \{
        user_friendly_names yes
\}
devices \{
        device \{
                vendor                  "LIO-ORG"
                product                 "FILEIO"     # (may be other type)
                getuid_callout          <GETUID_CALLOUT>
        \}
\}
                     }
				}
			  }
		}
	},
	'init' => {
		'multipathd' => {
			path  => '/etc/init.d/multipathd',
			stop  => '/etc/init.d/multipathd stop',
			start => '/etc/init.d/multipathd start',
			off   => 'chkconfig multipathd off',
			on    => 'chkconfig multipathd on',
		}
	},
	'task' => {
		'modprobe' => [ 'modprobe dm_multipath' ],
		'rmmod'    => [ 'rmmod dm_multipath' ],
		'flush'    => [ 'multipath -F' ]
	}
};

#------------SLES

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{packages} = [ 'sg3_utils', 'multipath-tools' ];
$common{'SLES'}{10}{packages} = [ 'scsi', 'multipath-tools' ];

$multipath{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$multipath{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$multipath{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$multipath{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$multipath{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$multipath{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$multipath{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$multipath{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$multipath{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$multipath{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$multipath{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$multipath{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$multipath{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$multipath{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$multipath{'SLES'}{10}{4}{'x86_64'} = Storable::dclone( $common{'SLES'} );
$multipath{'SLES'}{10}{4}{'x86_64'}{packages} = $common{'SLES'}{10}{packages};

$multipath{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$multipath{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

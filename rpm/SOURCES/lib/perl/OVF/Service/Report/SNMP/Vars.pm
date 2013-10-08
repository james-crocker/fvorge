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

package OVF::Service::Report::SNMP::Vars;

use strict;
use warnings;
use Storable;

our %snmp;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'net-snmp-utils' ],
	'files'    => {
		'snmp.conf' => {
			path    => '/usr/share/snmp/snmp.conf',
			save    => 1,
			chmod   => 644,
			apply   => {
				1 => {
					replace => 1,
					content => q{<SNMP_COMMUNITY>}
				}
			  }
		}
	}
};

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{packages} = [ 'net-snmp' ];

$snmp{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$snmp{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$snmp{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$snmp{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$snmp{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$snmp{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$snmp{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$snmp{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$snmp{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$snmp{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$snmp{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$snmp{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$snmp{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$snmp{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$snmp{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$snmp{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$snmp{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

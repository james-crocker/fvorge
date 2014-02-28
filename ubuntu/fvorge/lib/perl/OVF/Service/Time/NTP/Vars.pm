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

package OVF::Service::Time::NTP::Vars;

use strict;
use warnings;
use Storable;

our %ntp;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'ntp', 'ntpdate' ],
	'files'    => {
		'ntpconf' => {
			path  => '/etc/ntp.conf',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{tinker panic 0
driftfile /var/lib/ntp/drift

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
                           
restrict 127.0.0.1            
restrict -6 ::1            
                 
server <NTP_SERVER>
server 0.centos.pool.ntp.org
server 1.centos.pool.ntp.org
server 2.centos.pool.ntp.org

includefile /etc/ntp/crypto/pw

keys /etc/ntp/keys
}
				}
			}
		}
	},
	'init' => {
		'ntpdate' => {
			path  => '/etc/init.d/ntpdate',
			stop  => '/etc/init.d/ntpdate stop',
			start => '/etc/init.d/ntpdate start',
			off   => 'chkconfig ntpdate off',
			on    => 'chkconfig ntpdate on',
		},
		'ntpd' => {
			path  => '/etc/init.d/ntpd',
			stop  => '/etc/init.d/ntpd stop',
			start => '/etc/init.d/ntpd start',
			off   => 'chkconfig ntpd off',
			on    => 'chkconfig ntpd on',
		}
	}
};

# Centos 5.9 only 'ntp' No 'ntpdate'
$common{'RHEL'}{5}{packages} = [ 'ntp' ];
$common{'RHEL'}{5}{init}     = {
	'ntpd' => {
		path  => '/etc/init.d/ntpd',
		stop  => '/etc/init.d/ntpd stop',
		start => '/etc/init.d/ntpd start',
		off   => 'chkconfig ntpd off',
		on    => 'chkconfig ntpd on',
	}
};

# SLES

$common{'SLES'} = {
	'packages' => [ 'xntp' ],
	'files'    => {
		'ntpconf' => {
			path  => '/etc/ntp.conf',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{tinker panic 0
driftfile /var/lib/ntp/drift

restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
                           
restrict 127.0.0.1            
restrict -6 ::1            
                 
server <NTP_SERVER>
server 0.centos.pool.ntp.org
server 1.centos.pool.ntp.org
server 2.centos.pool.ntp.org

includefile /etc/ntp/crypto/pw

#keys /etc/ntp.keys (broken init script)
}
				}
			  }
		}
	},
	'init' => {
		'ntpd' => {
			path  => '/etc/init.d/ntp',
			stop  => '/etc/init.d/ntp stop',
			start => '/etc/init.d/ntp start',
			off   => 'chkconfig ntp off',
			on    => 'chkconfig ntp on',
		}
	}
};

$ntp{'RHEL'}{5}{9}{'x86_64'}           = Storable::dclone( $common{'RHEL'} );
$ntp{'RHEL'}{5}{9}{'x86_64'}{init}     = $common{'RHEL'}{5}{init};
$ntp{'RHEL'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$ntp{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$ntp{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$ntp{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$ntp{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ntp{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ntp{'CentOS'}{5}{9}{'x86_64'}           = Storable::dclone( $common{'RHEL'} );
$ntp{'CentOS'}{5}{9}{'x86_64'}{init}     = $common{'RHEL'}{5}{init};
$ntp{'CentOS'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$ntp{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$ntp{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$ntp{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$ntp{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ntp{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ntp{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ntp{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ntp{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$ntp{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$ntp{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

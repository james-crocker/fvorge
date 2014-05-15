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

package OVF::Service::Security::PAM::LDAP::Vars;

use strict;
use warnings;
use Storable;

our %pam;
my %common;

$common{'RHEL'} = {
	'packages'       => [ 'nss-pam-ldapd',      'pam_ldap' ],
	'packages-32bit' => [ 'nss-pam-ldapd.i686', 'pam_ldap.i686' ],
	'task'           => {
		'enable'  => [ q{authconfig --enableldap --enableldapauth --ldapserver=<LDAP_SERVER> --ldapbasedn='<LDAP_BASEDN>' --update} ],
		'disable' => [ q{authconfig --disableldap --disableldapauth --update} ]
	}
};

$common{'RHEL'}{5}{packages} = [ 'nss_ldap' ];
$common{'RHEL'}{5}{'packages-32bit'} = [ 'nss_ldap.i386' ];

$common{'SLES'} = {
	'packages'       => [ 'openldap2-client', 'nss_ldap', 'pam_ldap' ],
	'packages-32bit' => [ 'nss_ldap-32bit',   'pam_ldap-32bit' ],
	'task'           => {
		'enable'  => [ q{yast2 --ncurses ldap pam enable server="<LDAP_SERVER>" base="<LDAP_BASEDN>"} ],
		'disable' => [ q{yast2 --ncurses ldap pam disable} ]
	}
};

$common{'Ubuntu'} = {
	'packages' => [ 'libpam-ldap' ],
	'files'    => {
		'ldap-auth-config' => {
			path  => '/tmp/ldap-auth-config.dat',
			save  => 0,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => qq{ldap-auth-config\tldap-auth-config/bindpw\tpassword
ldap-auth-config\tldap-auth-config/rootbindpw\tpassword\t<LDAP_ROOTBINDPW>  
ldap-auth-config\tldap-auth-config/ldapns/ldap_version\tselect  3
ldap-auth-config\tldap-auth-config/dbrootlogin\tboolean\tfalse
ldap-auth-config\tldap-auth-config/move-to-debconf\tboolean\ttrue
ldap-auth-config\tldap-auth-config/ldapns/ldap-server\tstring\t<LDAP_SERVER>
ldap-auth-config\tldap-auth-config/override\tboolean\ttrue
ldap-auth-config\tldap-auth-config/dblogin\tboolean\tfalse
ldap-auth-config\tldap-auth-config/ldapns/base-dn string\t<LDAP_BASEDN>
ldap-auth-config\tldap-auth-config/rootbinddn string\t<LDAP_ROOTBINDDN>
ldap-auth-config\tldap-auth-config/binddn string\t<LDAP_BINDDN>
ldap-auth-config\tldap-auth-config/pam_password\tselect\tmd5
}
				}
			}
		}
	},
	'task' => {}
};

$common{'Ubuntu'}{'task'} = {
	'enable' => [ q{auth-client-config -t nss -p lac_ldap}, q{debconf-set-selections } . $common{'Ubuntu'}{'files'}{'ldap-auth-config'}{'path'} ],
	'disable' => [ q{} ]
};

$pam{'RHEL'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$pam{'RHEL'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$pam{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$pam{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$pam{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$pam{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pam{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pam{'CentOS'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$pam{'CentOS'}{5}{9}{'x86_64'}{packages} = $common{'RHEL'}{5}{packages};

$pam{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$pam{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$pam{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$pam{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pam{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pam{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$pam{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$pam{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$pam{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$pam{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$pam{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$pam{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

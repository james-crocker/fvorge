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

package OVF::Service::Database::Oracle::Vars;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Vars::Common;

our %oracle;
my %common;

my $setoraPerSid;
my $oratab;

my $setoraPreamble = q{
#!/bin/bash

# REQUIRES $1 ARG OF ORACLE_SID. eg. sp-ora10

unset ORACLE_BASE
unset ORACLE_HOME
unset ORACLE_SID

ORACLE_SID=$1

};

my $setoraPostscript = q{export PATH
export ORACLE_BASE
export ORACLE_HOME
export ORACLE_SID

};

my $sysctlconf = q{# ORACLE - ORACLE SETUP DOCS chapter 2, section 2.9.1
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 4294967295
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
};

$common{'RHEL'} = {
	'groups' => { 
		'sp-oradba' => { 
			gid => 6003 
		} 
	},
	'users'  => {
		'sp-ora10' => {
			uid     => 6003,
			gid     => 6003,
			homeDir => '/home/sp-ora10',
			passwd  => 'myora10pass',
			oraSid  => 'QAORA10',
			oraBase => '/srv/sp-ora10',
			oraHome => 'product/10.2.0/dbhome_1',
			oraBin  => '/usr/local/sp-ora10',
			shell   => '/bin/bash',
			comment => 'SIOS ORA10 User'
		},
		'sp-ora11' => {
			uid     => 6004,
			gid     => 6003,
			homeDir => '/home/sp-ora11',
			passwd  => 'myora11pass',
			oraSid  => 'QAORA11',
			oraBase => '/srv/sp-ora11',
			oraHome => 'product/11.2.0/dbhome_1',
			oraBin  => '/usr/local/sp-ora11',
			shell   => '/bin/bash',
			comment => 'SIOS ORA11 User'
		}
	},
	'directories' => {
		'ora10' => {
			path  => '/srv/sp-ora10',
			save  => 0,
			chmod => 755,
			chown => 'sp-ora10',
			chgrp => 'sp-oradba'
		},
		'ora11' => {
			path  => '/srv/sp-ora11',
			save  => 0,
			chmod => 755,
			chown => 'sp-ora11',
			chgrp => 'sp-oradba'
		}
	},
};

foreach my $user ( keys %{ $common{'RHEL'}{users} } ) {
	$setoraPerSid .= q{if [ "$ORACLE_SID" == "} . $common{'RHEL'}{users}{$user}{oraSid} . q{" ]; then
  ORACLE_BASE=} . $common{'RHEL'}{users}{$user}{oraBase} . q{
  ORACLE_HOME=$ORACLE_BASE/} . $common{'RHEL'}{users}{$user}{oraHome} . q{
  PATH=$PATH:$HOME/bin:$ORACLE_HOME/bin:} . $common{'RHEL'}{users}{$user}{oraBin} . q{
fi

   };

	$oratab .= $common{'RHEL'}{users}{$user}{oraSid} . ':' . $common{'RHEL'}{users}{$user}{oraBase} . '/' . $common{'RHEL'}{users}{$user}{oraHome} . ':N' . "\n";

}

$common{'RHEL'}{'files'} = {
	'setora' => {
		path  => $OVF::Vars::Common::sysVars{'fvorge'}{bin} . '/set-ora',
		save  => 0,
		chmod => 755,
		apply => {
			1 => {
				replace => 1,
				content => $setoraPreamble . $setoraPerSid . $setoraPostscript
			}
		}
	},
	'oratab' => {
		path  => '/etc/oratab',
		save  => 0,
		chmod => 664,
		chown => 'sp-ora11',
		chgrp => 'sp-oradba',
		apply => {
			1 => {
				replace => 1,
				content => $oratab
			}
		}
	},
	'sysctlconf' => {
		path  => '/etc/sysctl.conf',
		save  => 1,
		chmod => 644,
		apply => {
			1 => {
				tail    => 1,
				content => $sysctlconf
			}
		  }
	},
};

$oracle{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$oracle{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$oracle{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$oracle{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$oracle{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$oracle{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$oracle{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$oracle{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$oracle{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$oracle{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$oracle{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$oracle{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$oracle{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$oracle{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$oracle{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$oracle{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$oracle{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

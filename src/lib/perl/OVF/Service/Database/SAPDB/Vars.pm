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

package OVF::Service::Database::SAPDB::Vars;

use strict;
use warnings;

our %sapdb;
my %common;

$common{'RHEL'} = {
	'groups' => { 'sp-sapdba' => { gid => 6001 } },
	'users'  => {
		'sp-sapdb' => {
			uid     => 6001,
			gid     => 6001,
			homeDir => '/home/sp-sapdb',
			passwd  => 'frs123',
			shell   => '/bin/bash',
			comment => 'SIOS OVF User SAPDB'
		}
	},
	'directories' => {
		'sapdbSharedDir' => {
			path  => '/srv/sp-sapdb',
			save  => 0,
			chmod => 755,
			chgrp => 'sp-sapdba',
			chown => 'sp-sapdb',
		},
		'sapdbLocalDir' => {
			path  => '/srv/sp-sapdb-local',
			save  => 0,
			chmod => 755,
			chgrp => 'sp-sapdba',
			chown => 'sp-sapdb',
		}
	},
	'virtualip' => {
		'ip'     => q(<SAPDB_VIRTUAL_IP>),
		'prefix' => q(<SAPDB_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<SAPDB_VIRTUAL_IP_DEV>)
	}
};

$common{'RHEL'}{files} = {
	'bash_profile' => {
		path  => $common{'RHEL'}{users}{'sp-sapdb'}{homeDir} . q{/.bash_profile},
		save  => 0,
		chmod => 444,
		chgrp => 'sp-sapdba',
		chown => 'sp-sapdb',
		apply => {
			1 => {
				replace => 1,
				content => q{if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin:} . $common{'RHEL'}{directories}{'sapdbSharedDir'}{path} . q{/DEMODB/bin

export PATH
}
			}
		}
	},
	'etcoptsdb' => {
		path  => '/etc/opt/sdb',
		save  => 0,
		chmod => 444,
		apply => {
			1 => {
				replace => 1,
				content => q{[Globals]
IndepPrograms=} . $common{'RHEL'}{directories}{sapdbSharedDir}{path} . q{/globalprograms
IndepData=} . $common{'RHEL'}{directories}{sapdbSharedDir}{path} . q{/globaldata
SdbOwner=sp-sapdb
SdbGroup=sp-sapdba
}
			}
		}
	},
	'xusers-key' => {
		path  => '/home/sp-sapdb/xusers-key',
		save  => 0,
		chmod => 660,
		chown => 'sp-sapdb',
		chgrp => 'sp-sapdba',
		apply => {
			1 => {
				replace => 1,
				content => q{DEFAULT
NULLDB
NULLDB
NULLDB
<SAPDB_VIRTUAL_IP>
INTERNAL
-1
-1
-1
my_locale
LK_USERKEY
sapdb
frs123
DEMODB
<SAPDB_VIRTUAL_IP>
INTERNAL
-1
-1
-1
en_US
}
			}
		  }
	}
};

$common{'SLES'} = %{ $common{'RHEL'} };

$sapdb{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$sapdb{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sapdb{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sapdb{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sapdb{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sapdb{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sapdb{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sapdb{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sapdb{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sapdb{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sapdb{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sapdb{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sapdb{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sapdb{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sapdb{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$sapdb{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$sapdb{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

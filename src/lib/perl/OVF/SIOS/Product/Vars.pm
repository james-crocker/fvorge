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

package OVF::SIOS::Product::Vars;

use strict;
use warnings;

our %product;
my %common;

$common{'RHEL'} = {
	task => {
		'setup' => [ $OVF::Vars::Common::sysCmds{'fvorge'}{'sp-setup'} . q{ -p <SIOS_PRODUCT> -no-c <SIOS_SETUP_ARGS>} ],
		'erase' => [ $OVF::Vars::Common::sysCmds{'fvorge'}{'sp-erase'} . q{ -p <SIOS_PRODUCT> -no-c <SIOS_ERASE_ARGS>} ]
	},
	files => {
		'bash_profile' => {
			path  => '/root/.bash_profile',
			save  => 1,
			chmod => 644,
			apply => {
				1 => {
					tail    => 1,
					content => q{export PATH=$PATH:/opt/LifeKeeper/bin}
				}
			}
		}
	}
};

$product{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$product{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$product{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$product{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$product{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$product{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$product{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$product{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$product{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$product{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$product{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$product{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$product{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$product{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$product{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$product{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$product{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

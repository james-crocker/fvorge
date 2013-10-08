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

package SIOS::BuildVars;

use lib '../../perl';

use strict;
use warnings;

our %build = (
	default => {
		product   => 'sps',
		version   => 'latest',
		build     => 'latest',
		gaVersion => 'latest',
		arks      => 'none',
		arkPrefix => 'steeleye-'
	},

	source => {
		host => '<source.fqdn.hostname>',
		base => '/home/lk_linux/CD_IMAGES'
	},

	ga => {
		host   => '<ga.fqdn.hostname>',
		base   => '/steel/localftp/electronic-software-distribution/linux',
		subDir => 'lk-on-x86',
		core   => { '8.2.0' => '', '8.1.3' => '', '8.1.2' => '', '8.1.1' => '', '8.1.0' => '', '8.0.0' => 'SteelEye_Protection_Suite', 'previous' => 'Core' },
		arks   => 'RecoveryKits'
	},

	licenses => {
		host => '<lic.fqdn.hostname>',
		base => '/export/PKGS/licenses',
		lk   => {
			corePath => 'linux',
			kitsPath => 'linux-kits'
		},

		'lk-cn' => {
			corePath => 'linux-china',
			kitsPath => 'linux-kits'
		},

		lkssp => {
			corePath => 'vAppKeeper',
			kitsPath => 'vAppKeeper'
		},

		ora => {
			corePath => 'linux',
			kitsPath => 'linux-kits'
		},

		sap => {
			corePath => 'linux',
			kitsPath => 'linux-kits'
		},

		smc => {
			corePath => undef,
			kitsPath => undef
		},

		sps => {
			corePath => 'linux',
			kitsPath => 'linux-kits'
		},

		vapp => {
			corePath => 'vAppKeeper',
			kitsPath => 'vAppKeeper'
		  }

	},

	licEval => {
		days    => [ 7, 14, 30, 60, 90 ],
		default => {
			days => 90,
			kits => 'all'
		}
	},

	scp => { userName => 'lk_linux' },

	setup => {
		path       => '/tmp',
		licPath    => 'eval-licenses',
		kitsPath   => 'kits',
		isoPath    => 'iso',
		mountPoint => '/mnt/seimg'
	}
);

our $buildLicEvalDaysHelp = join( '|', @{ $build{licEval}{days} } );
our $buildLicEvalDaysRegexPattern = '^(' . join( '|', @{ $build{licEval}{days} } ) . ')$';

our $buildHelp         = $build{default}{build} . '|#';
our $buildRegexPattern = '^(' . $build{default}{build} . '|[^\-\+]?[1-9]+)$';

1;


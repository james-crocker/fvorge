# Copyright (c) 2014 SIOS Technology Corp.  All rights reserved.

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

package OVF::Time::Vars;

use strict;
use warnings;

our %time;
my %common;

# Ubuntu Time
$common{'Ubuntu'} = {
	'defaults' => {
	},
	'files' => {
		'timezone' => {
			path  => '/etc/timezone',
			apply => {
				1 => {
					replace => 1,
					content => "<TIMEZONE>\n"
				},
			},
		},
	},
	'localtime' => {
		path  => '/etc/localtime',
		source => "/usr/share/zoneinfo/<TIMEZONE>"
	},
};

$time{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$time{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

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

package LIO::Vars;

use strict;
use warnings;

our %lio;
my %common;

my $cdImagesPath = 'Linux';

our $actionRegex   = 'create|destroy|saveconfig';
our $createRegex   = 'fileio|target|acls|luns|portals';
our $destroyRegex  = 'fileio|target';
our $fabricRegex   = 'iscsi';
our $volUnitsRegex = 'B|k|K|kB||KB|m|M|mB||MB|g|G|gB|GB|t|T|tB|TB';

$common{'RHEL'} = {
	'defaults' => {
		'targetserver'     => 'iscsi.sc.steeleye.com',
		'iqntarget-prefix' => 'iqn.2013.com.steeleye.qa.target:',
		'iqninit-prefix'   => 'iqn.2013.com.steeleye.qa.init:',
		'portal-ports'     => [ 3260, 3260 ],
		'portals'          => [ '172.17.105.22', '172.17.105.23' ],
		'fabric'           => 'iscsi',
		'tpgt'             => 1,
		'vol-prefix'       => 'D',
		'sys-fileio-path' => '/srv/iscsi-fileio/qa',
		'fileio-path'      => '/backstores/fileio',
		'disable-chap' => 1
	},
	'targetcli' => '/usr/bin/targetcli'
};

$lio{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$lio{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$lio{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$lio{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$lio{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lio{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lio{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$lio{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$lio{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$lio{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$lio{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lio{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lio{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$lio{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$lio{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$lio{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$lio{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

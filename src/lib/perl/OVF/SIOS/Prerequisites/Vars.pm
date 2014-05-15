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

package OVF::SIOS::Prerequisites::Vars;

use strict;
use warnings;

our %prerequisites;
my %common;

$common{'RHEL'}{sps}{packages} = [ 'patch', 'redhat-lsb' ];
$common{'RHEL'}{sps}{'packages-32bit'} = [ 'libXtst.i686', 'libstdc++.i686', 'bzip2-libs.i686', 'pam.i686', 'zlib.i686' ];

$common{'RHEL'}{5}{sps}{packages} = [ ];
$common{'RHEL'}{5}{sps}{'packages-32bit'} = [ 'libXtst.i386', 'libXi.i386', 'bzip2-libs.i386' ];

$common{'SLES'}{sps}{packages} = [ 'lsb' ];
$common{'SLES'}{sps}{'packages-32bit'} = [ 'libstdc++33-32bit', 'bzip2-32bit', 'pam-32bit', 'pam-modules-32bit', 'zlib-32bit' ];

$prerequisites{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$prerequisites{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$prerequisites{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$prerequisites{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$prerequisites{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$prerequisites{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$prerequisites{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$prerequisites{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$prerequisites{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$prerequisites{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$prerequisites{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$prerequisites{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$prerequisites{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$prerequisites{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$prerequisites{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$prerequisites{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$prerequisites{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

1;

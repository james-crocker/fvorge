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

package SIOS::SysInfo;

use strict;
use warnings;

use lib '../../perl';

use Linux::Distribution qw( distribution_name distribution_version);

our $arch    = '';
our $distro  = '';
our $version = '';

my $linux = Linux::Distribution->new;
if ( $distro = $linux->distribution_name() ) {
	$version = $linux->distribution_version();

	#$arch = $linux->distribution_arch();
	$arch = `uname -m`;
}

#print "Distro: $distro\n";
#print "Version: $version\n";
#print "Arch: $arch\n";

1;

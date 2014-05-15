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

package OVF::VApp;

use lib '../../perl';

use strict;
use warnings;

use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

sub restart ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action    = $thisSubName;
	my $arch      = $options{ovf}{current}{'host.architecture'};
	my $distro    = $options{ovf}{current}{'host.distribution'};
	my $major     = $options{ovf}{current}{'host.major'};
	my $minor     = $options{ovf}{current}{'host.minor'};

	my $rebootCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{rebootCmd};
	my $syncCmd   = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{syncCmd};

	Sys::Syslog::syslog( 'info', qq{$action ...} );
	
	system( $syncCmd );
	system( $rebootCmd );

	exit 0;

}

1;

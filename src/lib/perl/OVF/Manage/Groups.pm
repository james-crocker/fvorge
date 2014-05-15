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

package OVF::Manage::Groups;

use strict;
use warnings;

use lib '../../../perl';
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub create ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $addCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{addCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	# CREATE Groups FIRST as USER creation may rely on them existing first.

	my $myAddCmd = $addCmd;
	foreach my $group ( keys %ovfObject ) {
		$myAddCmd =~ s/<GID>/$ovfObject{$group}{gid}/;
		Sys::Syslog::syslog( 'info', qq{$action $myAddCmd $group ...} );
		system( qq{$myAddCmd $group $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action WARNING: Couldn't ($myAddCmd $group) ($?:$!)} );
		$myAddCmd = $addCmd;

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $destroyCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{destroyCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $group ( keys %ovfObject ) {
		Sys::Syslog::syslog( 'info', qq{$action $destroyCmd $group ...} );
		system( qq{$destroyCmd $group $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action WARNING: Couldn't ($destroyCmd $group) ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;


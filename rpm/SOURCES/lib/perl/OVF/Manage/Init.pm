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

package OVF::Manage::Init;

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

sub enable ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $init ( keys %ovfObject ) {
		my $onCmd    = $ovfObject{$init}{on};
		my $startCmd = $ovfObject{$init}{start};

		Sys::Syslog::syslog( 'info', qq{$action ENABLE: $init ...} );
		system( qq{$onCmd $quietCmd} ) == 0    or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $onCmd ($?:$!)} );
		system( qq{$startCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $startCmd ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub disable ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $init ( keys %ovfObject ) {
		my $offCmd  = $ovfObject{$init}{off};
		my $stopCmd = $ovfObject{$init}{stop};

		Sys::Syslog::syslog( 'info', qq{$action DISABLE: $init ...} );
		system( qq{$stopCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $stopCmd ($?:$!)} );
		system( qq{$offCmd $quietCmd} ) == 0  or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $offCmd ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

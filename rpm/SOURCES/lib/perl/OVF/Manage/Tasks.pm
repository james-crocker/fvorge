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

package OVF::Manage::Tasks;

use strict;
use warnings;

use POSIX;

use lib '../../../perl';
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub run ( \%\@ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( @ovfObject ) = @{ ( shift ) };

	my $action    = $thisSubName;
	my $retVal;
	my $groupRetVal = 1;

	foreach my $task ( @ovfObject ) {
		Sys::Syslog::syslog( 'info', qq{$action $task ... } );
		$retVal = system( qq{$task $quietCmd} );
		if ( $retVal != 0 ) {
			Sys::Syslog::syslog( 'warning', qq{$action WARNING: Couldn't $task ($?:$!)} );
			$groupRetVal = 0;	
		} else {
			Sys::Syslog::syslog( 'info', qq{$action SUCCEED: $task} );
		}
	}
	
	return $groupRetVal;

}

sub runExpect ( \$\$\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $expect ) = ${ ( shift ) };
	my ( $task ) = ${ ( shift ) };
	my ( %options )   = %{ ( shift ) };

	my $action    = $thisSubName;
	my $retVal;
	
	$expect = 0 if ( !defined $expect or !isdigit( $expect ) );

	Sys::Syslog::syslog( 'info', qq{$action $task (expect $expect) ... } );
	$retVal = system( qq{$task $quietCmd} );
	
	if ( $retVal != $expect ) {
		Sys::Syslog::syslog( 'warning', qq{$action WARNING: Couldn't $task ($?:$!)} );
	} else {
		Sys::Syslog::syslog( 'info', qq{$action SUCCEED: $task} );	
	}

	return $retVal;

}

1;

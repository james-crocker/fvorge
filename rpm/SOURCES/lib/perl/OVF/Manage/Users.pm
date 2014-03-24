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

package OVF::Manage::Users;

use strict;
use warnings;

use lib '../../../perl';
use OVF::Service::Security::SSH::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub create ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $action    = $thisSubName;

	my $addCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{addCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	# CREATE Groups FIRST as USER creation may rely on them existing first.

	my $myAddCmd = $addCmd;
	foreach my $user ( keys %ovfObject ) {

		$myAddCmd =~ s/<HOME_DIR>/"$ovfObject{$user}{homeDir}"/;
		$myAddCmd =~ s/<UID>/$ovfObject{$user}{uid}/;
		$myAddCmd =~ s/<GID>/$ovfObject{$user}{gid}/;
		$myAddCmd =~ s/<PASSWD>/"$ovfObject{$user}{passwd}"/;
		$myAddCmd =~ s/<COMMENT>/"$ovfObject{$user}{comment}"/;
		$myAddCmd =~ s/<SHELL>/"$ovfObject{$user}{shell}"/;
		
		if ( $ovfObject{$user}{'extra-args'} ) {
			$myAddCmd .= ' '.$ovfObject{$user}{'extra-args'};
		}

		Sys::Syslog::syslog( 'info', qq{$action $myAddCmd $user ...} );
		
		my $retVal = system( qq{$myAddCmd $user $quietCmd} );
		if ( $retVal == 0 ) {
			# Create SSH user config
			# DISABLED 20140324 - TODO refactor for changes in createUserConfig routine
			#OVF::Service::Security::SSH::Apply::createUserConfig( \%options, $ovfObject{$user}{homeDir}, $ovfObject{$user}{uid}, $ovfObject{$user}{gid} );	
		} else {
			Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($myAddCmd $user) ($?:$!)} );	
		}

		$myAddCmd = $addCmd;

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $action    = $thisSubName;

	my $destroyCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{destroyCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ... } );

	foreach my $user ( keys %ovfObject ) {
		Sys::Syslog::syslog( 'info', qq{$action $destroyCmd $user ...} );
		system( qq{$destroyCmd $user $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $user) ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;


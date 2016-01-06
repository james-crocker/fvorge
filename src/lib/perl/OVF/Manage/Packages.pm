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

package OVF::Manage::Packages;

use strict;
use warnings;

use Storable;

use lib '../../../perl';
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro    = $SIOS::CommonVars::sysDistro;
my $sysVersion   = $SIOS::CommonVars::sysVersion;
my $sysArch      = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub install ( \%\@ ) {

	my ( %options )   = %{ ( shift ) };
	my ( @ovfObject ) = @{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgInstallCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgInstallCmd};

	my $pkgList = join( ' ', @ovfObject );
	
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: No packages provided or defined} ) and return ) if ( !$pkgList );
	
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($pkgList) ...} );

	system( qq{$pkgInstallCmd $pkgList $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgInstallCmd $pkgList ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub remove ( \%\@ ) {

	my ( %options )   = %{ ( shift ) };
	my ( @ovfObject ) = @{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;;

	my $pkgRemoveCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgRemoveCmd};

	my $pkgList = join( ' ', @ovfObject );
	
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: No packages provided or defined} ) and return ) if ( !$pkgList );
	
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($pkgList) ...} );

	system( qq{$pkgRemoveCmd $pkgList $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgRemoveCmd $pkgList ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub groupInstall ( \%\@ ) {

	my ( %options )   = %{ ( shift ) };
	my ( @ovfObject ) = @{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgInstallCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgInstallCmd};

	my $pkgList = join( ' ', @ovfObject );
	
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: No packages provided or defined} ) and return ) if ( !$pkgList );
	
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($pkgList) ...} );

	system( qq{$pkgInstallCmd $pkgList $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgInstallCmd $pkgList ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub groupRemove ( \%\@ ) {

	my ( %options )   = %{ ( shift ) };
	my ( @ovfObject ) = @{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgRemoveCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgRemoveCmd};

	my $pkgList = join( ' ', @ovfObject );
	
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: No packages provided or defined} ) and return ) if ( !$pkgList );
	
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($pkgList) ...} );

	system( qq{$pkgRemoveCmd $pkgList $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{Couldn't $pkgRemoveCmd $pkgList ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub update ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgUpdateCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgUpdateCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	system( qq{$pkgUpdateCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgUpdateCmd ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub groupUpdate ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgUpdateCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgUpdateCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	system( qq{$pkgUpdateCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgUpdateCmd ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub clean ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgCleanCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgCleanCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	system( qq{$pkgCleanCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgCleanCmd ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub addSuseRepo ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $pkgAddSuseRepoCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pkgAddSuseRepoCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $fileName ( keys %ovfObject ) {
		system( qq{$pkgAddSuseRepoCmd $fileName $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $pkgAddSuseRepoCmd $fileName ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

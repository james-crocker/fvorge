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

package LIO::Module;

use strict;
use warnings;

use Tie::File;

use lib '../../perl';
use LIO::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub create ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};
	my $arch   = $options{'architecture'};

	my $distNum = $options{'distNum'};
	my $majNum  = $options{'majNum'};
	my $minNum  = $options{'minNum'};
	my $archNum = $options{'archNum'};
	my $grpNum  = $options{'grpNum'};
	my $instNum = $options{'instNum'};

	my $vmName       = $options{'vmname'};
	my $lioObject    = $options{'lioobject'};
	my $targetServer = $options{'targetserver'};
	my $iqnTarget    = $options{'iqntarget'};
	my $fabric       = $options{'fabric'} if ( defined $options{'fabric'} );
	my $disableChap  = $options{'disablechap'} if ( defined $options{'disablechap'} );
	my $iqnInitiator = $options{'iqninit'} if ( defined $options{'iqninit'} );
	my $tpgt         = $options{'tpgt'} if ( defined $options{'tpgt'} );
	my @portals      = $options{'portals'} if ( defined $options{'portals'} );
	my @portalPorts  = $options{'portalports'} if ( defined $options{'portalports'} );
	my @volSizes     = $options{'volsizes'} if ( defined $options{'volsizes'} );

	my $sysFileioPath = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'sys-fileio-path'};
	my $fileioPath    = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'fileio-path'};
	my $volPrefix     = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'vol-prefix'};

	if ( !defined $LIO::Vars::lio{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO LIO PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $targetcli = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'targetcli'};

	my $distName = $distNum . '-' . $majNum . '-' . $minNum . '-' . $archNum;

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my @createCmd;

	if ( $lioObject eq 'target' ) {
		push( @createCmd, '/$fabric create $iqnTarget' );
		if ( defined $disableChap and $disableChap ) {
			push( @createCmd, '/$fabric/$iqnTarget/tpgt$tpgt set attribute authentication=0' );
		}
	} elsif ( $lioObject eq 'fileio' ) {
		my $count = 1;
		foreach my $volSize ( @volSizes ) {
			push( @createCmd, qq{$fileioPath create $distNum-$majNum-$minNum-$archNum-$grpNum-$volPrefix$count-$volSize $sysFileioPath/$distName/$grpNum/$volPrefix$count-$volSize $volSize} );
			$count++;
		}
	} elsif ( $lioObject eq 'luns' ) {
		my $count = 1;
		foreach my $volSize ( @volSizes ) {
			push( @createCmd, qq{/$fabric/$iqnTarget/tpgt$tpgt/luns create $fileioPath/$distNum-$majNum-$minNum-$archNum-$grpNum-$volPrefix$count-$volSize} );
			$count++;
		}
	} elsif ( $lioObject eq 'acls' ) {
		push( @createCmd, qq{/$fabric/$iqnTarget/tpgt$tpgt/acls create $iqnInitiator} );
	} elsif ( $lioObject eq 'portals' ) {
		my $count = 0;
		foreach my $portal ( @portals ) {
			push( @createCmd, qq{/$fabric/$iqnTarget/tpgt$tpgt/portals create $portal $portalPorts[$count]} );
			$count++;
		}
	}

	foreach my $cmd ( @createCmd ) {
		print "CMD: echo '$cmd' | $targetcli\n";
	}

	#system( $createCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($createCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

}

sub destroy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	my $distNum = $options{'distNum'};
	my $majNum  = $options{'majNum'};
	my $minNum  = $options{'minNum'};
	my $archNum = $options{'archNum'};
	my $grpNum  = $options{'grpNum'};
	my $instNum = $options{'instNum'};

	my $vmName       = $options{'vmname'};
	my $lioObject    = $options{'lioobject'};
	my $targetServer = $options{'targetserver'};
	my $iqnTarget    = $options{'iqntarget'};
	my $fabric       = $options{'fabric'} if ( defined $options{'fabric'} );
	my $disableChap  = $options{'disablechap'} if ( defined $options{'disablechap'} );
	my $iqnInitiator = $options{'iqninit'} if ( defined $options{'iqninit'} );
	my $tpgt         = $options{'tpgt'} if ( defined $options{'tpgt'} );
	my @portals      = $options{'portals'} if ( defined $options{'portals'} );
	my @portalPorts  = $options{'portalports'} if ( defined $options{'portalports'} );
	my @volSizes     = $options{'volsizes'} if ( defined $options{'volsizes'} );

	my $sysFileioPath = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'sys-fileio-path'};
	my $fileioPath    = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'fileio-path'};
	my $volPrefix     = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'defaults'}{'vol-prefix'};

	if ( !defined $LIO::Vars::lio{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $targetcli = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'targetcli'};

	my $distName = $distNum . '-' . $majNum . '-' . $minNum . '-' . $archNum;

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my @destroyCmd;

	if ( $lioObject eq 'target' ) {
		push( @destroyCmd, '/$fabric delete $iqnTarget' );
	} elsif ( $lioObject eq 'fileio' ) {
		my $count = 1;
		foreach my $volSize ( @volSizes ) {
			push( @destroyCmd, qq{$fileioPath delete $distNum-$majNum-$minNum-$archNum-$grpNum-$volPrefix$count-$volSize} );
			$count++;
		}
	}

	foreach my $cmd ( @destroyCmd ) {
		print "CMD: echo '$cmd' | $targetcli\n";
	}

	#system( $destroyCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($destroyCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

}

sub saveconfig ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	if ( !defined $LIO::Vars::lio{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $targetcli = $LIO::Vars::lio{$distro}{$major}{$minor}{$arch}{'targetcli'};

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my $cmd = qq{echo };
	system( $cmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($cmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

}

1;

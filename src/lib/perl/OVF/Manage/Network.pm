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

package OVF::Manage::Network;

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

sub addIp ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $addCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{addCmd};
	my $ip     = getIp( \$ovfObject{ip} );
	my $prefix = $ovfObject{prefix};
	my $dev    = $ovfObject{dev};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($ip) ...} );

	system( qq{$addCmd $ip/$prefix dev $dev $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ADD ($addCmd $ip/$prefix dev $dev) ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub deleteIp ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $deleteCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{deleteCmd};
	my $ip        = getIp( \$ovfObject{ip} );
	my $prefix    = $ovfObject{prefix};
	my $dev       = $ovfObject{dev};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($ip) ...} );

	system( qq{$deleteCmd $ip/$prefix dev $dev $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't DELETE ($deleteCmd $ip/$prefix dev $dev) ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub getIp ( \$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $addr ) = ${ ( shift ) };
	my $hostCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{hostCmd};

	# 172.17.105.33 || 3001:334::1
	if ( $addr =~ /(\d+\.\d+\.\d+\.\d+|\:)/ ) {
		return $addr;
	} else {
		my $ip = qx{ $hostCmd $addr | awk '{print \$4;}' };
		chomp( $ip );
		return $ip;
	}

}

sub pingHost ( \$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $addr ) = ${ ( shift ) };
	
	return 0 if ( !$addr );
	
	my $pingHostCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pingHostCmd};
	my $ping6HostCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{ping6HostCmd};

	my $pingVal = system( qq{$pingHostCmd -c 2 $addr $quietCmd} );
	my $ping6Val = system( qq{$ping6HostCmd -c 2 $addr $quietCmd} );
	
	if ( $pingVal == 0 ) {
		return 1;
	} elsif ( $ping6Val == 0 ) {
		return 1;
	} else {
		return 0;
	}
	
}

1;

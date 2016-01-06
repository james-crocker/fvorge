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

package OVF::Service::Report::SNMP::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Service::Report::SNMP::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};
	
	my $property = 'service.report.snmp.enabled';

	if ( !defined $OVF::Service::Report::SNMP::Vars::snmp{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}
	
	if ( !defined $options{ovf}{current}{$property} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $property undefined} );
		return;
	}
	
	if ( !OVF::State::ovfIsChanged( $property, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $property same as Previous property} );
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ...} );
		if ( $options{ovf}{current}{$property} ) {
			enable( \%options );
		} else {
			disable( \%options );
		}
	} 	

}

sub enable ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %snmpVars = %{ $OVF::Service::Report::SNMP::Vars::snmp{$distro}{$major}{$minor}{$arch} };

	my $required        = [];
	my $requiredEnabled = [ 'service.report.snmp.community' ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.report.snmp.enabled', $requiredEnabled, %options ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$snmpVars{files}{'snmp.conf'}{apply}{1}{content} =~ s/<SNMP_COMMUNITY>/$options{ovf}{current}{'service.report.snmp.community'}/;

	OVF::Manage::Directories::create( %options, %{ $snmpVars{directories} } );
	OVF::Manage::Files::create( %options, %{ $snmpVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub disable ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %snmpVars = %{ $OVF::Service::Report::SNMP::Vars::snmp{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Files::destroy( %options, %{ $snmpVars{files} } );
	OVF::Manage::Directories::destroy( %options, %{ $snmpVars{directories} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

1;

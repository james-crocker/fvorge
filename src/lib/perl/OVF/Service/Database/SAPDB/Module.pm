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

package OVF::Service::Database::SAPDB::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Manage::Groups;
use OVF::Manage::Network;
use OVF::Service::Database::SAPDB::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};
	
	my $property = 'service.database.sapdb.enabled';

	if ( !defined $OVF::Service::Database::SAPDB::Vars::sapdb{$distro}{$major}{$minor}{$arch} ) {
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
			create( \%options );
		} else {
			destroy( \%options );
		}
	} 

}

sub create ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my @required = ( 'service.database.sapdb.virtualip', 'service.database.sapdb.virtualip-prefix', 'service.database.sapdb.virtualip-if' );
	my $halt = 0;
	foreach my $reqProperty ( @required ) {
		if ( !$options{ovf}{current}{$reqProperty} ) {
			Sys::Syslog::syslog( 'err', qq{Missing required parameter: $reqProperty} );
			$halt = 1;
		}
	}
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP::} ) and return ) if ( $halt );

	my %sapdbVars = %{ $OVF::Service::Database::SAPDB::Vars::sapdb{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	# CREATE Groups FIRST as USER creation may rely on them existing first.
	OVF::Manage::Groups::create( %options, %{ $sapdbVars{groups} } );
	OVF::Manage::Users::create( %options, %{ $sapdbVars{users} } );

	OVF::Manage::Directories::create( %options, %{ $sapdbVars{directories} } );

	$sapdbVars{files}{'xusers-key'}{apply}{1}{content} =~ s/<SAPDB_VIRTUAL_IP>/$options{ovf}{current}{'service.database.sapdb.virtualip'}/g;
	$sapdbVars{virtualip}{ip}                =~ s/<SAPDB_VIRTUAL_IP>/$options{ovf}{current}{'service.database.sapdb.virtualip'}/g;
	$sapdbVars{virtualip}{prefix}            =~ s/<SAPDB_VIRTUAL_IP_PREFIX>/$options{ovf}{current}{'service.database.sapdb.virtualip-prefix'}/g;
	$sapdbVars{virtualip}{dev}               =~ s/<SAPDB_VIRTUAL_IP_DEV>/$options{ovf}{current}{'service.database.sapdb.virtualip-if'}/g;

	OVF::Manage::Files::create( %options, %{ $sapdbVars{files} } );
	OVF::Manage::Network::addIp( %options, %{ $sapdbVars{virtualip} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %sapdbVars = %{ $OVF::Service::Database::SAPDB::Vars::sapdb{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$sapdbVars{virtualip}{ip}     =~ s/<SAPDB_VIRTUAL_IP>/$options{ovf}{current}{'service.database.sapdb.virtualip'}/g;
	$sapdbVars{virtualip}{prefix} =~ s/<SAPDB_VIRTUAL_IP_PREFIX>/$options{ovf}{current}{'service.database.sapdb.virtualip-prefix'}/g;
	$sapdbVars{virtualip}{dev}    =~ s/<SAPDB_VIRTUAL_IP_DEV>/$options{ovf}{current}{'service.database.sapdb.virtualip-if'}/g;

	OVF::Manage::Directories::destroy( %options, %{ $sapdbVars{directories} } );
	OVF::Manage::Files::destroy( %options, %{ $sapdbVars{files} } );
	OVF::Manage::Network::deleteIp( %options, %{ $sapdbVars{virtualip} } );

	OVF::Manage::Users::destroy( %options, %{ $sapdbVars{users} } );
	OVF::Manage::Groups::destroy( %options, %{ $sapdbVars{groups} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

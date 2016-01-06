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

package OVF::Service::Database::PostgreSQL::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Manage::Init;
use OVF::Manage::Network;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::Service::Security::Firewall::Module;
use OVF::Service::Database::PostgreSQL::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};
	
	my $property = 'service.database.postgresql.enabled';

	if ( !defined $OVF::Service::Database::PostgreSQL::Vars::pgsql{$distro}{$major}{$minor}{$arch} ) {
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

	my $required = [];
	my $requiredEnabled = [ 'service.database.postgresql.database-directory', 'service.database.postgresql.virtualip', 'service.database.postgresql.virtualip-prefix', 'service.database.postgresql.virtualip-if', 'service.database.postgresql.port', 'service.database.postgresql.storage-device', 'service.database.postgresql.port' ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.database.postgresql.enabled', $requiredEnabled, %options ) );

	my $directory       = $options{ovf}{current}{'service.database.postgresql.database-directory'};
	my $virtualIp       = $options{ovf}{current}{'service.database.postgresql.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.database.postgresql.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.database.postgresql.virtualip-if'};
	my $port            = $options{ovf}{current}{'service.database.postgresql.port'};
	my $source          = $options{ovf}{current}{'service.database.postgresql.storage-device'};

	my $fsType;
	if ( defined $options{ovf}{current}{'service.database.postgresql.fs-type'} ) {
		$fsType = $options{ovf}{current}{'service.database.postgresql.fs-type'};
	} elsif ( OVF::Manage::Storage::isBlockDevice( $source ) ) {
		$fsType = OVF::Manage::Storage::blkFsType( $source );
	}
	
	if ( !defined $fsType ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not determine the $source fs-type and service.database.postgresql.fs-type was not defined} );
		return;
	}

	my %shortVars = %{ $OVF::Service::Database::PostgreSQL::Vars::pgsql{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{directories}{'database'}{path}           =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{files}{'pg_hba.conf'}{path} =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{files}{'start-pgsql'}{apply}{1}{content} =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{files}{'start-pgsql'}{apply}{1}{content} =~ s/<PGSQL_VIRTUAL_IP>/$virtualIp/g;
	$shortVars{files}{'start-pgsql'}{apply}{1}{content} =~ s/<PGSQL_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/g;
	$shortVars{files}{'start-pgsql'}{apply}{1}{content} =~ s/<PGSQL_VIRTUAL_IP_DEV>/$virtualIpIf/g;
	$shortVars{files}{'start-pgsql'}{apply}{1}{content} =~ s/<PGSQL_PORT>/$port/;

	$shortVars{mount}{source} =~ s/<PGSQL_DEVICE>/$source/;
	$shortVars{mount}{target} =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{mount}{fstype} =~ s/<PGSQL_FS_TYPE>/$fsType/;

	$shortVars{task}{chgattr}[ 0 ]         =~ s/<PGSQL_DATA_DIRECTORY>/$directory/g;
	$shortVars{task}{cleardir}[ 0 ]        =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{task}{initdb}[ 0 ]          =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{virtualip}{ip}              =~ s/<PGSQL_VIRTUAL_IP>/$virtualIp/;
	$shortVars{virtualip}{prefix}          =~ s/<PGSQL_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{virtualip}{dev}             =~ s/<PGSQL_VIRTUAL_IP_DEV>/$virtualIpIf/;
	$shortVars{task}{start}[ 0 ]           =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{task}{start}[ 0 ]           =~ s/<PGSQL_VIRTUAL_IP>/$virtualIp/;
	$shortVars{task}{start}[ 0 ]           =~ s/<PGSQL_PORT>/$port/;
	$shortVars{task}{'open-firewall'}[ 0 ] =~ s/<PGSQL_PORT>/$port/g;
	
	# SPECIFIC FOR Steeleye SPS - Disable package postgres and rely on /opt/fvorge/bin/start-pgsql
	OVF::Manage::Init::disable( %options, %{ $shortVars{init} } );

	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'open-firewall'} } );
	}

	OVF::Manage::Storage::mount( %options, %{ $shortVars{mount} } );
	OVF::Manage::Directories::create( %options, %{ $shortVars{directories} } );

	# Initialize the DB if requested and set open security
	if ( $options{ovf}{current}{'service.database.postgresql.initdb'} ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{cleardir} } );
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{chgattr} } );
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{initdb} } );
		OVF::Manage::Files::create( %options, %{ $shortVars{files} } );
	}

	# Manual startup
	OVF::Manage::Network::addIp( %options, %{ $shortVars{virtualip} } );
	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{start} } );

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

	my $requiredEnabled = [];
	my $required = [ 'service.database.postgresql.database-directory', 'service.database.postgresql.virtualip', 'service.database.postgresql.virtualip-prefix', 'service.database.postgresql.virtualip-if', 'service.database.postgresql.port', 'service.database.postgresql.storage-device', 'service.database.postgresql.fs-type' ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.database.postgresql.enabled', $requiredEnabled, %options ) );

	my $directory       = $options{ovf}{current}{'service.database.postgresql.database-directory'};
	my $virtualIp       = $options{ovf}{current}{'service.database.postgresql.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.database.postgresql.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.database.postgresql.virtualip-if'};
	my $port            = $options{ovf}{current}{'service.database.postgresql.port'};
	

	my %shortVars = %{ $OVF::Service::Database::PostgreSQL::Vars::pgsql{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{directories}{'database'}{path} =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{virtualip}{ip}                 =~ s/<PGSQL_VIRTUAL_IP>/$virtualIp/;
	$shortVars{virtualip}{prefix}             =~ s/<PGSQL_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{virtualip}{dev}                =~ s/<PGSQL_VIRTUAL_IP_DEV>/$virtualIpIf/;
	$shortVars{mount}{target}                 =~ s/<PGSQL_DATA_DIRECTORY>/$directory/;
	$shortVars{task}{'close-firewall'}[ 0 ]   =~ s/<PGSQL_PORT>/$port/g;

	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'close-firewall'} } );
	}

	# Mount should have been adjusted if mkfs called.
	OVF::Manage::Files::destroy( %options, %{ $shortVars{files} } );
	OVF::Manage::Directories::destroy( %options, %{ $shortVars{directories} } );
	OVF::Manage::Init::disable( %options, %{ $shortVars{init} } );
	OVF::Manage::Storage::umount( %options, %{ $shortVars{mount} } );
	OVF::Manage::Network::deleteIp( %options, %{ $shortVars{virtualip} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

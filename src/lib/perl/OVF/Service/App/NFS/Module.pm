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

package OVF::Service::App::NFS::Module;

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
use OVF::Service::App::NFS::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property = 'service.app.nfs.enabled';

	if ( !defined $OVF::Service::App::NFS::Vars::nfs{$distro}{$major}{$minor}{$arch} ) {
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

	my $action     = $thisSubName;
	my $arch       = $options{ovf}{current}{'host.architecture'};
	my $distro     = $options{ovf}{current}{'host.distribution'};
	my $major      = $options{ovf}{current}{'host.major'};
	my $minor      = $options{ovf}{current}{'host.minor'};
	my $nfsversion = $options{ovf}{current}{'service.app.nfs.version'};

	my $required = [];
	my $requiredEnabled = [ 'service.app.nfs.version', 'service.app.nfs.storage-device', 'service.app.nfs.data-directory', 'service.app.nfs.virtualip', 'service.app.nfs.virtualip-prefix', 'service.app.nfs.virtualip-if', ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.app.nfs.enabled', $requiredEnabled, %options ) );

	my $source          = $options{ovf}{current}{'service.app.nfs.storage-device'};
	my $dataDirectory   = $options{ovf}{current}{'service.app.nfs.data-directory'};
	my $virtualIp       = $options{ovf}{current}{'service.app.nfs.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.app.nfs.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.app.nfs.virtualip-if'};

	my $fsType;
	if ( defined $options{ovf}{current}{'service.app.nfs.fs-type'} ) {
		$fsType = $options{ovf}{current}{'service.app.nfs.fs-type'};
	} elsif ( OVF::Manage::Storage::isBlockDevice( $source ) ) {
		$fsType = OVF::Manage::Storage::blkFsType( $source );
	}

	if ( !defined $fsType ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not determine the $source fs-type and service.app.nfs.fs-type was not defined} );
		return;
	}

	my %shortVars = %{ $OVF::Service::App::NFS::Vars::nfs{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{$nfsversion}{mount}{source} =~ s/<NFS_DEVICE>/$source/;
	$shortVars{$nfsversion}{mount}{target} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{$nfsversion}{mount}{fstype} =~ s/<NFS_FS_TYPE>/$fsType/;

	$shortVars{$nfsversion}{task}{cleardir}[ 0 ] =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{virtualip}{ip}                    =~ s/<NFS_VIRTUAL_IP>/$virtualIp/;
	$shortVars{virtualip}{prefix}                =~ s/<NFS_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{virtualip}{dev}                   =~ s/<NFS_VIRTUAL_IP_DEV>/$virtualIpIf/;

	$shortVars{$nfsversion}{files}{'exports'}{apply}{1}{content} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/g;

	$shortVars{3}{directories}{'root'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{3}{directories}{'dir1'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{3}{directories}{'dir2'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'fsid0'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'bind1'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'bind2'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind1}{source}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind1}{target}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind2}{source}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind2}{target}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;

	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'open-firewall'} } );
	}

	OVF::Manage::Storage::mount( %options, %{ $shortVars{$nfsversion}{mount} } );

	if ( $options{ovf}{current}{'service.app.nfs.clear-storage'} ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{$nfsversion}{task}{cleardir} } );
	}
	
	OVF::Manage::Directories::create( %options, %{ $shortVars{$nfsversion}{directories} } );

	if ( $nfsversion == 4 ) {
		OVF::Manage::Storage::mount( %options, %{ $shortVars{$nfsversion}{bind1} } );
		OVF::Manage::Storage::mount( %options, %{ $shortVars{$nfsversion}{bind2} } );
	}

	OVF::Manage::Files::create( %options, %{ $shortVars{$nfsversion}{files} } );
	OVF::Manage::Network::addIp( %options, %{ $shortVars{virtualip} } );
	OVF::Manage::Init::enable( %options, %{ $shortVars{init} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub disable ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action     = $thisSubName;
	my $arch       = $options{ovf}{current}{'host.architecture'};
	my $distro     = $options{ovf}{current}{'host.distribution'};
	my $major      = $options{ovf}{current}{'host.major'};
	my $minor      = $options{ovf}{current}{'host.minor'};
	my $nfsversion = $options{ovf}{current}{'service.app.nfs.version'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my $requiredEnabled = [];
	my $required = [ 'service.app.nfs.version', 'service.app.nfs.storage-device', 'service.app.nfs.data-directory', 'service.app.nfs.virtualip', 'service.app.nfs.virtualip-prefix', 'service.app.nfs.virtualip-if', ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.app.nfs.enabled', $requiredEnabled, %options ) );

	my $dataDirectory   = $options{ovf}{current}{'service.app.nfs.data-directory'};
	my $virtualIp       = $options{ovf}{current}{'service.app.nfs.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.app.nfs.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.app.nfs.virtualip-if'};

	my %shortVars = %{ $OVF::Service::App::NFS::Vars::nfs{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{$nfsversion}{mount}{target} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;

	$shortVars{virtualip}{ip}     =~ s/<NFS_VIRTUAL_IP>/$virtualIp/;
	$shortVars{virtualip}{prefix} =~ s/<NFS_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{virtualip}{dev}    =~ s/<NFS_VIRTUAL_IP_DEV>/$virtualIpIf/;

	$shortVars{4}{directories}{'dir1'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'dir2'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'root'}{path}  =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'bind1'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'bind1'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{directories}{'fsid0'}{path} =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind1}{target}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;
	$shortVars{4}{bind2}{target}              =~ s/<NFS_DATA_DIRECTORY>/$dataDirectory/;

	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'close-firewall'} } );
	}

	OVF::Manage::Init::disable( %options, %{ $shortVars{init} } );
	OVF::Manage::Network::deleteIp( %options, %{ $shortVars{virtualip} } );

	if ( $nfsversion == 4 ) {
		OVF::Manage::Storage::umount( %options, %{ $shortVars{$nfsversion}{bind1} } );
		OVF::Manage::Storage::umount( %options, %{ $shortVars{$nfsversion}{bind2} } );
	}

	OVF::Manage::Files::destroy( %options, %{ $shortVars{$nfsversion}{files} } );
	OVF::Manage::Directories::destroy( %options, %{ $shortVars{$nfsversion}{directories} } );
	OVF::Manage::Storage::umount( %options, %{ $shortVars{$nfsversion}{mount} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

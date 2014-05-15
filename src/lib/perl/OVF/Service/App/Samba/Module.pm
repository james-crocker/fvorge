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

package OVF::Service::App::Samba::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Manage::Groups;
use OVF::Manage::Init;
use OVF::Manage::Network;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::Manage::Users;
use OVF::Service::Security::Firewall::Module;
use OVF::Service::App::Samba::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property = 'service.app.samba.enabled';

	if ( !defined $OVF::Service::App::Samba::Vars::samba{$distro}{$major}{$minor}{$arch} ) {
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
	my $requiredEnabled = [ 'service.app.samba.workgroup', 'service.app.samba.netbiosname', 'service.app.samba.sharename', 'service.app.samba.lockpath', 'service.app.samba.logpath', 'service.app.samba.pidpath', 'service.app.samba.confpath', 'service.app.samba.role', 'service.app.samba.storage-device', 'service.app.samba.virtualip', 'service.app.samba.virtualip-prefix', 'service.app.samba.virtualip-if' ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.app.samba.enabled', $requiredEnabled, %options ) );

	my $sharePath       = $options{ovf}{current}{'service.app.samba.sharepath'};
	my $lockPath        = $options{ovf}{current}{'service.app.samba.lockpath'};
	my $logPath         = $options{ovf}{current}{'service.app.samba.logpath'};
	my $pidPath         = $options{ovf}{current}{'service.app.samba.pidpath'};
	my $confPath        = $options{ovf}{current}{'service.app.samba.confpath'};
	my $source          = $options{ovf}{current}{'service.app.samba.storage-device'};
	my $virtualIp       = $options{ovf}{current}{'service.app.samba.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.app.samba.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.app.samba.virtualip-if'};
	my $workgroup       = $options{ovf}{current}{'service.app.samba.workgroup'};
	my $netbios         = $options{ovf}{current}{'service.app.samba.netbiosname'};
	my $shareName       = $options{ovf}{current}{'service.app.samba.sharename'};
	my $role            = lc( $options{ovf}{current}{'service.app.samba.role'} );

	my $fsType;
	if ( defined $options{ovf}{current}{'service.app.samba.fs-type'} ) {
		$fsType = $options{ovf}{current}{'service.app.samba.fs-type'};
	} elsif ( OVF::Manage::Storage::isBlockDevice( $source ) ) {
		$fsType = OVF::Manage::Storage::blkFsType( $source );
	}

	if ( !defined $fsType ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not determine the $source fs-type and service.app.samba.fs-type was not defined} );
		return;
	}

	my %shortVars = %{ $OVF::Service::App::Samba::Vars::samba{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{directories}{'lockdir'}{path}            =~ s/<SAMBA_LOCK_PATH>/$lockPath/;
	$shortVars{directories}{'sharedir'}{path}           =~ s/<SAMBA_SHARE_PATH>/$sharePath/;
	$shortVars{directories}{'piddir'}{path}             =~ s/<SAMBA_PID_PATH>/$pidPath/;
	$shortVars{files}{'sp-smb.conf'}{path}              =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_SERVER_WORKGROUP>/$workgroup/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_NETBIOS_NAME>/$netbios/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_VIRTUAL_IP>/$virtualIp/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_LOCK_PATH>/$lockPath/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_SHARE_NAME>/$shareName/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_SHARE_PATH>/$sharePath/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_LOG_PATH>/$logPath/;
	$shortVars{files}{'sp-smb.conf'}{apply}{1}{content} =~ s/<SAMBA_PID_PATH>/$pidPath/;
	$shortVars{files}{'start-smb'}{apply}{1}{content}   =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/g;
	$shortVars{files}{'start-smb'}{apply}{1}{content}   =~ s/<SAMBA_VIRTUAL_IP>/$virtualIp/g;
	$shortVars{files}{'start-smb'}{apply}{1}{content}   =~ s/<SAMBA_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{files}{'start-smb'}{apply}{1}{content}   =~ s/<SAMBA_VIRTUAL_IP_DEV>/$virtualIpIf/;
	$shortVars{'virtualip'}{ip}                         =~ s/<SAMBA_VIRTUAL_IP>/$virtualIp/;
	$shortVars{'virtualip'}{prefix}                     =~ s/<SAMBA_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{'virtualip'}{dev}                        =~ s/<SAMBA_VIRTUAL_IP_DEV>/$virtualIpIf/;
	$shortVars{task}{'start'}{smbd}[ 0 ]                =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/;
	$shortVars{task}{'start'}{nmbd}[ 0 ]                =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/;
	$shortVars{task}{'smbpasswd'}[ 0 ]                  =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/;
	$shortVars{task}{cleardir}[ 0 ]                     =~ s/<SAMBA_SHARE_PATH>/$sharePath/;
	$shortVars{mount}{source}                           =~ s/<SAMBA_DEVICE>/$source/;
	$shortVars{mount}{target}                           =~ s/<SAMBA_SHARE_PATH>/$sharePath/;
	$shortVars{mount}{fstype}                           =~ s/<SAMBA_FS_TYPE>/$fsType/;

	if ( $distro eq 'SLES' ) {
		$shortVars{task}{'setrole'}      =~ s/<SAMBA_SERVER_ROLE>/$role/;
		$shortVars{task}{'setworkgroup'} =~ s/<SAMBA_SERVER_WORKGROUP>/$workgroup/;
	}

	# Disable native settings since using own config
	OVF::Manage::Init::disable( %options, %{ $shortVars{init} } );
	
	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'open-firewall'} } );
	}

	OVF::Manage::Storage::mount( %options, %{ $shortVars{mount} } );

	if ( $options{ovf}{current}{'service.app.samba.clear-storage'} ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{cleardir} } );
	}

	# CREATE Groups FIRST as USER creation may rely on them existing first.
	OVF::Manage::Groups::create( %options, %{ $shortVars{groups} } );
	OVF::Manage::Users::create( %options, %{ $shortVars{users} } );
	OVF::Manage::Directories::create( %options, %{ $shortVars{directories} } );
	OVF::Manage::Files::create( %options, %{ $shortVars{files} } );
	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{rmdistrofile} } );

	#OVF::Manage::Init::enable ( %options, %{ $shortVars{init} } );
	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{touchprintcap} } );
	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{smbpasswd} } );
	OVF::Manage::Network::addIp( %options, %{ $shortVars{virtualip} } );

	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{start}{smbd} } );
	OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{start}{nmbd} } );

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
	my $required = [ 'service.app.samba.workgroup', 'service.app.samba.netbiosname', 'service.app.samba.sharename', 'service.app.samba.lockpath', 'service.app.samba.logpath', 'service.app.samba.pidpath', 'service.app.samba.confpath', 'service.app.samba.storage-device', 'service.app.samba.fs-type', 'service.app.samba.virtualip', 'service.app.samba.virtualip-prefix', 'service.app.samba.virtualip-if', ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.app.samba.enabled', $requiredEnabled, %options ) );

	my $sharePath       = $options{ovf}{current}{'service.app.samba.sharepath'};
	my $lockPath        = $options{ovf}{current}{'service.app.samba.lockpath'};
	my $pidPath         = $options{ovf}{current}{'service.app.samba.pidpath'};
	my $confPath        = $options{ovf}{current}{'service.app.samba.confpath'};
	my $virtualIp       = $options{ovf}{current}{'service.app.samba.virtualip'};
	my $virtualIpPrefix = $options{ovf}{current}{'service.app.samba.virtualip-prefix'};
	my $virtualIpIf     = $options{ovf}{current}{'service.app.samba.virtualip-if'};

	my %shortVars = %{ $OVF::Service::App::Samba::Vars::samba{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	$shortVars{files}{'sp-smb.conf'}{path}    =~ s/<SAMBA_SMB_CONF_PATH>/$confPath/;
	$shortVars{directories}{'lockdir'}{path}  =~ s/<SAMBA_LOCK_PATH>/$lockPath/;
	$shortVars{directories}{'sharedir'}{path} =~ s/<SAMBA_SHARE_PATH>/$sharePath/;
	$shortVars{directories}{'piddir'}{path}   =~ s/<SAMBA_PID_PATH>/$pidPath/;
	$shortVars{'virtualip'}{ip}               =~ s/<SAMBA_VIRTUAL_IP>/$virtualIp/;
	$shortVars{'virtualip'}{prefix}           =~ s/<SAMBA_VIRTUAL_IP_PREFIX>/$virtualIpPrefix/;
	$shortVars{'virtualip'}{dev}              =~ s/<SAMBA_VIRTUAL_IP_DEV>/$virtualIpIf/;
	$shortVars{mount}{target}                 =~ s/<SAMBA_SHARE_PATH>/$sharePath/;

	if ( OVF::Service::Security::Firewall::Module::isRunning( %options ) ) {
		OVF::Manage::Tasks::run( %options, @{ $shortVars{task}{'close-firewall'} } );
	}

	OVF::Manage::Init::disable( %options, %{ $shortVars{init} } );
	OVF::Manage::Files::destroy( %options, %{ $shortVars{files} } );
	OVF::Manage::Directories::destroy( %options, %{ $shortVars{directories} } );
	OVF::Manage::Storage::umount( %options, %{ $shortVars{mount} } );
	OVF::Manage::Groups::destroy( %options, %{ $shortVars{groups} } );
	OVF::Manage::Users::destroy( %options, %{ $shortVars{users} } );
	OVF::Manage::Network::deleteIp( %options, %{ $shortVars{virtualip} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

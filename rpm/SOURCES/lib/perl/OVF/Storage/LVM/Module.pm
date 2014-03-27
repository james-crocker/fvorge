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

package OVF::Storage::LVM::Module;

use strict;
use warnings;

use Digest::MD5;
use POSIX;
use Storable;

use lib '../../../../perl';
use OVF::Manage::Files;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::State;
use OVF::Storage::LVM::Vars;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property       = 'storage.lvm';
	my $lvActionExpect = 'available|create|destroy';

	if ( !defined $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( !defined $options{ovf}{current}{$property} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $property undefined} );
		return;
	}

	if ( !OVF::State::ovfIsChanged( $property, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $property same as Previous property} );
		return;
	}

	foreach my $lvNum ( sort keys %{ $options{ovf}{current}{$property} } ) {
		Sys::Syslog::syslog( 'info', qq{$action ($lvNum) ...} );
		if ( !defined $options{ovf}{current}{$property}{$lvNum}{'action'} ) {
			Sys::Syslog::syslog( 'info', qq{$action ($lvNum) ::SKIP:: $property.$lvNum.action undefined} );
			next;
		}
		my $lvAction = $options{ovf}{current}{$property}{$lvNum}{'action'};
		if ( $lvAction !~ /^($lvActionExpect)$/ ) {
			Sys::Syslog::syslog( 'info', qq{$action ($lvNum) ::SKIP:: action=$lvAction; expecting $lvActionExpect } );
			next;
		}
		if ( exists $options{ovf}{previous} and defined $options{ovf}{previous}{$property}{$lvNum} ) {
			my @previous = OVF::State::printOvfProperties( '', %{ $options{ovf}{previous}{$property}{$lvNum} } );
			my @current  = OVF::State::printOvfProperties( '', %{ $options{ovf}{current}{$property}{$lvNum} } );
			if ( Digest::MD5::md5_hex( @previous ) eq Digest::MD5::md5_hex( @current ) ) {
				Sys::Syslog::syslog( 'info', qq{$action ($lvNum) ::SKIP:: Current properties same as Previous} );
				next;
			}
		}
		manage( $lvNum, $lvAction, \%options );
	}

	my $propertyOnboot = 'storage.lvm.option.booton';
	if ( $distro eq 'SLES' and OVF::State::ovfIsChanged( $propertyOnboot, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action Options OnBoot ...} );
		if ( $options{ovf}{current}{$propertyOnboot} ) {
			enableOnBoot( \%options );
		} else {
			disableOnBoot( \%options );
		}
	} else {
		Sys::Syslog::syslog( 'info', qq{$action Options OnBoot ::SKIP:: NO changes to apply or distribution NOT SLES} );
	}

}

sub enableOnBoot ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName";
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %lvmVars = %{ $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Init::enable( %options, %{ $lvmVars{init} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub disableOnBoot ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName";
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %lvmVars = %{ $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Init::disable( %options, %{ $lvmVars{init} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub manage ( $$\% ) {

	my $lvNum     = shift;
	my $lvmAction = shift;
	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName $lvmAction ($lvNum)";
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %lvItem  = %{ $options{ovf}{current}{'storage.lvm'}{$lvNum} };
	my %lvmVars = %{ Storable::dclone( $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} ) };

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM PV Devices not defined} ) and return ) if ( !defined $lvItem{'pv-device'} );
	my @pvDevices = split( /,/, $lvItem{'pv-device'} );

	Sys::Syslog::syslog( 'info', qq{$action with } . join( ', ', @pvDevices ) . q{ ...} );
	
	if ( $options{ovf}{current}{'service.iscsi.enabled'} and !OVF::Manage::Storage::iscsiAvailable() ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: ISCSI Services NOT available} );
		return;
	}

	if ( $options{ovf}{current}{'service.multipath.enabled'} and !OVF::Manage::Storage::multipathAvailable() ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Multipath Services NOT available} );
		return;
	}

	foreach my $dev ( @pvDevices ) {
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $dev DOES NOT EXIST} ) and return ) if ( !OVF::Manage::Storage::devExists( $dev ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $dev IN USE} ) and return ) if ( $lvmAction eq 'create' and OVF::Manage::Storage::devInUse( $dev ) );
	}

	my $lvSlices = $lvItem{'lv-slices'};
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM Slices not >= 1} ) and return ) if ( $lvmAction eq 'create' and ( !defined $lvItem{'lv-slices'} or !isdigit( $lvSlices ) or $lvSlices < 1 ) );
	
#	if ( !OVF::Manage::Storage::lvmAvailable() ) {
#		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM Services NOT available} );
#		return;
#	}

	my $vgName;
	if ( $lvItem{'vg-name'} ) {
		$vgName = $lvItem{'vg-name'};
	} else {
		$vgName = $lvmVars{defaults}{vgname} . $lvNum;
	}

	my $pvDeviceList = join( ' ', @pvDevices );
	$lvmVars{task}{vgcreate}[ 0 ] =~ s/<LVM_PV_DEVICES>/$pvDeviceList/;
	$lvmVars{task}{vgcreate}[ 0 ] =~ s/<LVM_VG_NAME>/$vgName/;
	$lvmVars{task}{vgremove}[ 0 ] =~ s/<LVM_VG_NAME>/$vgName/;
	$lvmVars{task}{vgavaily}[ 0 ] =~ s/<LVM_VG_NAME>/$vgName/;
	$lvmVars{task}{vgavailn}[ 0 ] =~ s/<LVM_VG_NAME>/$vgName/;

	#	$lvmVars{task}{freepe}[ 0 ]   =~ s/<LVM_VG_NAME>/$vgName/;

	my @lvNames      = split( /,/, $lvItem{'lv-name'} )    if ( $lvItem{'lv-name'} );
	my @lvMountPaths = split( /,/, $lvItem{'mount-path'} ) if ( $lvItem{'mount-path'} );
	my @lvMounts     = split( /,/, $lvItem{'mount'} )      if ( $lvItem{'mount'} );
	my @lvTypes      = split( /,/, $lvItem{'fs-type'} )    if ( $lvItem{'fs-type'} );
	my @lvTabs       = split( /,/, $lvItem{fstab} )        if ( $lvItem{fstab} );
	my @lvTabOptions = map { ( my $s = $_ ) =~ s/^\[//; $s =~ s/\]$//; $s } split( /\],\[/, $lvItem{'fstab-option'} ) if ( $lvItem{'fstab-option'} );
	my @lvSizes = split( /,/, $lvItem{'size'} ) if ( $lvItem{'size'} );

	# Make (VG) available if 'available' otherwise already available if part of 'create'
	if ( $lvmAction eq 'available' ) {
		OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{vgavaily} } );

		if ( !defined $lvItem{'lv-slices'} ) {
			my %lvInfo = OVF::Manage::Storage::getLvInfo( $vgName );
			if ( defined $lvInfo{$vgName}{'volumes'} ) {
				$lvSlices = $lvInfo{$vgName}{'volumes'};
				@lvNames  = ();
				for ( my $lvNum = 1; $lvNum <= $lvSlices; $lvNum++ ) {
					push( @lvNames, $lvInfo{$vgName}{$lvNum}{'name'} );
				}
			} else {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not find the number of logical volumes for volume group $vgName} );
				return;
			}
		}
	}

	# Create the Volume Groups (VG)
	if ( $lvmAction eq 'create' ) {

		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM Slice Sizes not defined} ) and return ) if ( !defined $lvItem{'size'} );

		my $totalSize = 0;
		my $numSizes  = 0;
		foreach my $size ( @lvSizes ) {
			if ( $size =~ /^(\d{1,3})%$/ ) {
				$totalSize += $1;
				$numSizes++;
			} else {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM Slice size unrecognized ($size). Expecting #%, ##% or ###%} );
				return;
			}
		}

		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Number of LVM Slice Sizes don't match number of LVM Slices} ) and return ) if ( $numSizes != $lvSlices );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: LVM Slice size total > 100%} ) and return ) if ( $totalSize > 100 );

		foreach my $pvDevice ( @pvDevices ) {
			my %lvmVars = %{ Storable::dclone( $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} ) };
			$lvmVars{task}{pvcreate}[ 0 ] =~ s/<LVM_PV_DEVICE>/$pvDevice/;
			$lvmVars{task}{pvremove}[ 0 ] =~ s/<LVM_PV_DEVICE>/$pvDevice/;
			if ( OVF::Manage::Storage::isLvmPv( $pvDevice ) ) {
				if ( !OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{pvremove} } ) ) {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not get exclusive access for device ($pvDevice) '}.$lvmVars{task}{pvremove}[0].qq{' Check mounts and dmsetup} );
				return;
				}
			}
			OVF::Manage::Storage::zero( $pvDevice, %options );
			if ( !OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{pvcreate} } ) ) {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not create PhysicalVolume ($pvDevice) '}.$lvmVars{task}{pvcreate}[0].qq{' Check mounts and dmsetup} );
				return;
			}
		}

		if ( !OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{vgcreate} } ) ) {
			Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not create VolumeGroup ($vgName) '}.$lvmVars{task}{vgcreate}[0].qq{' Check mounts and dmsetup} );
			return;
		}
		
		OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{vgavaily} } );
	}

	for ( my $slice = 0; $slice < $lvSlices; $slice++ ) {

		my $physicalExtent = $lvSizes[ $slice ] . 'FREE';

		my @lvcreate = @{ Storable::dclone( $lvmVars{task}{lvcreate} ) };
		my @lvavaily = @{ Storable::dclone( $lvmVars{task}{lvavaily} ) };
		my @lvavailn = @{ Storable::dclone( $lvmVars{task}{lvavailn} ) };
		my @lvremove = @{ Storable::dclone( $lvmVars{task}{lvremove} ) };
		my %lvfiles  = %{ Storable::dclone( $lvmVars{files} ) };
		my %mount    = %{ Storable::dclone( $lvmVars{mount} ) };

		my $sliceNum = $slice + 1;
		my $lvname;
		my $lvsource;
		my $lvtarget;
		my $lvtype;
		my $lvtab;
		my $lvtaboptions;
		my $lvmount;

		if ( $lvNames[ $slice ] ) {
			$lvname = $lvNames[ $slice ];
		} else {
			$lvname = $lvmVars{defaults}{lvname} . '-' . $sliceNum;
		}

		$lvsource = '/dev/' . $vgName . '/' . $lvname;

		if ( $lvTypes[ $slice ] ) {
			$lvtype = $lvTypes[ $slice ];
		} elsif ( $lvmAction eq 'available' and OVF::Manage::Storage::isBlockDevice( $lvsource ) ) {
			$lvtype = OVF::Manage::Storage::blkFsType( $lvsource );
		} else {
			$lvtype = $lvmVars{defaults}{fstype};
		}

		if ( $lvMountPaths[ $slice ] ) {
			$lvtarget = $lvMountPaths[ $slice ];
		} else {
			if ( $lvtype eq 'swap' ) {
				$lvtarget = 'swap';
			} else {
				$lvtarget = $lvmVars{defaults}{target} . '/' . $lvname;
			}
		}

		# If no add to fstab then default to LVM.pm default

		if ( $lvTabs[ $slice ] ) {
			$lvtab = $lvTabs[ $slice ];
		} else {
			$lvtab = $lvmVars{defaults}{addFstab};
		}

		# If no add fstab options then default to LVM.pm default
		if ( $lvTabOptions[ $slice ] ) {
			$lvtaboptions = $lvTabOptions[ $slice ] . qq(\t\t0 0);
		} else {
			$lvtaboptions = $lvmVars{defaults}{fstabOptions} . qq(\t\t0 0);
		}

		if ( $lvMounts[ $slice ] ) {
			$lvmount = $lvMounts[ $slice ];
		} else {
			$lvmount = $lvmVars{defaults}{mount};
		}

		$mount{source} =~ s/<LVM_LV_PATH>/$lvsource/;
		$mount{target} =~ s/<LVM_PATH>/$lvtarget/;
		$mount{fstype} =~ s/<LVM_FS_TYPE>/$lvtype/;
		$lvcreate[ 0 ] =~ s/<LVM_PHYSICAL_EXTENT>/$physicalExtent/;
		$lvcreate[ 0 ] =~ s/<LVM_LV_NAME>/$lvname/;
		$lvcreate[ 0 ] =~ s/<LVM_VG_NAME>/$vgName/;
		$lvremove[ 0 ] =~ s/<LVM_LV_PATH>/$lvsource/;
		$lvavaily[ 0 ] =~ s/<LVM_LV_PATH>/$lvsource/;
		$lvavailn[ 0 ] =~ s/<LVM_LV_PATH>/$lvsource/;

		$lvfiles{fstab}{apply}{1}{content} =~ s/<LVM_LV_PATH>/$lvsource/;
		$lvfiles{fstab}{apply}{1}{content} =~ s/<LVM_PATH>/$lvtarget/;
		$lvfiles{fstab}{apply}{1}{content} =~ s/<LVM_FS_TYPE>/$lvtype/;
		$lvfiles{fstab}{apply}{1}{content} =~ s/<LVM_FSTAB_OPTIONS>/$lvtaboptions/;

		my $deleteFstab = $lvfiles{fstab}{apply}{1}{content};

		if ( $lvmAction eq 'available' ) {
			OVF::Manage::Tasks::run( %options, @lvavaily );
			OVF::Manage::Storage::mount( %options, %mount ) if ( $lvmount );
			OVF::Manage::Files::create( %options, %lvfiles ) if ( $lvtab );
		} elsif ( $lvmAction eq 'create' ) {
			OVF::Manage::Tasks::run( %options, @lvcreate );
			OVF::Manage::Tasks::run( %options, @lvavaily );
			OVF::Manage::Storage::makeFilesystem( %options, %mount );
			OVF::Manage::Storage::mount( %options, %mount ) if ( $lvmount );
			OVF::Manage::Files::create( %options, %lvfiles ) if ( $lvtab );
		} elsif ( $lvmAction eq 'destroy' ) {
			$lvfiles{fstab}{save} = 0;
			$lvfiles{fstab}{apply}{1} = {
				'delete' => { 1 => { 'regex' => $deleteFstab } }
			};
			OVF::Manage::Files::create( %options, %lvfiles );
			OVF::Manage::Storage::umount( %options, %mount );
			OVF::Manage::Tasks::run( %options, @lvavailn );
			OVF::Manage::Tasks::run( %options, @lvremove );
		}
	}

	# Destory the VG and PV AFTER having already destroyed each LV
	if ( $lvmAction eq 'destroy' ) {
		OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{vgavailn} } );
		OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{vgremove} } );
		foreach my $pvDevice ( @pvDevices ) {
			my %lvmVars = %{ Storable::dclone( $OVF::Storage::LVM::Vars::lvm{$distro}{$major}{$minor}{$arch} ) };
			$lvmVars{task}{'pvremove'}[ 0 ] =~ s/<LVM_PV_DEVICE>/$pvDevice/;
			OVF::Manage::Tasks::run( %options, @{ $lvmVars{task}{'pvremove'} } );
		}
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

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

package OVF::Storage::Filesystems::Module;

use strict;
use warnings;

use Digest::MD5;
use POSIX;

use lib '../../../../perl';
use OVF::Manage::Files;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::State;
use OVF::Storage::Filesystems::Vars;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property       = 'storage.fs';
	my $fsActionExpect = 'available|create|destroy';

	if ( !defined $OVF::Storage::Filesystems::Vars::fs{$distro}{$major}{$minor}{$arch} ) {
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

	foreach my $fsNum ( sort keys %{ $options{ovf}{current}{$property} } ) {
		Sys::Syslog::syslog( 'info', qq{$action ($fsNum) ...} );
		if ( !defined $options{ovf}{current}{$property}{$fsNum}{'action'} ) {
			Sys::Syslog::syslog( 'info', qq{$action ($fsNum) ::SKIP:: $property.$fsNum.action undefined} );
			next;
		}
		my $fsAction = $options{ovf}{current}{$property}{$fsNum}{'action'};
		if ( $fsAction !~ /^($fsActionExpect)$/ ) {
			Sys::Syslog::syslog( 'info', qq{$action ($fsNum) ::SKIP:: action=$fsAction; expecting $fsActionExpect } );
			next;
		}
		if ( exists $options{ovf}{previous} and defined $options{ovf}{previous}{$property}{$fsNum} ) {
			my @previous = OVF::State::printOvfProperties( '', %{ $options{ovf}{previous}{$property}{$fsNum} } );
			my @current  = OVF::State::printOvfProperties( '', %{ $options{ovf}{current}{$property}{$fsNum} } );
			if ( Digest::MD5::md5_hex( @previous ) eq Digest::MD5::md5_hex( @current ) ) {
				Sys::Syslog::syslog( 'info', qq{$action ($fsNum) ::SKIP:: Current properties same as Previous} );
				next;
			}
		}
		manage( $fsNum, $fsAction, \%options );
	}

}

sub manage ( $$\% ) {

	my $fsNum    = shift;
	my $fsAction = shift;
	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName $fsAction ($fsNum)";
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %fsVars = %{ $OVF::Storage::Filesystems::Vars::fs{$distro}{$major}{$minor}{$arch} };
	my %fsItem = %{ $options{ovf}{current}{'storage.fs'}{$fsNum} };

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: Device NOT defined} ) and return ) if ( !defined $fsItem{device} );

	my $fsDevice     = $fsItem{device};
	my $fsPartitions = $fsItem{partitions};
	my $fsLabel      = $fsItem{label};
	my @fsMountPaths = split( /,/, $fsItem{'mount-path'} ) if ( $fsItem{'mount-path'} );
	my @fsMounts     = split( /,/, $fsItem{'mount'} ) if ( $fsItem{'mount'} );
	my @fsTypes      = split( /,/, $fsItem{'fs-type'} ) if ( $fsItem{'fs-type'} );
	my @fsTabs       = split( /,/, $fsItem{fstab} ) if ( $fsItem{fstab} );
	my @fsSizes      = split( /,/, $fsItem{'size'} ) if ( $fsItem{size} );
	my @fsTabOptions = map { ( my $s = $_ ) =~ s/^\[//; $s =~ s/\]$//; $s } split( /\],\[/, $fsItem{'fstab-option'} ) if ( $fsItem{'fstab-option'} );

	my $devName = ( split( /\//, $fsDevice ) )[ -1 ];
	
	my $processingType;

	if ( !defined $fsItem{'fs-type'} or ( defined $fsItem{'fs-type'} and $fsItem{'fs-type'} ne 'nfs' ) ) {

		Sys::Syslog::syslog( 'info', qq{$action $fsPartitions partitions $fsDevice } );
		
		if ( $options{ovf}{current}{'service.iscsi.enabled'} and !OVF::Manage::Storage::iscsiAvailable() ) {
			Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: ISCSI Services NOT available} );
			return;
		}

		if ( $options{ovf}{current}{'service.multipath.enabled'} and !OVF::Manage::Storage::multipathAvailable() ) {
			Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Multipath Services NOT available} );
			return;
		}

		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $fsDevice DOES NOT EXIST} )       and return ) if ( !OVF::Manage::Storage::devExists( $fsDevice ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $fsDevice BLKID DOES NOT EXIST} ) and return ) if ( $fsAction eq 'available' and !OVF::Manage::Storage::isBlockDevice( $fsDevice ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $fsDevice IN USE} )               and return ) if ( $fsAction eq 'create' and OVF::Manage::Storage::devInUse( $fsDevice ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Partitions not >= 0} )            and return ) if ( $fsAction eq 'create' and ( !defined $fsPartitions or !isdigit( $fsPartitions ) or $fsPartitions < 0 ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Label not gpt|msdos} ) and return ) if ( $fsAction eq 'create' and ( !defined $fsLabel or $fsLabel !~ /^(gpt|msdos)$/ ) );
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: No partition sizes defined. Expecting one or more #%} ) and return ) if ( !defined $fsItem{'size'} and $fsPartitions > 0 );

		if ( $fsAction eq 'create' ) {

			if ( $fsPartitions > 0 ) {

				my $totalSize = 0;
				my $numSizes  = 0;
				foreach my $size ( @fsSizes ) {
					if ( $size =~ /^(\d{1,3})%$/ ) {
						$totalSize += $1;
						$numSizes++;
					} else {
						Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Partition size unrecognized ($size). Expecting #%, ##% or ###%} );
						return;
					}
				}

				( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Number of partition sizes don't match number of partitions} ) and return ) if ( $numSizes != $fsPartitions );
				( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Partition size total > 100% Got ($totalSize%)} ) and return ) if ( $totalSize > 100 );

			}

			OVF::Manage::Storage::zero( $fsDevice, %options );
			OVF::Manage::Storage::label( $fsDevice, $fsLabel, %options );
			OVF::Manage::Storage::partition( $fsDevice, $fsPartitions, @fsSizes, %options );

		}

		if ( $fsAction eq 'available' and !defined $fsItem{partitions} ) {
			my %partedInfo = OVF::Manage::Storage::getPartedInfo( $fsDevice, '%' );
			if ( defined $partedInfo{partitions} ) {
				$fsPartitions = scalar( @{ $partedInfo{partitions} } );
			} else {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Could not find the number of partitions for device $fsDevice} );
				return;
			}
		}
		
	} else {

		Sys::Syslog::syslog( 'info', qq{$action NFS $fsDevice } );
		$fsPartitions = 0;
		$fsLabel      = '';
		$fsAction     = 'available';

	}

	for ( my $part = 0; $part <= $fsPartitions; $part++ ) {
		
		# Want to perform ONLY once for case of /dev/sda (whole device) or nfs
		last if ( $fsPartitions == 0 and $part > 0 );
		last if ( $fsPartitions > 0 and $part == $fsPartitions );

		my %fsVars = %{ Storable::dclone( $OVF::Storage::Filesystems::Vars::fs{$distro}{$major}{$minor}{$arch} ) };

		my $partNum = $part + 1;

		my $source;
		my $target;
		my $fstype;
		my $fspath;
		my $fstab;
		my $fstaboptions;
		my $fsmount;

		# MSDOS extended partition (not useable) p1,p2,p3,e4,l5,l6...
		if ( $fsLabel eq 'msdos' and $fsPartitions > 4 and $part >= 3 ) {
			$partNum++;
		}

		my $partSuffix;
		if ( $fsPartitions > 0 ) {
			if ( $fsDevice =~ /\/mapper\/mpath([a-z]+|\d+)$/ ) {
				if ( $distro ne 'SLES' ) {
					$partSuffix = 'p' . $partNum;
				} elsif ( $distro eq 'SLES' ) {
					$partSuffix = '_part' . $partNum;
				}
			} else {
				$partSuffix = $partNum;
			}
			$source = $fsDevice . $partSuffix;
		} else {
			$source = $fsDevice;
		}

		if ( $fsTypes[ $part ] ) {
			$fstype = $fsTypes[ $part ];
		} elsif ( $fsAction eq 'available' and OVF::Manage::Storage::isBlockDevice( $source ) ) {
			$fstype = OVF::Manage::Storage::blkFsType( $source );
		} else {
			$fstype = $fsVars{defaults}{fstype};
		}

		if ( $fsMountPaths[ $part ] ) {
			$target = $fsMountPaths[ $part ];
		} else {
			if ( $fstype eq 'swap' ) {
				$target = 'swap';
			} elsif ( $fstype eq 'nfs' ) {
				my $cleanPath = $source;
				$cleanPath =~ s/:\//\//;
				$target = $fsVars{defaults}{target} . '/' . $cleanPath;
			} else {
				$target = $fsVars{defaults}{target} . '/' . $devName . $partSuffix;
			}
		}
		
		if ( $fsAction ne 'destroy' and $fstype eq 'nfs' and OVF::Manage::Storage::devInUse( $target ) ) {
			Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $source $target IN USE} );
			last;
		} 

		if ( $fsTabs[ $part ] ) {
			$fstab = $fsTabs[ $part ];
		} else {
			$fstab = $fsVars{defaults}{addFstab};
		}

		if ( $fsTabOptions[ $part ] ) {
			$fstaboptions = $fsTabOptions[ $part ] . qq(\t\t0 0);
		} else {
			$fstaboptions = $fsVars{defaults}{fstabOptions} . qq(\t\t0 0);
		}

		if ( $fsMounts[ $part ] ) {
			$fsmount = $fsMounts[ $part ];
		} else {
			$fsmount = $fsVars{defaults}{mount};
		}

		$fsVars{mount}{source}                   =~ s/<FS_DEVICE>/$source/;
		$fsVars{mount}{target}                   =~ s/<FS_PATH>/$target/;
		$fsVars{mount}{fstype}                   =~ s/<FS_FS_TYPE>/$fstype/;
		$fsVars{files}{fstab}{apply}{1}{content} =~ s/<FS_DEVICE>/$source/;
		$fsVars{files}{fstab}{apply}{1}{content} =~ s/<FS_PATH>/$target/;
		$fsVars{files}{fstab}{apply}{1}{content} =~ s/<FS_FS_TYPE>/$fstype/;
		$fsVars{files}{fstab}{apply}{1}{content} =~ s/<FS_FSTAB_OPTIONS>/$fstaboptions/;

		my $deleteFstab = $fsVars{files}{fstab}{apply}{1}{content};

		if ( $fsAction eq 'available' ) {
			OVF::Manage::Storage::mount( %options, %{ $fsVars{mount} } ) if ( $fsmount );
			OVF::Manage::Files::create( %options, %{ $fsVars{files} } ) if ( $fstab );
		} elsif ( $fsAction eq 'create' ) {
			OVF::Manage::Storage::makeFilesystem( %options, %{ $fsVars{mount} } ) if ( $fstype ne 'nfs' );
			OVF::Manage::Storage::mount( %options, %{ $fsVars{mount} } ) if ( $fsmount );
			OVF::Manage::Files::create( %options, %{ $fsVars{files} } ) if ( $fstab );
		} elsif ( $fsAction eq 'destroy' ) {
			OVF::Manage::Storage::umount( %options, %{ $fsVars{mount} } );
			$fsVars{files}{fstab}{save} = 0;
			$fsVars{files}{fstab}{apply}{1} = {
				'delete' => { 1 => { 'regex' => $deleteFstab } }
			};
			OVF::Manage::Files::create( %options, %{ $fsVars{files} } );
			OVF::Manage::Storage::zero( $source, %options ) if ( $fstype ne 'nfs' );
		}

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

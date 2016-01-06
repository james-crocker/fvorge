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

package OVF::Manage::Storage;

use strict;
use warnings;

use File::Path;
use POSIX;

use lib '../../../perl';

use SIOS::CommonVars;
use OVF::Vars::Common;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd       = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};
my $redirStdErrCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{redirStdErrCmd};

my $retriesMax   = $OVF::Vars::Common::sysVars{'retry'}{'availale'}{'max'};
my $retriesSleep = $OVF::Vars::Common::sysVars{'retry'}{'availale'}{'sleep'};

sub udevSettle ( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $udevsettleCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{udevsettleCmd};
	system( $udevsettleCmd ) == 0 or ( Sys::Syslog::syslog( 'warning', qq{$thisSubName WARNING: $udevsettleCmd ($?:$!)} ) and return 0 );
	return 1;

}

sub iscsiAvailable( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	return 0 if ( !udevSettle() );

	my @serviceCheckCmds = ( '/etc/init.d/iscsi status', '/etc/init.d/iscsid status', 'iscsiadm -m host' );

	my $isReady = 0;

	foreach my $chk ( @serviceCheckCmds ) {
		my $retry = 0;
		while ( $retry < $retriesMax ) {
			udevSettle();
			my $retVal = system( qq{$chk $quietCmd} );
			if ( $retVal != 0 ) {
				$retry++;
				Sys::Syslog::syslog( 'info', qq{$thisSubName ::RETRY:: ($chk) $retry of $retriesMax. Sleeping $retriesSleep} );
				sleep $retriesSleep;
			} else {
				$isReady++;
				last;
			}
		}
		return 0 if ( $retry >= $retriesMax );
	}

	if ( $isReady == scalar( @serviceCheckCmds ) ) {
		return 1;
	} else {
		return 0;
	}

}

sub multipathAvailable( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	return 0 if ( !udevSettle() );

	my @serviceCheckCmds = ( '/etc/init.d/multipathd status', qq{multipath -F $quietCmd;multipath -r $quietCmd;multipath -l | egrep '^mpath'} );

	my $isReady = 0;

	foreach my $chk ( @serviceCheckCmds ) {
		my $retry = 0;
		while ( $retry < $retriesMax ) {
			udevSettle();
			my $retVal = system( qq{$chk $quietCmd} );
			if ( $retVal != 0 ) {
				$retry++;
				Sys::Syslog::syslog( 'info', qq{$thisSubName ::RETRY:: ($chk) $retry of $retriesMax. Sleeping $retriesSleep} );
				sleep $retriesSleep;
			} else {
				$isReady++;
				last;
			}
		}
		return 0 if ( $retry >= $retriesMax );
	}

	if ( $isReady == scalar( @serviceCheckCmds ) ) {
		return 1;
	} else {
		return 0;
	}

}

#sub lvmAvailable( ) {
#
#	my $thisSubName = ( caller( 0 ) )[ 3 ];
#
#	return 0 if ( !udevSettle() );
#
#	my $lvmLoopFile = '/tmp/fvorge-lvm-available-test';
#	my $loopDev     = '/dev/loop6';
#
#	my @serviceCheckCmds = ( qq{dd if=/dev/zero of=$lvmLoopFile bs=1M count=10}, qq{losetup $loopDev;if [ $? == 1 ]; then echo 0; else echo $?; fi}, qq{losetup $loopDev $lvmLoopFile}, qq{pvcreate $loopDev}, qq{pvremove -ff $loopDev}, qq{losetup -d $loopDev}, qq{rm $lvmLoopFile} );
#
#	my $isReady = 0;
#
#	foreach my $chk ( @serviceCheckCmds ) {
#		my $retry = 0;
#		while ( $retry < $retriesMax ) {
#			udevSettle();
#			my $retVal = system( qq{$chk $quietCmd} );
#			if ( $retVal != 0 ) {
#				$retry++;
#				Sys::Syslog::syslog( 'info', qq{$thisSubName ::RETRY:: ($chk) $retry of $retriesMax. Sleeping $retriesSleep} );
#				sleep $retriesSleep;
#			} else {
#				$isReady++;
#				last;
#			}
#		}
#		return 0 if ( $retry >= $retriesMax );
#	}
#
#	if ( $isReady == scalar( @serviceCheckCmds ) ) {
#		return 1;
#	} else {
#		return 0;
#	}
#
#}

sub devExists ( $ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	return 0 if ( !udevSettle() );

	my $objDev = shift;

	if ( defined $objDev and $objDev =~ /^\/dev\// and -e $objDev ) {
		return 1;
	} else {
		return 0;
	}

}

sub isLvmPv ( $ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	return 0 if ( !udevSettle() );

	my $objDev = shift;

	return 0 if ( !defined $objDev );

	my $pvdisplayCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{pvdisplayCmd};

	my $retVal = system( "$pvdisplayCmd $objDev $quietCmd" );

	if ( $retVal == 0 ) {
		return 1;
	} else {
		return 0;
	}

}

sub makeFilesystem ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $mkfsCmd      = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mkfsCmd};
	my $mkSwapCmd    = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mkSwapCmd};
	my $partprobeCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partprobeCmd};

	my $source = $ovfObject{source};
	my $fstype = $ovfObject{fstype};

	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: Source not defined} )  and return ) if ( !defined $source );
	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: FS-Type not defined} ) and return ) if ( !defined $fstype );

	return if ( !udevSettle() );

	my $action = "$thisSubName ($fstype) $source";

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source doesn't exist} )                                       and return ) if ( !devExists( $source ) );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source in use} )                                              and return ) if ( devInUse( $source ) );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: Won't make filesystem for 'loop' or 'bind' filesystem types} ) and return ) if ( $fstype eq 'loop' or $fstype eq 'bind' );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	system( qq{$partprobeCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $partprobeCmd ($?:$!)} );

	if ( $fstype eq 'swap' ) {
		system( qq{$mkSwapCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $mkSwapCmd $source ($?:$!)} );
	} else {
		system( qq{$mkfsCmd $fstype $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $mkfsCmd $fstype $source ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub partition ( \$\$\@\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $source )     = ${ ( shift ) };
	my ( $partitions ) = ${ ( shift ) };
	my ( @sizes )      = @{ ( shift ) };    # Must
	my ( %options )    = %{ ( shift ) };

	my $partedCmd    = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partedCmd};
	my $partprobeCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partprobeCmd};

	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: Source not defined} )     and return ) if ( !defined $source );
	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: Partitions not defined} ) and return ) if ( !defined $partitions );

	return if ( !udevSettle() );

	my $action = "$thisSubName $source with $partitions partitions";

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: Zero partitions requested} )                                      and return ) if ( $partitions == 0 );
	( Sys::Syslog::syslog( 'err',  qq{$action ::SKIP:: $source doesn't exist} )                                          and return ) if ( !devExists( $source ) );
	( Sys::Syslog::syslog( 'err',  qq{$action ::SKIP:: $source in use} )                                                 and return ) if ( devInUse( $source ) );
	( Sys::Syslog::syslog( 'err',  qq{$action ::SKIP:: Number of partition sizes don't match the number of partitions} ) and return ) if ( scalar( @sizes ) != $partitions );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	my %partInfo = getPartedInfo( \$source, '%' );

	my $capacity = $partInfo{capacity};
	my $label    = $partInfo{label};

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source has no label} ) and return ) if ( !defined $label );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: Capacity <= 0. Got $capacity} ) and return ) if ( !defined $capacity or $capacity <= 0 );

	my $startSize    = '0%';
	my $startSizeNum = 0;
	my $partType;

	my $count = 1;

	foreach my $partSize ( @sizes ) {

		my $partSizeNum = $partSize;
		$partSizeNum =~ s/\%//g;

		if ( $label eq 'msdos' ) {
			if ( $count == 4 and $partitions > 4 ) {
				$partType = 'extended';
			} elsif ( $count <= 4 ) {
				$partType = 'primary';
			} elsif ( $count > 4 ) {
				$partType = 'logical';
			}
		} elsif ( $label eq 'gpt' ) {
			$partType = 'gptPart' . $count;
		}

		if ( $label eq 'msdos' and $partType eq 'extended' ) {
			my $partitionCmd = qq{$partedCmd $source unit % mkpart $partType $startSize $capacity\%};
			system( qq{$partitionCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $partitionCmd ($?:$!)} );
			$count++;
			redo;
		} else {

			my $endSizeNum = $startSizeNum + $partSizeNum;
			my $endSize    = $endSizeNum . '%';

			my $partitionCmd = qq{$partedCmd $source unit % mkpart $partType $startSize $endSize};
			system( qq{$partitionCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $partitionCmd ($?:$!)} );

			$startSizeNum += $partSizeNum;
			$startSize = $startSizeNum . '%';

			$count++;

		}

	}

	system( qq{$partprobeCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $partprobeCmd ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub label ( \$\$\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $source )  = ${ ( shift ) };
	my ( $label )   = ${ ( shift ) };
	my ( %options ) = %{ ( shift ) };

	my $partedCmd    = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partedCmd};
	my $partprobeCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partprobeCmd};

	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: Source not defined} ) and return ) if ( !defined $source );
	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: No label provided} )  and return ) if ( !defined $label );

	return if ( !udevSettle() );

	my $action = "$thisSubName $source as $label";

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source doesn't exist} ) and return ) if ( !devExists( $source ) );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source in use} )        and return ) if ( devInUse( $source ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	my $mkLabelCmd = qq{$partedCmd $source mklabel $label};

	system( $mkLabelCmd ) == 0                         or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $mkLabelCmd ($?:$!)} );
	system( qq{$partprobeCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $partprobeCmd ($?:$!)} );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub getVgInfo ( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $vgdisplayCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{vgdisplayCmd};

	my %vgInfo;
	my $groupsCount = 0;

	return %vgInfo if ( !udevSettle() );

	my $retVal = system( $vgdisplayCmd );

	return %vgInfo if ( $retVal != 0 );

	my @vgData = qx( $vgdisplayCmd );

	#[root@cos1 ~]# vgdisplay -c
	#sevg1:r/w:772:-1:0:2:0:-1:0:1:1:1044480:4096:255:191:64:EB3LJ1-HTWR-T11i-Fou0-nW8V-ziwp-BZbV20

	foreach my $item ( @vgData ) {
		next if ( $item !~ /:/ );
		my @vg = split( ':', $item );
		$groupsCount++;
		$vgInfo{$groupsCount}{'name'}           = $vg[ 0 ];
		$vgInfo{$groupsCount}{'access'}         = $vg[ 1 ];
		$vgInfo{$groupsCount}{'status'}         = $vg[ 2 ];
		$vgInfo{$groupsCount}{'int-grp-number'} = $vg[ 3 ];
		$vgInfo{$groupsCount}{'max-lv'}         = $vg[ 4 ];
		$vgInfo{$groupsCount}{'current-lv'}     = $vg[ 5 ];
		$vgInfo{$groupsCount}{'open-lv'}        = $vg[ 6 ];
		$vgInfo{$groupsCount}{'max-lv-size'}    = $vg[ 7 ];
		$vgInfo{$groupsCount}{'max-pv'}         = $vg[ 8 ];
		$vgInfo{$groupsCount}{'current-pv'}     = $vg[ 9 ];
		$vgInfo{$groupsCount}{'actual-pv'}      = $vg[ 10 ];
		$vgInfo{$groupsCount}{'vg-size'}        = $vg[ 11 ];
		$vgInfo{$groupsCount}{'extent-size'}    = $vg[ 12 ];
		$vgInfo{$groupsCount}{'extent-total'}   = $vg[ 13 ];
		$vgInfo{$groupsCount}{'extent-alloc'}   = $vg[ 14 ];
		$vgInfo{$groupsCount}{'extent-free'}    = $vg[ 15 ];
		$vgInfo{$groupsCount}{'uuid'}           = $vg[ 16 ];
	}

	$vgInfo{'groups'} = $groupsCount if ( $groupsCount > 0 );

	return %vgInfo;

}

sub getLvInfo ( \$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $vgName ) = ${ ( shift ) };

	my $lvdisplayCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{lvdisplayCmd};

	my %lvInfo;
	my $volumesCount = 0;

	return %lvInfo if ( !udevSettle() );

	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: No VolumeGroup name provided} ) and return %lvInfo ) if ( !defined $vgName );

	my $retVal = system( qq{$lvdisplayCmd $vgName} );

	return %lvInfo if ( $retVal != 0 );

	my @lvData = qx( $lvdisplayCmd $vgName );

	#[root@cos1 tmp]# lvdisplay -c sevg1
	#  /dev/sevg1/fvorge-lv-1:sevg1:3:0:-1:0:1040384:127:-1:0:-1:-1:-1
	#  /dev/sevg1/fvorge-lv-2:sevg1:3:0:-1:0:524288:64:-1:0:-1:-1:-1
	#$? = 0
	#[root@cos1 tmp]# lvdisplay -c sevg1df
	#  Volume group "sevg1df" not found
	#  Skipping volume group sevg1df
	#$? = 5

	foreach my $item ( @lvData ) {
		next if ( $item !~ /:/ );
		my @lv = split( ':', $item );
		$volumesCount++;
		$lvInfo{$vgName}{$volumesCount}{'name'}           = $lv[ 0 ];
		$lvInfo{$vgName}{$volumesCount}{'vgname'}         = $lv[ 1 ];
		$lvInfo{$vgName}{$volumesCount}{'access'}         = $lv[ 2 ];
		$lvInfo{$vgName}{$volumesCount}{'status'}         = $lv[ 3 ];
		$lvInfo{$vgName}{$volumesCount}{'int-vol-number'} = $lv[ 4 ];
		$lvInfo{$vgName}{$volumesCount}{'open-count'}     = $lv[ 5 ];
		$lvInfo{$vgName}{$volumesCount}{'size'}           = $lv[ 6 ];
		$lvInfo{$vgName}{$volumesCount}{'extents-assoc'}  = $lv[ 7 ];
		$lvInfo{$vgName}{$volumesCount}{'extents-alloc'}  = $lv[ 8 ];
		$lvInfo{$vgName}{$volumesCount}{'alloc-policy'}   = $lv[ 9 ];
		$lvInfo{$vgName}{$volumesCount}{'read-ahead'}     = $lv[ 10 ];
		$lvInfo{$vgName}{$volumesCount}{'major'}          = $lv[ 11 ];
		$lvInfo{$vgName}{$volumesCount}{'minor'}          = $lv[ 12 ];
	}

	$lvInfo{$vgName}{'volumes'} = $volumesCount if ( $volumesCount > 0 );

	return %lvInfo;

}

sub getPartedInfo ( \$$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $source ) = ${ ( shift ) };
	my ( $unit ) = ( shift );

	my $partedCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partedCmd};

	my %partInfo;
	my @partitions;

	( Sys::Syslog::syslog( 'warning', qq{$thisSubName $source does not exist} )            and return %partInfo ) if ( !devExists( $source ) );
	( Sys::Syslog::syslog( 'warning', qq{$thisSubName unit is not s|B|kB|MB|GB|TB|cyl|%} ) and return %partInfo ) if ( $unit !~ /s|B|kB|MB|GB|TB|cyl|%/i );

	return %partInfo if ( !udevSettle() );

	my @partedData = qx( $partedCmd $source unit $unit print );

	#GPT
	#CYL;
	#/dev/sda:130cyl:scsi:512:512:gpt:QEMQEMU HARDDISK;
	#130:255:63:8225kB;
	#1:0cyl:20cyl:19cyl::logical:;
	#2:20cyl:40cyl:20cyl:ext2:extended:;
	#3:40cyl:60cyl:20cyl:ext3:primary:;
	#4:60cyl:80cyl:20cyl::logical:;
	#5:80cyl:99cyl:19cyl::eoon:;

	#MSDOS
	#CYL;
	#/dev/sda:130cyl:scsi:512:512:msdos:QEMU QEMU HARDDISK;
	#130:255:63:8225kB;
	#1:0cyl:9cyl:9cyl:ext4::type=83;
	#2:9cyl:20cyl:10cyl:::type=83;
	#3:20cyl:29cyl:9cyl:::type=83;
	#4:29cyl:130cyl:100cyl:::lba, type=0f;
	#5:30cyl:39cyl:8cyl:ext3::type=83;

	# parted -m -s /dev/sda1 unit % print
	#BYT;
	#/dev/sda1:100%:unknown:512:512:loop:Unknown;
	#1:0.00%:100%:100%:ext4::;

	#parted -m -s /dev/sdb unit % print
	#Error: /dev/sdb: unrecognised disk label

	# Non-English systems may use ',' instead of '.' for decimal notation

	if ( $partedData[ 0 ] =~ /(BYT|CYL);/ ) {

		foreach my $data ( @partedData ) {
			chomp( $data );
			if ( $data =~ /\s*([^:]+):([\d\.\,]+)$unit:([^:]+):(\d+):(\d+):([^:]+):([^:]+);/i ) {
				$partInfo{devname}  = $1;
				$partInfo{capacity} = $2;
				$partInfo{type}     = $3;
				$partInfo{heads}    = $4;
				$partInfo{sectors}  = $5;
				$partInfo{label}    = $6;
				$partInfo{vendor}   = $7;
			} elsif ( $data =~ /\s*(\d+):([\d\.\,]+)$unit:([\d\.\,]+)$unit:([\d\.\,]+)$unit:([^:]*):([^:]*):([^:]*);/i ) {
				my $number = $1;
				push( @partitions, $number );
				$partInfo{$number}{'start'}   = $2;
				$partInfo{$number}{'end'}     = $3;
				$partInfo{$number}{'size'}    = $4;
				$partInfo{$number}{'fs-type'} = $5;
				$partInfo{$number}{'name'}    = $6;
				$partInfo{$number}{'type'}    = $7;
			}
		}

	} else {

		# called with older version which did not have --machine
		# Also, Model, Disk, Sector size WILL dislay in localalized language - so make pattern generic

		foreach my $data ( @partedData ) {
			chomp( $data );

			next if ( $data =~ /^\s*$/ );

			if ( defined $partInfo{label} ) {
				if ( $partInfo{label} eq 'msdos' ) {
					if ( $data =~ /^\s+(\d+)\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+(primary|extended|logical)\s+(\S*)\s*(\S*)/i ) {
						my $number = $1;
						push( @partitions, $number );
						$partInfo{$number}{'start'}   = $2;
						$partInfo{$number}{'end'}     = $3;
						$partInfo{$number}{'size'}    = $4;
						$partInfo{$number}{'fs-type'} = $6;
						$partInfo{$number}{'name'}    = '';
						$partInfo{$number}{'type'}    = $7;
					}
				} elsif ( $partInfo{label} eq 'gpt' ) {
					if ( $data =~ /^\s+(\d+)\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+(\S*)\s+(\S*)\s*(\S*)/i ) {
						my $number = $1;
						push( @partitions, $number );
						$partInfo{$number}{'start'}   = $2;
						$partInfo{$number}{'end'}     = $3;
						$partInfo{$number}{'size'}    = $4;
						$partInfo{$number}{'fs-type'} = $5;
						$partInfo{$number}{'name'}    = $6;
						$partInfo{$number}{'type'}    = $7;
					}
				} elsif ( $partInfo{label} eq 'loop' ) {
					if ( $data =~ /^\s+(\d+)\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+([\d\.\,]+)$unit\s+(\S*)\s+(\S*)/i ) {
						my $number = $1;
						push( @partitions, $number );
						$partInfo{$number}{'start'}   = $2;
						$partInfo{$number}{'end'}     = $3;
						$partInfo{$number}{'size'}    = $4;
						$partInfo{$number}{'fs-type'} = $5;
						$partInfo{$number}{'name'}    = '';
						$partInfo{$number}{'type'}    = $6;
					}
				}

			} elsif ( $data =~ /:\s+([^\)\(]+)\s*\((\S+)\)\s*$/ ) {
				$partInfo{vendor} = $1;
				$partInfo{type}   = $2;
			} elsif ( $data =~ /\s+([^:]+):\s*([\d\.\,]+)$unit\s*/ ) {
				$partInfo{devname}  = $1;
				$partInfo{capacity} = $2;
			} elsif ( $data =~ /\([^\)\(]+\/[^\)\(]+\):\s*(\d+)\S+\/(\d+)\S+\s*$/ ) {
				$partInfo{heads}   = $1;
				$partInfo{sectors} = $2;
			} elsif ( $data =~ /:\s*([^\)\(]+)\s*$/ ) {
				$partInfo{label} = $1;
			}

		}

	}

	$partInfo{partitions} = @partitions if ( defined $partInfo{devname} );

	return %partInfo;

}

sub isBlockDevice ( \$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $objDev = ${ ( shift ) };

	return 0 if ( !defined $objDev );

	my %devDetail = getPartedInfo( $objDev, '%' );

	if ( defined $devDetail{devname} ) {
		return 1;
	} else {
		return 0;
	}

}

sub blkFsType ( \$ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $objDev = ${ ( shift ) };

	return undef if ( !defined $objDev );

	my %devDetail = getPartedInfo( $objDev, '%' );

	# When parted called on /dev/sda3 only {1} returned
	# When called on /dev/sda it returns all the partitions (if whole block device not used, in which case {1} still applies for /dev/sda)

	if ( defined $devDetail{1}{'fs-type'} ) {
		return $devDetail{1}{'fs-type'};
	} else {
		return undef;
	}

}

sub devInUse ( $ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $objDev = shift;

	return 0 if ( !defined $objDev );

	my $lvmMapperDev;
	if ( $objDev !~ /^\/dev\/(mapper|mpath)\// ) {
		if ( $objDev =~ /^\/dev\/([^\/]+)\/([^\/]+)/ ) {
			my $vg = $1;
			my $lv = $2;

			$lv =~ s/-/--/g;    # LVM mapper uses '-'
			$lvmMapperDev = "/dev/mapper/$vg-$lv";
		}
	}

	my $fuserCmd     = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{fuserCmd};
	my $fuserReadCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{fuserReadCmd};
	my $mntListCmd   = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mntListCmd};
	my $swapListCmd  = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{swapListCmd};

	return 0 if ( !udevSettle() );

	# Check for mounts
	my @mntVal = qx{$mntListCmd};
	foreach my $mnt ( @mntVal ) {
		my $regex = $objDev;
		$regex .= "|$lvmMapperDev" if ( $lvmMapperDev );
		if ( $mnt =~ /$regex/ ) {
			return 1;
		}
	}

	return 0 if ( !isBlockDevice( $objDev ) );

	my $retVal = system( "$fuserCmd $objDev* $quietCmd" );

	if ( $retVal == 0 ) {

		# Do another check to confirm it isn't the multipathd attached to some device
		# eg. /dev/sdg:            root       2164 f.... multipathd

		my @fuserVal = qx{$fuserReadCmd $objDev* $redirStdErrCmd};

		if ( @fuserVal ) {

			my $otherUse = 0;

			# Don't need the 'header'
			shift( @fuserVal );

			foreach my $item ( @fuserVal ) {
				chomp( $item );
				$otherUse = 1 if ( $item !~ /f....\s+multipathd/ );
			}

			if ( $otherUse == 1 ) {
				return 1;
			}

		}

	}

	# Check if in swapon
	my @swapVal = qx{$swapListCmd};
	foreach my $swap ( @swapVal ) {
		my $regex = $objDev;
		$regex .= "|$lvmMapperDev" if ( $lvmMapperDev );
		if ( $swap =~ /$regex/ ) {
			return 1;
		}
	}

	# If this far then not in use
	return 0;

}

sub zero ( \$\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $source )  = ${ ( shift ) };
	my ( %options ) = %{ ( shift ) };

	( Sys::Syslog::syslog( 'err', qq{$thisSubName ::SKIP:: Source not defined} ) and return ) if ( !defined $source );

	my $partprobeCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{partprobeCmd};

	my $action = "$thisSubName $source";

	return if ( !udevSettle() );

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source doesn't exist} ) and return ) if ( !devExists( $source ) );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source in use} )        and return ) if ( devInUse( $source ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	my $removePartitionCmd = qq{dd if=/dev/zero of=$source bs=1M count=1};
	system( qq{$removePartitionCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'err', qq{$thisSubName ERROR: $removePartitionCmd ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub mount ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $mntCmd     = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mountCmd};
	my $mntBindCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mountBindCmd};
	my $mntLoopCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mountLoopCmd};
	my $swapOnCmd  = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{swapOnCmd};
	my $source     = $ovfObject{source};
	my $target     = $ovfObject{target};
	my $fstype     = $ovfObject{fstype};

	my $action = "$thisSubName $source $target";

	my $host;
	if ( $fstype eq 'nfs' ) {
		if ( $source =~ /^([^:]+):/ ) {
			$host = $1;
		}
	}

	return if ( !udevSettle() );

	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source doesn't exist} ) and return ) if ( ( $fstype ne 'bind' and $fstype ne 'nfs' ) and !devExists( $source ) );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: BIND Source $source doesn't exist} ) and return ) if ( $fstype eq 'bind' and !-e $source );
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: $source not reachable} )             and return ) if ( $fstype eq 'nfs'  and !OVF::Manage::Network::pingHost( $host ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	createTarget( \%options, \%ovfObject ) if ( $fstype ne 'swap' );

	if ( $fstype eq 'loop' ) {
		system( qq{$mntLoopCmd $source $target $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $mntLoopCmd $source $target ($?:$!)} );
	} elsif ( $fstype eq 'bind' ) {
		system( qq{$mntBindCmd $source $target $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $mntBindCmd $source $target ($?:$!)} );
	} elsif ( $fstype eq 'swap' ) {
		system( qq{$swapOnCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $swapOnCmd $source ($?:$!)} );
	} else {
		system( qq{$mntCmd $fstype $source $target $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $mntCmd $fstype $source $target ($?:$!)} );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub umount ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $umntCmd    = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{umountCmd};
	my $swapOffCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{swapOffCmd};
	my $source     = $ovfObject{source};
	my $target     = $ovfObject{target};
	my $fstype     = $ovfObject{fstype};

	my $action = "$thisSubName $target";

	return if ( !udevSettle() );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );
	if ( $fstype eq 'swap' ) {
		system( qq{$swapOffCmd $source $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $swapOffCmd $source ($?:$!)} );
	} else {
		my $retVal;
		$retVal = system( qq{$umntCmd $target $quietCmd} );
		if ( $retVal ) {
			Sys::Syslog::syslog( 'warning', qq{$thisSubName Couldn't $umntCmd $target ($?:$!)} );
			return;
		} else {
			removeTarget( \%options, \%ovfObject );
		}
	}
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub createTarget ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $mkdirCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mkdirCmd};
	my $target   = $ovfObject{target};

	my $action = "$thisSubName $target";

	return if ( -d $target );
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );
	mkpath( $target ) or Sys::Syslog::syslog( 'err', qq{$thisSubName Couldn't mkpath [ $target ] ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub removeTarget ( \%\% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $target = $ovfObject{target};

	my $action = "$thisSubName $target";

	return if ( !-d $target );
	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );
	rmtree( $target ) or Sys::Syslog::syslog( 'err', qq{$thisSubName Couldn't rmtree [ $target ] ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

1;

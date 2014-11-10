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

package OVF::Automation::Module;

use strict;
use warnings;

use Tie::File;

use lib '../../../perl';
use OVF::Automation::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub deploy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};
	my $arch   = $options{'architecture'};

	my $majNum  = $options{'majNum'};
	my $minNum  = $options{'minNum'};
	my $grpNum  = $options{'grpNum'};
	my $instNum = $options{'instNum'};

	my $targetHost      = $options{'targethost'};
	my $targetDatastore = $options{'targetdatastore'};
	my $diskMode        = $options{'diskmode'};
	my $vmName          = $options{'vmname'};
	my $sourceOvf       = $options{'sourceovf'};
	my $vcenter         = $options{'vcenter'};
	my $vcUser          = $options{'vcenteruser'};
	my $vcPass          = $options{'vcenterpassword'};
	my $dataCenter      = $options{'datacenter'};
	my $propPath        = $options{'proppath'};
	my $vmFolder        = $options{'folder'};
	my $cluster         = $options{'cluster'};
	my $net             = $options{'net'};

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $ovftool             = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'ovftool'}{'path'};

	if ( !-x $ovftool ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO executable ($ovftool) FOUND for $distro $major.$minor $arch} );
		return;
	}

	my @propertiesOverride;
	if ( $options{'propoverride'} ) {
		if ( defined $propPath and -e $propPath ) {
			tie @propertiesOverride, 'Tie::File', $propPath, autochomp => 0 or ( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: Couldn't open OVF Override Properties file [ $propPath ] ($?:$!)} ) and return );
		} else {
			Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO property path ($propPath) FOUND ($?:$!)} );
			return;			
		}
	}

	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : INITIATE} );
	if ( defined $cluster ) {
		$cluster = qq{"$cluster"/};
	} else {
		$cluster = '';
	}
	
	# To overwrite existing vm. Need option for this. Default to *not* overwrite existing vm.
	#my $deployCmd = qq{$ovftool \\\n--overwrite \\\n--powerOffTarget \\\n--name="$vmName"};
	my $deployCmd = qq{$ovftool \\\n--name="$vmName"};

	if ( defined $vmFolder ) {
		$deployCmd .= qq{ \\\n--vmFolder="$vmFolder"};
	}
	
	if ( defined $net ) {
		foreach my $sourceTarget ( split( /\s*;\s*/, $net ) ) {
			my ( $source, $target ) = split( /\s*=\s*/, $sourceTarget );
			$deployCmd .= qq{ \\\n--net:"$source"="$target"};
		}
	}
	
	$deployCmd .= qq{ \\\n--datastore="$targetDatastore" \\\n--diskMode=$diskMode \\\n@propertiesOverride$sourceOvf \\\nvi://$vcUser:$vcPass\@$vcenter/"$dataCenter"/host/$cluster"$targetHost"};
	$deployCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	print "DEPLOY $deployCmd\n";
	system( $deployCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action ($vmName) : WARNING ($deployCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : COMPLETE} );

}

sub destroy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	my $vmName  = $options{'vmname'};
	my $vcenter = $options{'vcenter'};
	my $vcUser  = $options{'vcenteruser'};
	my $vcPass  = $options{'vcenterpassword'};

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'removevm'}{'path'};

	if ( !-x $ovftool ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO executable ($ovftool) FOUND for $distro $major.$minor $arch} );
		return;
	}

	#remove_vm.pl --vmname="02-11-02-01-200-01" --username=Administrator --password=<vcpasswd> --server=cae-qa-v1.sc.steeleye.com

	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : INITIATE} );
	my $destroyCmd = qq{$ovftool \\\n--vmname="$vmName" \\\n--username="$vcUser" \\\n--password="$vcPass" \\\n--server="$vcenter"};
	$destroyCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	#print "DESTROY $destroyCmd\n";
	system( $destroyCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action ($vmName) : WARNING ($destroyCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : COMPLETE} );

}

sub power ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	my $reqAction = $options{'action'};
	$action .= " ($reqAction)";

	my $vmName  = $options{'vmname'};
	my $vcenter = $options{'vcenter'};
	my $vcUser  = $options{'vcenteruser'};
	my $vcPass  = $options{'vcenterpassword'};

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'powerops'}{'path'};

	if ( !-x $ovftool ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO executable ($ovftool) FOUND for $distro $major.$minor $arch} );
		return;
	}

	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : INITIATE} );
	my $powerCmd = qq{$ovftool \\\n--operation="$reqAction" \\\n--vmname="$vmName" \\\n--username="$vcUser" \\\n--password="$vcPass" \\\n--server="$vcenter"};
	$powerCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	#print("POWER $powerCmd\n");
	system( $powerCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action ($vmName) : WARNING ($powerCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : COMPLETE} );

}

sub device ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	my $vmName       = $options{'vmname'};
	my $vcenter      = $options{'vcenter'};
	my $vcUser       = $options{'vcenteruser'};
	my $vcPass       = $options{'vcenterpassword'};
	my $vmDevice     = $options{'vmdevice'};
	my $isoDatastore = $options{'isodatastore'};
	my $isoPath      = $options{'isopath'};

	my $reqAction = $options{'action'};
	$action .= " ($reqAction :: $vmDevice)";

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $ovftool;

	if ( $vmDevice eq 'iso' ) {
		$ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'isomanage'}{'path'};
	} elsif ( $vmDevice eq 'net' or $vmDevice eq 'disk' ) {
		$ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'removabledevices'}{'path'};
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NOT IMPLEMENTED YET} );
		return;
	}

	if ( !-x $ovftool ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO executable ($ovftool) FOUND for $distro $major.$minor $arch} );
		return;
	}

	#vmISOManagement.pl --server=cae-qa-v1 --username=Administrator --password=<vcpasswd> --datastore=hancock-cdimages --filename=/filepile/cdimages/Linux/sles11-SP2-GMC/SLES-11-SP2-DVD-x86_64-GMC-DVD1.iso --operation=mount --vmname=DEPLOYOVFTEST

	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : INITIATE} );

	if ( $vmDevice eq 'iso' ) {

		my $operation;
		$operation = 'mount'   if ( $reqAction eq 'attach' );
		$operation = 'umount' if ( $reqAction eq 'detach' );

		my $deviceCmd = qq{$ovftool \\\n--operation="$operation" \\\n--vmname="$vmName" \\\n--datastore="$isoDatastore" \\\n--filename="$isoPath" \\\n--username="$vcUser" \\\n--password="$vcPass" \\\n--server="$vcenter"};
		$deviceCmd .= " $quietCmd" if ( $options{'quietrunning'} );
		system( $deviceCmd ) == 0 or ( Sys::Syslog::syslog( 'warning', qq{$action ($vmName) : WARNING ($deviceCmd) ($?:$!)} ) and return );
	}

	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : COMPLETE} );

}

sub snapshot ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};
	
	my $vmName              = $options{'vmname'};
	my $vcenter             = $options{'vcenter'};
	my $vcUser              = $options{'vcenteruser'};
	my $vcPass              = $options{'vcenterpassword'};
	my $snapshotName        = $options{'snapshotname'};
	my $snapshotDescription = $options{'snapshotdescription'};
 	my $snapshotMemory      = $options{'snapshotmemory'};
	my $snapshotQuiesce     = $options{'snapshotquiesce'};

	my $reqAction = $options{'action'};
	$action .= " ($reqAction)";

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}
	
	my $ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'snapshot'}{'path'};
	
	if ( !defined $snapshotName ) {
		$snapshotName = localtime;
	}

	if ( !defined $snapshotDescription ) {
		$snapshotDescription = 'FVORGE AUTOMATION';
	}	
	
	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : INITIATE} );
	my $snapshotCmd = qq{$ovftool \\\n--vmname="$vmName" \\\n--username="$vcUser" \\\n--password="$vcPass" \\\n--server="$vcenter" \\\n--snapshotname="$snapshotName" \\\n--snapshotdescription="$snapshotDescription"};
	if ( defined $snapshotMemory ) {
		$snapshotCmd .= qq{ \\\n--snapshotmemory};
	}
	if ( defined $snapshotQuiesce ) {
		$snapshotCmd .= qq{ \\\n--snapshotquiesce};
	}
	$snapshotCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	#print("SNAPSHOT $snapshotCmd\n");
	system( $snapshotCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action ($vmName) : WARNING ($snapshotCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action ($vmName) : COMPLETE} );

}

sub convertNames ( $$$$$$ ) {

	my $distribution = shift;
	my $major        = shift;
	my $minor        = shift;
	my $architecture = shift;
	my $group        = shift;
	my $instance     = shift;

	my $majNum;
	my $minNum;
	my $archNum;
	my $groupNum;
	my $instanceNum;

	my $vmName;

	my %ovfKeys;

	$majNum = $major;
	$majNum = '0' . $major if ( $major =~ /^\d$/ );

	$minNum = $minor;
	$minNum = '0' . $minor if ( $minor =~ /^\d$/ );

	$groupNum = $group;
	$groupNum = '00' . $group if ( $group =~ /^\d$/ );
	$groupNum = '0' . $group if ( $group =~ /^\d\d$/ );

	$instanceNum = $instance;
	$instanceNum = '0' . $instance if ( $instance =~ /^\d$/ );

	$vmName = $distribution . '-' . $majNum . '-' . $minNum . '-' . $architecture . '-' . $groupNum . '-' . $instanceNum;

	$ovfKeys{'vmname'}       = $vmName;
	$ovfKeys{'major'}        = $majNum;
	$ovfKeys{'minor'}        = $minNum;
	$ovfKeys{'group'}        = $groupNum;
	$ovfKeys{'instance'}     = $instanceNum;

	return %ovfKeys;

}

sub validateArguments( $$$$$$ ) {
	
	my $distribution = shift;
	my $major = shift;
	my $minor = shift;
	my $architecture = shift;
	my $group = shift;
	my $instance = shift;
	
	my $distroRegex      = $OVF::Vars::Common::sysVars{distrosRegex};
	my $archRegex        = $OVF::Vars::Common::sysVars{archsRegex};
	my $rhelVersionRegex = $OVF::Vars::Common::sysVars{rhelVersionsRegex};
	my $slesVersionRegex = $OVF::Vars::Common::sysVars{slesVersionsRegex};
	my $ubuntuVersionRegex = $OVF::Vars::Common::sysVars{ubuntuVersionsRegex};
	
	my @useError;
	
	if ( !defined $distribution or $distribution !~ /^($distroRegex)$/ ) {
		push( @useError, "--distribution $distroRegex required\n" );
	}

	if ( !defined $major or $major !~ /^\d+$/ ) {
		push( @useError, "--major # required\n" );
	}

	if ( !defined $minor or $minor !~ /^\d+$/ ) {
		push( @useError, "--minor # required\n" );
	}

	if ( !defined $architecture or $architecture !~ /^($archRegex)$/ ) {
		push( @useError, "--architecture $archRegex required\n" );
	}

	if ( !defined $group or $group !~ /^\d{1,3}$/ ) {
		push( @useError, "--group ### required\n" );
	}

	if ( !defined $instance or $instance !~ /^\d{1,2}$/ ) {
		push( @useError, "--instance ## required\n" );
	}

	my $version = '';
	if ( defined $major and defined $minor ) {
		$version = qq{$major.$minor};	
	}
	
	if ( defined $distribution ) {
		if ( $distribution eq 'SLES' and $version !~ /^($slesVersionRegex)$/ ) {
			push( @useError, "$distribution accepted versions $slesVersionRegex required\n" );
		}

		if ( $distribution eq 'RHEL' and $version !~ /^($rhelVersionRegex)$/ ) {
			push( @useError, "$distribution accepted versions $rhelVersionRegex required\n" );
		}

		if ( $distribution eq 'Ubuntu' and $version !~ /^($ubuntuVersionRegex)$/ ) {
			push( @useError, "$distribution accepted versions $ubuntuVersionRegex required\n" );
		}
	}

	return @useError;

}

1;

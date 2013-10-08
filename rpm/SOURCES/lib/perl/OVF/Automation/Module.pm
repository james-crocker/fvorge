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

	my $distNum = $options{'distNum'};
	my $majNum  = $options{'majNum'};
	my $minNum  = $options{'minNum'};
	my $archNum = $options{'archNum'};
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

	my $propPath = $options{'proppath'} if ( !exists $options{'proppath'} );

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $ovftool             = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'ovftool'}{'path'};
	my $ovfPropertyRootPath = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'ovf-properties-root'}{'path'};

	my @propertiesOverride;

	if ( !-x $ovftool ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO executable ($ovftool) FOUND for $distro $major.$minor $arch} );
		return;
	}

	my $distName        = $distNum . '-' . $majNum . '-' . $minNum . '-' . $archNum;
	my $ovfPropertyPath = $ovfPropertyRootPath . '/' . $distName . '/' . $grpNum . '/' . $instNum;
	my $vmFolder        = $distNum . '-' . $distro;

	if ( $options{'propoverride'} ) {
		if ( defined $propPath ) {

			if ( !-e $propPath ) {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO property file ($propPath) FOUND ($?:$!)} );
				return;
			}

		} else {

			if ( !-e $ovfPropertyPath ) {
				Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO property path ($ovfPropertyPath) FOUND ($?:$!)} );
				return;
			} else {
				tie @propertiesOverride, 'Tie::File', $ovfPropertyPath, autochomp => 0 or ( Sys::Syslog::syslog( 'err', qq{$action ::SKIP:: Couldn't open OVF Override Properties file [ $ovfPropertyPath ] ($?:$!)} ) and return );
			}
		}
	}

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my $deployCmd = qq{$ovftool --overwrite --powerOffTarget --name="$vmName" --vmFolder="$vmFolder" --datastore="$targetDatastore" --diskMode=$diskMode @propertiesOverride $sourceOvf vi://$vcUser:$vcPass\@$vcenter/"$dataCenter"/host/"$targetHost"};
	$deployCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	system( $deployCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($deployCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

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

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my $destroyCmd = qq{$ovftool --vmname="$vmName" --username="$vcUser" --password="$vcPass" --server="$vcenter"};
	$destroyCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	system( $destroyCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($destroyCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

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

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );
	my $powerCmd = qq{$ovftool --operation="$reqAction" --vmname="$vmName" --username="$vcUser" --password="$vcPass" --server="$vcenter"};
	$powerCmd .= " $quietCmd" if ( $options{'quietrunning'} );
	system( $powerCmd ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($powerCmd) ($?:$!)} );
	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

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

	Sys::Syslog::syslog( 'info', qq{$action : INITIATE} );

	if ( $vmDevice eq 'iso' ) {

		my $operation;
		$operation = 'mount'   if ( $reqAction eq 'attach' );
		$operation = 'umount' if ( $reqAction eq 'detach' );

#       Would like to query before attempting - but this script takes TO-LONG to execute. So, relying on retVal from the mount/umount
#		my $deviceCmd = qq{$ovftool --operation="queryiso" --vmname="$vmName" --datastore="$isoDatastore" --filename="$isoPath" --username="$vcUser" --password="$vcPass" --server="$vcenter"};
#		system( $deviceCmd ) == 0 or ( Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($deviceCmd) ($?:$!)} ) and return );

		my $deviceCmd = qq{$ovftool --operation="$operation" --vmname="$vmName" --datastore="$isoDatastore" --filename="$isoPath" --username="$vcUser" --password="$vcPass" --server="$vcenter"};
		$deviceCmd .= " $quietCmd" if ( $options{'quietrunning'} );
		system( $deviceCmd ) == 0 or ( Sys::Syslog::syslog( 'warning', qq{$action : WARNING ($deviceCmd) ($?:$!)} ) and return );
	}

	Sys::Syslog::syslog( 'info', qq{$action : COMPLETE} );

}

sub snapshot ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $arch   = $options{'architecture'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};

	my $reqAction = $options{'action'};
	$action .= " ($reqAction)";

	my $vmDevice = $options{'vmdevice'};

	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NOT IMPLEMENTED YET} );
	return;

}

sub convertNames ( $$$$$$ ) {

	my $distribution = shift;
	my $major        = shift;
	my $minor        = shift;
	my $architecture = shift;
	my $group        = shift;
	my $instance     = shift;

	my $distNum;
	my $majNum;
	my $minNum;
	my $archNum;
	my $groupNum;
	my $instanceNum;

	my $vmName;
	my $sourceOvf;

	my %ovfKeys;

	$distNum = $distribution;
	$distNum = '01' if ( $distribution eq 'RHEL' );
	$distNum = '02' if ( $distribution eq 'SLES' );
	$distNum = '03' if ( $distribution eq 'CentOS' );
	$distNum = '06' if ( $distribution eq 'ORAL' );

	$majNum = $major;
	$majNum = '0' . $major if ( $major =~ /^\d$/ );

	$minNum = $minor;
	$minNum = '0' . $minor if ( $minor =~ /^\d$/ );

	$archNum = $architecture;
	$archNum = '01' if ( $architecture eq 'x86_64' );
	$archNum = '02' if ( $architecture eq 'i686' );

	$groupNum = $group;
	$groupNum = '00' . $group if ( $group =~ /^\d$/ );
	$groupNum = '0' . $group if ( $group =~ /^\d\d$/ );

	$instanceNum = $instance;
	$instanceNum = '0' . $instance if ( $instance =~ /^\d$/ );

	$vmName = $distNum . '-' . $majNum . '-' . $minNum . '-' . $archNum . '-' . $groupNum . '-' . $instanceNum;

	$sourceOvf = $distNum . '-' . $majNum . '-' . $minNum . '-' . $archNum . $OVF::Automation::Vars::sourceOvfSuffix;
	$sourceOvf = $sourceOvf . '/' . $sourceOvf . '.ovf';

	$ovfKeys{'vmname'}       = $vmName;
	$ovfKeys{'distribution'} = $distNum;
	$ovfKeys{'architecture'} = $archNum;
	$ovfKeys{'major'}        = $majNum;
	$ovfKeys{'minor'}        = $minNum;
	$ovfKeys{'group'}        = $groupNum;
	$ovfKeys{'instance'}     = $instanceNum;
	$ovfKeys{'sourceovf'}    = $sourceOvf;

	return %ovfKeys;

}

1;

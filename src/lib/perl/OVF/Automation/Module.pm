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

# Make bundled VMware packages LAST for unit tests; but not overriding system libs.
BEGIN { push ( @INC, ( '/opt/fvorge/lib/perl', '../../../../lib/perl' ) );
	# To allow https connections with unverified SSL certs.
	# From VMware: https://communities.vmware.com/message/2444510
	$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use strict;
#use warnings;

use Tie::File;
use Fcntl 'O_RDONLY';

use lib '../../../perl';
use OVF::Automation::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

# All important vCLI
# fvorge-minions.deb includes vCLI and ovftool from VMware
use VMware::VIRuntime;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd   = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub deploy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my @useError;
	my $ovftool;

	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};
	my $arch   = $options{'architecture'};

	my $targetHost      = $options{'targethost'};
	my $targetDatastore = $options{'targetdatastore'};
	my $diskMode        = $options{'diskmode'};
	my $vmName          = $options{'vmname'};
	my $sourceOvf       = $options{'sourceovf'};
	my $vcenter         = $options{'vcenter'};
	my $vcUser          = $options{'vcenteruser'};
	my $vcPass          = $options{'vcenterpassword'};
	my $dataCenter      = $options{'datacenter'};
	my $vmFolder        = $options{'folder'};
	my $cluster         = $options{'cluster'};
	my $net             = $options{'net'};
	my $overwrite       = $options{'overwrite'};
	my $propoverride    = $options{'propoverride'};
	
	# Validate correct set of arguments for this action.
	push ( @useError, validateVcenterArguments( \%options ) );
	push ( @useError, validateVmName( \$vmName, \%options ) );	
	
	if ( !defined $sourceOvf ) {
		push( @useError, "--sourceovf required\n" );
	}

	if ( !defined $targetHost ) {
		push( @useError, "--targethost required\n" );
	}

	if ( !defined $targetDatastore ) {
		push( @useError, "--targetdatastore required\n" );
	}

	if ( !defined $dataCenter ) {
		push( @useError, "--datacenter required\n" );
	}
	
	# TODO: validate targethost, targetdatastore, datacenter, (cluster if provided)
	# through validate functions before continuing. The ovftool outputs error if
	# locator doesn't refer to an object - but parsing it is a bother.
	
	handleUseError( \@useError );

	# Don't depend on distribution arguments; unless available
	if ( !defined $distro or !defined $major or !defined $minor or !defined $arch ) {
		$ovftool = $OVF::Automation::Vars::defaultOvftoolPath;
	} else {
		$ovftool = $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{'bin'}{'ovftool'}{'path'};
	}
	
	if ( !defined $ovftool or !-x $ovftool ) {
		my $ovftool = 'ovftool' if ( !defined $ovftool );
		logMessage( $action, undef, 'err', 'skip', qq{NO executable ($ovftool) FOUND} );
		return;
	}
	
	# Get any OVF properties override values for the given sourceOvf.
	my @filePropertiesOverride;
	my @propertiesOverride;
	if ( defined $propoverride ) {
		if ( -e $propoverride ) {
			tie @filePropertiesOverride, 'Tie::File', $propoverride, autochomp => 0, mode => O_RDONLY or ( logMessage( $action, undef, 'err', 'skip', qq{Couldn't open OVF Override Properties file [ $propoverride ] ($?:$!)} ) and return );
		} else {
			logMessage( $action, undef, 'err', 'skip', qq{NO property path ($propoverride) FOUND ($?:$!)} );
			return;			
		}
		# Append/Prepend OVF properties for ovftool format
		foreach my $ovfProperty ( @filePropertiesOverride ) {
			# Account for legacy file that already was defined as --prop:(...) \ - add them otherwise
			# Skip blank or '#' commented lines.
			if ( $ovfProperty !~ /^\s+$/ or $ovfProperty !~ /^\s*#/ ) {
				if ( $ovfProperty !~ /^--prop:/ ) {
					$ovfProperty = qq{--prop:$ovfProperty};
				}
				if ( $ovfProperty !~ /\s+\\$/ ) {
					$ovfProperty .= q{ \\};
				}
				push( @propertiesOverride, $ovfProperty );
			}
		}
	}

	logMessage( $action, $vmName, 'info', undef, qq{BEGIN} );
	
	# Create the OVFTOOL deploy cmd
	my $deployCmd = qq{$ovftool --acceptAllEulas}; #Accept ALL Eulas by default.
	
	$deployCmd .= qq{ \\\n--name="$vmName"};
	
	# To overwrite existing vm. Need option for this. Default to *not* overwrite existing vm.
	if ( defined $overwrite ) {
		$deployCmd .= qq{ \\\n--overwrite \\\n--powerOffTarget};	
	}
	
	# If to enumerate in a vCenter 'folder' - NOTE! vmFolder MUST EXIST PRIOR TO DEPLOYMENT - IT WILL NOT BE CREATED
	if ( defined $vmFolder ) {
		$deployCmd .= qq{ \\\n--vmFolder="$vmFolder"};
	}
	
	# If a multiple networks; and given a specific net to attach.
	if ( defined $net ) {
		foreach my $sourceTarget ( split( /\s*;\s*/, $net ) ) {
			my ( $source, $target ) = split( /\s*=\s*/, $sourceTarget );
			$deployCmd .= qq{ \\\n--net:"$source"="$target"};
		}
	}
	
	# If in a cluster set it for inclusion in the url.
	if ( defined $cluster ) {
		$cluster = qq{"$cluster"/};
	} else {
		$cluster = '';
	}
	
	# Diskmode - default THIN
	if ( !defined $diskMode ) {
		$diskMode = 'thin';
	}
	
	$deployCmd .= qq{ \\\n--datastore="$targetDatastore"};
	$deployCmd .= qq{ \\\n--diskMode=$diskMode};
	if ( scalar @propertiesOverride > 0 ) {
		$deployCmd .= qq{ \\\n@propertiesOverride};
	}
	$deployCmd .= qq{ \\\n} if ( scalar @propertiesOverride <= 0 );
	$deployCmd .= $sourceOvf;
	$deployCmd .= qq{ \\\nvi://"$vcUser":"$vcPass"\@"$vcenter"/"$dataCenter"/host/$cluster"$targetHost"};
	$deployCmd .= qq{ $quietCmd} if ( !$options{'verbose'} );
	print qq{DEPLOY COMMAND:\n$deployCmd\n} if ( $options{'verbose'} );
	if ( system( $deployCmd ) == 0 ) {
		logMessage( $action, $vmName, 'info', 'success', undef );
	} else {
		logMessage( $action, $vmName, 'err', 'error', qq{($deployCmd) ($?:$!)} );
	}
	logMessage( $action, $vmName, 'info', undef, qq{END} );

}

sub destroy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my @useError;

	my $vmName  = $options{'vmname'};
	my $vcenter = $options{'vcenter'};
	my $vcUser  = $options{'vcenteruser'};
	my $vcPass  = $options{'vcenterpassword'};
		
	# Validate correct set of arguments for this action.
	push ( @useError, validateVcenterArguments( \%options ) );
	push ( @useError, validateVmName( \$vmName, \%options ) );
	
	handleUseError( \@useError );

	logMessage( $action, $vmName, 'info', undef, qq{BEGIN} );
	Util::connect( getVIRuntimeUrl( \%options ), $vcUser, $vcPass );
	my $vm = Vim::find_entity_view(view_type => 'VirtualMachine', filter =>{ 'name' => $vmName});
	if ( !defined $vm ) {
		logMessage( $action, $vmName, 'err', 'error', qq{UNABLE TO LOCATE VM ($vmName) AT VCENTER ($vcenter)} );
	} else {		
		my $task_ref = $vm->Destroy_Task();
		logMessage( $action, $vmName, getVIRuntimeTaskStatus($task_ref) );
	}
	Util::disconnect();
	logMessage( $action, $vmName, 'info', undef, qq{END} );

}

sub power ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my @useError;

	my $op = $options{'action'};
	$action .= " ($op)";

	my $vmName  = $options{'vmname'};
	my $vcenter = $options{'vcenter'};
	my $vcUser  = $options{'vcenteruser'};
	my $vcPass  = $options{'vcenterpassword'};

	# Validate correct set of arguments for this action.
	my $powerRegex = $OVF::Automation::Vars::powerRegex;
	if ( $op !~ /^($powerRegex)$/ ) {
		push ( @useError, '--action=$powerRegex required; got $op')
	}
	push ( @useError, validateVcenterArguments( \%options ) );
	push ( @useError, validateVmName( \$vmName, \%options ) );
	
	handleUseError( \@useError );
	
	logMessage( $action, $vmName, 'info', undef, qq{BEGIN} );
	Util::connect( getVIRuntimeUrl( \%options ), $vcUser, $vcPass );
	my $vm = Vim::find_entity_view(view_type => 'VirtualMachine', filter =>{ 'config.name' => $vmName});
	if ( !defined $vm ) {
		logMessage( $action, $vmName, 'warning', 'warning', qq{UNABLE TO LOCATE VM ($vmName) AT VCENTER ($vcenter)} );
	} else {		
		my $state = $vm->runtime->powerState->val;
		# power on
		if ( $op eq $OVF::Automation::Vars::powerOnName ) {
			if ( $state ne 'poweredOff' && $state ne 'suspended' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->PowerOnVM();
			}
		}
		# reset
		elsif ( $op eq $OVF::Automation::Vars::resetName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->ResetVM();
			}
		}
		# standby
		elsif ( $op eq $OVF::Automation::Vars::standbyName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->StandbyGuest();
			}
		}
		# power off
		elsif ( $op eq $OVF::Automation::Vars::powerOffName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->PowerOffVM();
			}
		}
		# suspend
		elsif ( $op eq $OVF::Automation::Vars::suspendName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->SuspendVM();
			}
		}
		# shutdown
		elsif ( $op eq $OVF::Automation::Vars::shutdownName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->ShutdownGuest();
			}
		}
		# reboot
		elsif ( $op eq $OVF::Automation::Vars::rebootName ) {
			if ( $state ne 'poweredOn' ) {
				logMessage( $action, $vmName, 'warning', 'warning', qq{OPERATION NOT SUPPORTED FOR CURRENT STATE ($state)} );
			} else {
				$vm->RebootGuest();
			}
		}
	}
	logMessage( $action, $vmName, 'info', 'success', undef );
	Util::disconnect();
	logMessage( $action, $vmName, 'info', undef, qq{END} );

}

sub device ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $vmName       = $options{'vmname'};
	my $vcenter      = $options{'vcenter'};
	my $vcUser       = $options{'vcenteruser'};
	my $vcPass       = $options{'vcenterpassword'};
	my $vmDevice     = $options{'vmdevice'};
	my $vmDeviceName = $options{'vmdevicename'};
	my $isoDatastore = $options{'isodatastore'};
	my $isoPath      = $options{'isopath'};
	my $operation    = $options{'action'};
	
	my @useError;
	my $attach = 0;
	my $detach = 0;
	my $list   = 0;

	my $attachName    =  $OVF::Automation::Vars::deviceAttachName;
	my $detachName    =  $OVF::Automation::Vars::deviceDetachName;
	my $listName    =  $OVF::Automation::Vars::deviceListName;
	my $vmDeviceRegex = $OVF::Automation::Vars::vmDeviceRegex;
	
	# Validate correct set of arguments for this action.
	my $deviceRegex = $OVF::Automation::Vars::deviceRegex;
	if ( $operation !~ /^($deviceRegex)$/ ) {
		push ( @useError, '--action=$deviceRegex required; got $operation')
	} else {
		if ( $operation eq $attachName ) {
			$attach = 1;
		} elsif ( $operation eq $detachName ) {
			$detach = 1;
		} elsif ( $operation eq $listName ) {
			$list   = 1;
		}
	}
	push ( @useError, validateVcenterArguments( \%options ) );
	push ( @useError, validateVmName( \$vmName, \%options ) );
		
	if ( !defined $vmDevice or $vmDevice !~ /^($vmDeviceRegex)$/ ) {
		push( @useError, "--vmdevice $vmDeviceRegex required\n" );
	}

	if ( $attach and defined $vmDevice and $vmDevice eq $OVF::Automation::Vars::vmDeviceIsoName ) {
		if ( !defined $isoDatastore ) {
			push( @useError, "--isodatastore required\n" );
		}
		if ( !defined $isoPath ) {
			push( @useError, "--isopath required\n" );
		}
	}
	
	if ( defined $vmDevice and $vmDevice ne $OVF::Automation::Vars::vmDeviceIsoName ) {
		if ( !defined $vmDeviceName and $operation ne $listName ) {
			# Device name not needed for 'listing' opertations.
			push( @useError, "--vmdevicename required\n" );
		}
	}
	
	handleUseError( \@useError );
	
	my $devDetail = '';
	
	if ( $vmDevice eq $OVF::Automation::Vars::vmDeviceIsoName ) {
		$devDetail = qq{:[$isoDatastore] $isoPath};
	} else {
		$devDetail = qq{:$vmDeviceName} if ( $vmDeviceName );
	}
	
	$action .= " ($operation:$vmDevice$devDetail)";

	logMessage( $action, $vmName, 'info', undef, qq{BEGIN} );
	Util::connect( getVIRuntimeUrl( \%options ), $vcUser, $vcPass );
	my $vm = Vim::find_entity_view(view_type => 'VirtualMachine', filter =>{ 'name' => $vmName});
	if ( !defined $vm ) {
		logMessage( $action, $vmName, 'err', 'error', qq{UNABLE TO LOCATE VM ($vmName) AT VCENTER ($vcenter)} );
	} else {
		if ( $list ) {
			if ( $vmDevice eq $OVF::Automation::Vars::vmDeviceIsoName ) {
				findDatastoreFile( $vm, undef, '*.iso', 1 );
			} else {
				my $deviceList = $vm->config->hardware->device;
				my $deviceFound = 0;
				foreach my $device ( @$deviceList ) {
					my $printDevice = 0;
					if ( defined $device->{deviceInfo} and defined $device->{connectable} ) {
						if ( !defined $vmDeviceName or $vmDeviceName eq $device->deviceInfo->label ) {
							$printDevice = 1;
							$deviceFound = 1;
						}
						printf( "%-40.40s %-s\n", $device->deviceInfo->label, $device->connectable->connected ? 'true' : 'false' ) if ( $printDevice );
					}
				}
				logMessage( $action, $vmName, 'warning', 'warning', qq{NO DEVICE LABELED ($vmDeviceName) FOUND} ) if ( defined $vmDeviceName and !$deviceFound );
			}
		} else {
			# For ISO attach/detach
			if ( $vmDevice eq $OVF::Automation::Vars::vmDeviceIsoName ) {
				if ( $attach ) {
					foreach my $msg ( cdromIsoMount( $vm, $isoDatastore, $isoPath ) ) {
						logMessage( $action, $vmName, $msg->[0], $msg->[1], $msg->[2] );
					}
				} elsif ( $detach ) {
					foreach my $msg ( cdromIsoUmount( $vm ) ) {
						logMessage( $action, $vmName, $msg->[0], $msg->[1], $msg->[2] );
					}
				}
			} else {
				# For any other device type
				my $connect;
				$connect = 1 if ( $attach );
				$connect = 0 if ( $detach );
				my $deviceMatched = 0;
				my $deviceListRef = $vm->config->hardware->device;
				foreach my $device ( @$deviceListRef ) {
					if (defined $device->{deviceInfo} && $device->deviceInfo->label eq $vmDeviceName) {
						connectDevice( $action, $vmName, $vm, $device, $connect );
						$deviceMatched = 1;
						last;
					}
				}
				logMessage( $action, $vmName, 'warning', 'warning', qq{NO DEVICE LABELED ($vmDeviceName) FOUND} ) if ( !$deviceMatched );
			}
		}
	}
	Util::disconnect();
	logMessage( $action, $vmName, 'info', 'success', undef ); # Success if this far without throwing warning or error.
	logMessage( $action, $vmName, 'info', undef, qq{END} );

}

sub snapshot ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my $vmName              = $options{'vmname'};
	my $vcenter             = $options{'vcenter'};
	my $vcUser              = $options{'vcenteruser'};
	my $vcPass              = $options{'vcenterpassword'};
	my $snapshotName        = $options{'snapshotname'};
	my $snapshotDescription = $options{'snapshotdescription'};
 	my $snapshotMemory      = $options{'snapshotmemory'};
	my $snapshotQuiesce     = $options{'snapshotquiesce'};
	
	my $operation           = $options{'action'};

	my $revertRecent        = 0;
	my $revertToName        = 0;
	my $destroyByName       = 0;
	my $destroyAll          = 0;
	
	my @useError;
	
	my $snapshotRevertName = $OVF::Automation::Vars::snapshotRevertName;
	my $snapshotDestroyName = $OVF::Automation::Vars::snapshotDestroyName;
		
	# Validate correct set of arguments for this action.
	my $snapshotRegex       = $OVF::Automation::Vars::snapshotRegex;
	if ( $operation !~ /^($snapshotRegex)$/ ) {
		push ( @useError, '--action=$snapshotRegex required; got $operation');
	}
	push ( @useError, validateVcenterArguments( \%options ) );
	push ( @useError, validateVmName( \$vmName, \%options ) );
	handleUseError( \@useError );
		
	if ( $operation eq $snapshotRevertName ) {
		my $snapTo;
		if ( defined $snapshotName ) {
			$snapTo = $snapshotName;
			$revertToName = 1;
		} else {
			$snapTo = 'recent';
			$revertRecent = 1;
		}
		$action .= qq{ (revert:$snapTo)};
	}
	
	if ( $operation eq $snapshotDestroyName ) {
		my $destroyTo;
		if ( defined $snapshotName ) {
			$destroyTo = $snapshotName;
			$destroyByName = 1;
		} else {
			$destroyTo = 'all';
			$destroyAll = 1;			
		}
		$action .= qq{ (destroy:$destroyTo)};
	}
	
	# Default FALSE if not defined
	if ( !defined $snapshotMemory ) {
		$snapshotMemory = 0;
	}

	# Default FALSE if not defined
	if ( !defined $snapshotQuiesce ) {
		$snapshotQuiesce = 0;
	}
	
	# Default to localtime stamp if not name not provided
	if ( !defined $snapshotName ) {
		$snapshotName = localtime;
	}
	
	# Default to default description if none provided
	if ( !defined $snapshotDescription ) {
		if ( defined $OVF::Automation::Vars::defaultSnapshotDescription ) {
			$snapshotDescription = $OVF::Automation::Vars::defaultSnapshotDescription;
		} else {
			$snapshotDescription = '';
		}
	}
   
   	my $snapshotCreateName = $OVF::Automation::Vars::snapshotCreateName;	
	if ( $operation eq $snapshotCreateName ) {
		$action .= qq{ (create:$snapshotName)};
	}
	
	logMessage( $action, $vmName, 'info', undef, qq{BEGIN} );
	Util::connect( getVIRuntimeUrl( \%options ), $vcUser, $vcPass );
	my $vm = Vim::find_entity_view(view_type => 'VirtualMachine', filter =>{ 'config.name' => $vmName});
	if ( !defined $vm ) {
		logMessage( $action, $vmName, 'err', 'error', qq{UNABLE TO LOCATE VM ($vmName) AT VCENTER ($vcenter)} );
	} else {
		my ( $snapshotOk, $snapshotRef );
		if ( $revertRecent ) {
			( $snapshotOk, $snapshotRef ) = validateSnapshot( $action, $vmName, $vm, undef );
			if ( $snapshotOk ) {
				eval {
					$vm->RevertToCurrentSnapshot();
				};
				logMessage( $action, $vmName, getVIRuntimeEvalStatus( $@ ) );
			}
		} elsif ( $revertToName ) {
			( $snapshotOk, $snapshotRef ) = validateSnapshot( $action, $vmName, $vm, $snapshotName );
			if ( $snapshotOk and defined $snapshotRef ) {
				eval {
					$snapshotRef->RevertToSnapshot();
				};
				logMessage( $action, $vmName, getVIRuntimeEvalStatus( $@ ) );
			}
		} elsif ( $destroyByName ) {
			( $snapshotOk, $snapshotRef ) = validateSnapshot( $action, $vmName, $vm, $snapshotName );
			if ( $snapshotOk and defined $snapshotRef ) {
				# May want a GetOpt switch for removeChildren; but for now
				# destroy children too.
				eval {
					$snapshotRef->RemoveSnapshot( removeChildren => 1 );
				};
				logMessage( $action, $vmName, getVIRuntimeEvalStatus( $@ ) );
			}
		} elsif ( $destroyAll ) {
			( $snapshotOk, $snapshotRef ) = validateSnapshot( $action, $vmName, $vm, undef );
			if ( $snapshotOk ) {
				eval {
					$vm->RemoveAllSnapshots();
				};
				logMessage( $action, $vmName, getVIRuntimeEvalStatus( $@ ) );
			}
		} else {
			eval {
				$vm->CreateSnapshot(name => $snapshotName,
									description => $snapshotDescription,
									memory => $snapshotMemory,
									quiesce => $snapshotQuiesce);
			};
			logMessage( $action, $vmName, getVIRuntimeEvalStatus( $@ ) );
		}
	}
	Util::disconnect();
	logMessage( $action, $vmName, 'info', undef, qq{END} );
	
}

sub validateSnapshot ( $$$$ ) {
	
	my $action       = shift;
	my $actionDetail = shift;
	my $vm           = shift;
	my $snapshotName = shift;
	
	my $snapshotOk = 1;
	my $snapshot;
	
	if ( defined $vm->snapshot ) {
		if ( defined $snapshotName ) {
			my ( $snapshotRef, $nRefs ) = findSnapshotName( $vm->snapshot->rootSnapshotList, $snapshotName );
			if ( defined $snapshotRef ) {
				if ( $nRefs > 1 ) {
					logMessage( $action, $actionDetail, 'err', 'error', qq{($nRefs) SNAPSHOTS WITH THE SAME NAME ($snapshotName)} );
					$snapshotOk = 0;
				} else {
					$snapshot = Vim::get_view (mo_ref =>$snapshotRef->snapshot);
				}
			} else {
				logMessage( $action, $actionDetail, 'err', 'error', qq{SNAPSHOT ($snapshotName) NOT FOUND} );
				$snapshotOk = 0;
			}
		}
	} else {
		logMessage( $action, $actionDetail, 'warning', 'warning', qq{VIRTUAL MACHINE HAS *NO* SNAPSHOTS} );
		$snapshotOk = 0;
	}
	
	return $snapshotOk, $snapshot;

}

sub findSnapshotName ( $$ ) {
	
	my $tree  = shift;
	my $name  = shift;
	my $ref   = undef;
	my $count = 0;

	foreach my $node ( @$tree ) {
		if ( $node->name eq $name ) {
			$ref = $node;
			$count++;
		}
		my ( $subRef, $subCount ) = findSnapshotName( $node->childSnapshotList, $name );
		$count = $count + $subCount;
		$ref = $subRef if ( $subCount );
	}

	return ( $ref, $count );

}

sub getVIRuntimeUrl ( \% ) {
	
	my ( %options ) = %{ ( shift ) };
	
	# May want to accept these from command line options at some point.
	# Till then, can assume the defaults.
	
	my $protocol = 'https';
	my $server   = $options{'vcenter'};
	my $port     = '443';
	my $path     = '/sdk/webService';
		
	$port = defined($port) ? qq{:$port} : '';
	
	return qq{$protocol://$server$port$path};	
	
}

sub cdromIsoUmount ( $ ) {
	
	my $vm = shift;
	
	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my @msg;
	
	my $cdromDevice = findCdromDevice( $vm );
	
	unless( $cdromDevice ) {
		push( @msg, [ 'err', qq{STATUS (error) : UNABLE TO FIND CDROM DEVICE} ] );
	}
	
	return @msg if (  @msg );
	
	# !! MAY CAUSE WARNING ON CDROM LOCK IN VCENTER GUI IF HOST POWERED ON AND
	# GUEST AUTOMATICALLY LOCKS THE DEVICE.
		
	my $cdromBackingInfo = VirtualCdromRemoteAtapiBackingInfo->new( deviceName => '' );
	my $devConInfo = VirtualDeviceConnectInfo->new( startConnected => 'false', connected => 'false', allowGuestControl => 'false' );
	my $cdrom = VirtualCdrom->new( backing => $cdromBackingInfo, connectable => $devConInfo, controllerKey => $cdromDevice->controllerKey, key => $cdromDevice->key, unitNumber => $cdromDevice->unitNumber );
	my $devspec = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new('edit'), device => $cdrom );
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
	
	eval {
		my $taskRef = $vm->ReconfigVM_Task( spec => $vmspec );
		push( @msg, [ getVIRuntimeTaskStatus( $taskRef ) ] );
	};
	push ( @msg, [ getVIRuntimeEvalStatus( $@ ) ] );
	
	return @msg;
	
}

sub cdromIsoMount ( $$$ ) {
	
	my $vm      = shift;
	my $dsName  = shift;
	my $isoPath = shift;
	
	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my @msg;
	
	my $cdromDevice  = findCdromDevice( $vm );
	my $ds           = findDatastore( $vm, $dsName );
	
	unless( $ds ) {
		push( @msg, [ 'err', 'error', qq{UNABLE TO LOCATE DATASTORE ($dsName)} ] );
	}
	
	unless( $cdromDevice ) {
		push( @msg, [ 'err', 'error', qq{UNABLE TO FIND CDROM DEVICE ($cdromDevice)} ] );
	}
	
	unless( findDatastoreFile( $vm, $ds, $isoPath, 0 ) ) {
		push( @msg, [ 'err', 'error', qq{UNABLE TO FIND FILE ($isoPath) IN DATASTORE ($dsName)} ]);
	}
	
	return @msg if ( @msg );
	
	# !! MAY CAUSE WARNING ON CDROM LOCK IN VCENTER GUI IF HOST POWERED ON AND
	# GUEST AUTOMATICALLY LOCKS THE DEVICE.
	
	my $dsIsoPath = qq{[$dsName] $isoPath};
	
	my $cdromBackingInfo = VirtualCdromIsoBackingInfo->new( datastore => $ds, fileName => $dsIsoPath );
	my $devConInfo = VirtualDeviceConnectInfo->new( startConnected => 'true', connected => 'true', allowGuestControl => 'false' );
	my $cdrom = VirtualCdrom->new( backing => $cdromBackingInfo, connectable => $devConInfo, controllerKey => $cdromDevice->controllerKey, key => $cdromDevice->key, unitNumber => $cdromDevice->unitNumber );
	my $devspec = VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new('edit'), device => $cdrom );
	my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
	
	eval {
		my $taskRef = $vm->ReconfigVM_Task( spec => $vmspec );
		push( @msg, [ getVIRuntimeTaskStatus( $taskRef ) ] );
	};
	push ( @msg, [ getVIRuntimeEvalStatus( $@ ) ] );
	
	return @msg;
	
}

sub findDatastore ( $$ ) {
	
	my $vm = shift;
	my $dsName = shift;

	my $host = Vim::get_view( mo_ref => $vm->runtime->host );
	my $datastores =  Vim::get_views( mo_ref_array => $host->datastore );
	foreach ( @$datastores ) {
		if ( $_->summary->name eq $dsName ) {
			return $_;
		}
	}
	
	return undef
	
}

sub findCdromDevice ( $ ) {
	
	my $vm = shift;

	my $devices = $vm->config->hardware->device;
	foreach my $device ( @$devices ) {
		if ( $device->isa( 'VirtualCdrom' ) ) {
			return $device;
		}
	}
	
	return undef;
	
}

sub findDatastoreFile ( $$$$ ){
	
	my $vm            = shift;
	my $dataStore     = shift;
	my $filterPattern = shift;
	my $list          = shift;
	
	my $found = 0;
	my $host;
	my $datastores;
	my $pathMatch;
	my $fileMatch;
	
	# If filterPattern has directory info - then be sure to match by that also.
	# The matchPattern is for FILENAME matching; not full path.
	if ( defined $filterPattern and $filterPattern =~ /([^\/]+\/)([^\/]+)$/ ) {
		$pathMatch = $` . $1;
		$fileMatch = $2;
		$filterPattern = '*';
	}
	
	if ( !defined $dataStore or !defined $dataStore->summary ) {
		$host = Vim::get_view( mo_ref => $vm->runtime->host );
		$datastores =  Vim::get_views( mo_ref_array => $host->datastore );
	} else {
		# Make ref to match return from Vim::get_views above.
		my @dsArray = ( $dataStore );
		$datastores = \@dsArray;
	}
	
	foreach my $ds ( @$datastores ) {
		my $browser = Vim::get_view ( mo_ref => $ds->browser );
		my $dsPath = '[' . $ds->info->name . ']';
		my $fileQuery = FileQueryFlags->new(fileOwner => 0, fileSize => 0, fileType => 0, modification => 0);
		my $searchSpec = HostDatastoreBrowserSearchSpec->new(details => $fileQuery, matchPattern => [$filterPattern]);
		my $searchRes = $browser->SearchDatastoreSubFolders(datastorePath => $dsPath, searchSpec => $searchSpec);
		foreach my $result (@$searchRes) {
			my $files = $result->file;
			foreach my $file (@$files) {
				print $result->folderPath . $file->path . "\n" if ( $list );
				if ( defined $pathMatch and defined $fileMatch ) {
					if ( $result->folderPath eq qq{$dsPath $pathMatch} and $file->path eq $fileMatch ) {
						$found = 1;
					}
				} else {
					# Must have been a FILE only pattern - and if here it was found.
					$found = 1;
				}
			}
		}		
	}
	
	return $found;
	
}

sub connectDevice ( $$$$$ ) {
	
	my $action       = shift;
	my $actionDetail = shift;
	my $vm           = shift;
	my $device       = shift;
	my $connect      = shift;
	
	my $thisSubName = ( caller( 0 ) )[ 3 ];

	$action = $thisSubName if ( !defined $action );
	if ( !defined $actionDetail ) {
		$actionDetail = 'true' if ( $connect == 1 );
		$actionDetail = 'false' if ( $connect == 0 );
	}
	
	if ( defined $device and defined $connect ) {
		$device->connectable->connected($connect);
		my $spec = VirtualMachineConfigSpec->new( changeVersion => $vm->config->changeVersion, deviceChange => [
						VirtualDeviceConfigSpec->new( operation => VirtualDeviceConfigSpecOperation->new('edit'), device => $device )
					] );
		eval {
			$vm->ReconfigVM(spec => $spec);
		};
		logMessage( $action, $actionDetail, getVIRuntimeEvalStatus( $@ ) );
	}
	
}

sub getVIRuntimeEvalStatus ( $ ) {
	
	my $statusRef = shift;
	
	my ( $priority, $status, $msg ) = ( 'info', 'success', undef );
	
	if ( $statusRef ) {
		if ( ref( $statusRef ) eq 'SoapFault' ) {
			if ( ref( $statusRef->detail ) eq 'InvalidName' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{NAME IS INVALID} );
			} elsif ( ref( $statusRef->detail ) eq 'InvalidState' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{CANNOT BE PERFORMED IN CURRENT STATE OF VIRTUAL MACHINE} );
			} elsif ( ref( $statusRef->detail ) eq 'NotSupported' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{NOT SUPPORTED} );
			} elsif ( ref( $statusRef->detail ) eq 'InvalidPowerState' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{INVALID POWER STATE} );
			} elsif ( ref( $statusRef->detail ) eq 'InsufficientResourcesFault' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{INSUFFICIENT RESOURCES} );
			} elsif ( ref( $statusRef->detail ) eq 'HostNotConnected' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{HOST NOT CONNECTED} );
			} elsif ( ref( $statusRef->detail ) eq 'NotFound' ) {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{NOT FOUND} );
			} elsif ( ref( $statusRef->detail ) eq 'InvalidDatastorePath' ){
				( $priority, $status, $msg ) = ( 'err', 'soapFault', q{INVALID DATASTORE PATH} );
			} else {
				( $priority, $status, $msg ) = ( 'err', 'soapFault', $statusRef->detail );
			}
		} else {
           ( $priority, $status, $msg ) = ( 'err', 'error', $statusRef );
        }
	}

	return ( $priority, $status, $msg );
	
}

sub getVIRuntimeTaskStatus ( $ ) {
	
	my $taskRef = shift;
	
	# Wait for a result for 25 seconds or return unknown
	my $taskView        = Vim::get_view(mo_ref => $taskRef);
	my $taskinfo         = $taskView->info->state->val;
	my $continue         = 0;
	my $continueMax      = 5;
	my $sleepTimeSec     = 5;
	my $waitTimeSec      = $continueMax * $sleepTimeSec;
	my ( $priority, $status, $msg ) = ( 'info', 'unknown', qq{EXCEEDED $waitTimeSec SECOND WAIT TIME} );
		
	while ( $continue <= $continueMax ) { # Wait X seconds ($continue x sleep)
		my $info = $taskView->info;
		if ( $info->state->val eq 'success' ) {
			( $priority, $status, $msg ) = ( 'info', 'success', $info->result );
		} elsif ( $info->state->val eq 'error' ) {
			my $soapFault = SoapFault->new;
			#my $faultName = $soapFault->name( $info->error->fault );
			#my $faultDetail = $soapFault->detail( $info->error->fault );
			$soapFault->fault_string( $info->error->localizedMessage );
			( $priority, $status, $msg ) = ( 'err', 'error', $info->error->fault );
		}
		sleep $sleepTimeSec;
		$taskView->ViewBase::update_view_data();
		$continue++;
	}
		
	return ( $priority, $status, $msg );
	
}

sub convertNames ( \% ) {

	my ( %options ) = %{ ( shift ) };
	
	my @useError;
	push ( @useError, validateDistributionArguments( \%options ) );
	return ( \@useError, undef ) if ( @useError );
	# No sense completing if useError here since
	# derivation relies on correct distribution arguments. 

	my $architecture   = $options{'architecture'};
	my $distribution   = $options{'distribution'};
	my $major          = $options{'major'};
	my $minor          = $options{'minor'};
	my $group          = $options{'group'};
	my $instance       = $options{'instance'};

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

	$vmName = $distribution . '-' . $majNum . '.' . $minNum . '-' . $architecture . '-' . $groupNum . '-' . $instanceNum;

	$ovfKeys{'vmname'}       = $vmName;
	$ovfKeys{'major'}        = $majNum;
	$ovfKeys{'minor'}        = $minNum;
	$ovfKeys{'group'}        = $groupNum;
	$ovfKeys{'instance'}     = $instanceNum;

	return ( \@useError, \%ovfKeys);

}

sub validateVmName ( \$\% ) {
	
	my ( $vmNameRef )  = shift;
	my ( %options )    = %{ ( shift ) };
	
	my @useError;
	my $useErrorRef;
	my $vmName;
	
	# If vmName is undefined AND can be derived the referenced vmName will
	# be changed.
	if ( !defined ${ $vmNameRef } or ${ $vmNameRef } =~ /^\s*$/ ) {
		( $useErrorRef, $vmName ) = getDerivedVmName( \%options );
		push ( @useError, @{ $useErrorRef } ) if ( $useErrorRef );
		if ( !defined $vmName ) {
			push ( @useError, "--vmname required if distribution arguments not provided\n");
		}
		${ $vmNameRef } = $vmName;
	}
	
	return @useError;
	
}

sub getDerivedVmName ( \% ) {
	
	my ( %options ) = %{ ( shift ) };

	# Get converted names for default values, auto-generated names, etc.
	if ( !defined $options{'vmname'} or $options{'vmname'} !~ /^\s*$/ ) {
		
		my ( $useErrorRef, $ovfKeysRef ) = convertNames( %options );
				
		if ( !defined $$ovfKeysRef{'vmname'} ) {
			return ( $useErrorRef, undef );
		} else {
			return ( undef, $$ovfKeysRef{'vmname'} );
		}

	} else {
		return ( undef, $options{'vmname'} );
	}
	
	return ( undef, undef );
	
}

sub validateVcenterArguments( \% ) {

	my ( %options ) = %{ ( shift ) };
	
	my $vcenter = $options{'vcenter'};
	my $vcUser  = $options{'vcenteruser'};
	my $vcPass  = $options{'vcenterpassword'};
	
	my @useError;

	if ( !defined $vcenter ) {
		push( @useError, "--vcenter required\n" );
	}

	if ( !defined $vcUser ) {
		push( @useError, "--vcenteruser required\n" );
	}

	if ( !defined $vcPass ) {
		push( @useError, "--vcenterpassword required\n" );
	}
	
	return @useError;
	
}

sub validateDistributionArguments( \% ) {
	
	my ( %options ) = %{ ( shift ) };
	
	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	
	my $distribution = $options{'distribution'};
	my $major        = $options{'major'};
	my $minor        = $options{'minor'};
	my $architecture = $options{'architecture'};
	my $group        = $options{'group'};
	my $instance     = $options{'instance'};
	
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

sub validateHasOvfProperties( \% ) {
	
	my ( %options ) = %{ ( shift ) };
		
	my @useError;
	push( @useError, validateDistributionArguments( %options ) );
	handleUseError( \@useError ); # Don't continue, since distro args needed next.	
	
	my $action = $options{'action'};
	my $distro = $options{'distribution'};
	my $major  = $options{'major'};
	my $minor  = $options{'minor'};
	my $arch   = $options{'architecture'};
			
	if ( !defined $OVF::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} ) {
		my $errMsg = qq{NO OVF PROPERTIES FOUND for $distro $major.$minor $arch};
		push( @useError, $errMsg );
		logMessage( $action, undef, 'err', 'skip', $errMsg );
	}
	
	return @useError;
	
}

sub handleUseError( \@ ) {
	
	my ( @useError ) = @{ ( shift ) };

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 166;
	}
	
}

sub logMessage ( $$$$$ ) {
	
	my $action       = shift;
	my $actionDetail = shift;
	my $priority     = shift;
	my $status       = shift;
	my $message      = shift;
	
	my $log;
	my $logComplete;
	
	if ( defined $priority ) {
		$log .= $action if ( defined $action );
		$log .= qq{ ($actionDetail)} if ( defined $actionDetail );
		$logComplete = $log;
		$log .= qq{ : STATUS ($status)} if ( defined $status );
		$log .= qq{ : $message} if (defined $message );
		Sys::Syslog::syslog( $priority, $log ) if ( $log );
		if ( $priority eq 'err' or $priority eq 'warning' ) {
			Sys::Syslog::syslog( 'info', qq{$logComplete : END} );
			exit 167 if ( $priority eq 'warning' );
			exit 168 if ( $priority eq 'err' );
		}
	}
	
}

1;

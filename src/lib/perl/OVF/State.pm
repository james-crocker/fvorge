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

package OVF::State;

use lib '../../perl';

use strict;
use warnings;

use POSIX;
use Tie::File;
use File::Path;
use Digest::MD5;
use Sys::Syslog;
use Net::IPv4Addr;

use Debug;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

my $propertiesPath = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{path};
my $propertiesFile = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{file};

my $ovfPath = qq{$propertiesPath/$propertiesFile};

# Easier to work with arrays for saving/reading the OVF properties file than parsing the complex hash %options
my @currentOvfProperties;
my @previousOvfProperties;

my $originalsPath = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{path};

my $groupedProperties = q{^(network\.if|network\.alias|network\.bond|storage\.(fs|lvm)|service\.security\.ssh\.user\.config|custom\..+)$};
my $yesRegex          = 'y|yes|true|t|1';
my $noRegex           = 'n|no|false|f|0';
my $saneKeyRegex      = q{[a-z\-\_\.0-9]+};
my $saneIdRegex       = q{[a-z\-\_0-9]+};

sub envSetup ( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;

	if (! -d $propertiesPath) {
		dbg "create properties path: $propertiesPath\n";
		mkpath($propertiesPath) or (Sys::Syslog::syslog('err', qq{$action Couldn't create [ $propertiesPath ] ($?:$!)}) and die);
	}

	if (! -d $originalsPath) {
		mkpath( $originalsPath ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't create [ $originalsPath ] ($?:$!)} ) and die );
	}

}

sub ovfCompareNotEqual ( $\% ) {

	my $ovf = shift;
	my %options = %{ ( shift ) };

	# These are 'grouped' items
	if ( $ovf =~ /$groupedProperties/ ) {

		foreach my $itemNum ( keys %{ $options{ovf}{current}{$ovf} } ) {
			dbg "compare item: $ovf $itemNum\n";
			# Value is always changed if there was no previous applied property
			return 1 if !defined $options{ovf}{previous}{$ovf}{$itemNum};

			foreach my $scanProperty (keys %{$options{ovf}{previous}{$ovf}{$itemNum}}) {
				my $current  = $options{ovf}{current}{$ovf}{$itemNum}{$scanProperty};
				my $previous = $options{ovf}{previous}{$ovf}{$itemNum}{$scanProperty};
				return 1 if ( Digest::MD5::md5_hex( $current ) ne Digest::MD5::md5_hex( $previous ) );
			}
		}

	} else {
		dbg "compare nongroup item: $ovf\n";

		# Value is always changed if there was no previous applied property
		return 1 if !defined $options{ovf}{previous}{$ovf};

		my $current  = $options{ovf}{current}{$ovf};
		my $previous = $options{ovf}{previous}{$ovf};
		return 1 if ( Digest::MD5::md5_hex( $current ) ne Digest::MD5::md5_hex( $previous ) );
	}
	dbg "current and previous items equal: $ovf\n";
	return 0;

}

sub ovfIsChanged ( $\% ) {
	my $property = shift;
	my %options = %{ ( shift ) };

	# No sense trying all the compares if there wasn't a previously saved environment
	return 1 if ( !exists $options{ovf}{previous} );

	# Search over the whole ovf class space eg. network.*
	if ( $property =~ /(\S+)\.\*/ ) {
		my $class = $1;

		foreach my $ovf ( keys %{ $options{ovf}{current} } ) {
			dbg "check for class property change: $class $ovf\n";
			if ( $ovf =~ /$class\..+/ ) {
				my $diff = ovfCompareNotEqual($ovf, %options);
				return 1 if ($diff == 1);
			}
		}
		dbg "all subproperties equal: $property\n";
		return 0; # all the same
	} else {
		dbg "check for property change: $property\n";
		return ovfCompareNotEqual( $property, %options );

	}

}

sub decodeURL ( $ ) {

	my $item = shift;

	#		"		&quot;
	#		<		&lt;
	#		>		&gt;
	#		&		&amp;
	#		space	%20
	#		=		%3D
	#		;		%3B (only if ;; together)

	$item =~ s/\%20/ /g;
	$item =~ s/\%3B\%3B/\;\;/g;
	$item =~ s/\%3D/\=/g;
	$item =~ s/\&quot;/\"/g;
	$item =~ s/\&lt;/\</g;
	$item =~ s/\&gt;/\>/g;
	$item =~ s/\&amp;/\&/g;

	return $item;

}

sub normalizeTrueFalse ( $$ ) {

	my $key  = shift;
	my $item = shift;

	return undef if ( !defined $key or !defined $item );

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;

	# Return if certain key types have values outside y|n
	my $requiredTrueFalse = '^(enabled|disabled|packages|setup|change|initdb|clear-storage|prerequisites|fstab|mount|packages-32bit|add-sshd|syslog-emerg|booton|genkeypair)$';
	return $item if ( $key ne '' and $key !~ /$requiredTrueFalse/ );

	if ( $item !~ /,/ ) {
		if ( $item =~ /^($yesRegex)$/i ) {
			return 1;
		} elsif ( $item =~ /^($noRegex)$/i ) {
			return 0;
		} else {
			Sys::Syslog::syslog( 'warning', qq{$action WARNING: Expecting a y|n value. Got $key ($item)} );
			return $item;
		}
	} else {
		my @items = split( /,/, $item );
		my @transformedItems;
		foreach my $val ( @items ) {
			push( @transformedItems, &normalizeTrueFalse( $key, $val ) );
		}
		return join( ',', @transformedItems );
	}

}

sub normalizeYesNo ( $$ ) {

	my $key  = shift;
	my $item = shift;

	return undef if ( !defined $key or !defined $item );

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;

	# Return if certain key types have values outside y|n
	my $requiredYesNo = '^(onboot|onparent|permit-root|pubkey-auth|gssapi-auth|rsa-auth|x11forwarding|tcpforwarding|password-auth|usepam)$';
	return $item if ( $key ne '' and $key !~ /$requiredYesNo/ );

	if ( $item =~ /^($yesRegex)$/i ) {
		return 'yes';
	} elsif ( $item =~ /^($noRegex)$/i ) {
		return 'no';
	} else {
		Sys::Syslog::syslog( 'warning', qq{$action WARNING: Expecting a y|n value. Got $key ($item)} );
		return $item;
	}

}

sub checkRequired ( $$$$\% ) {

	my $action          = shift;
	my $required        = shift;
	my $enableProperty  = shift;
	my $requiredEnabled = shift;
	my %options         = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	if ( $options{ovf}{current}{$enableProperty} ) {
		push( @{$required}, @{$requiredEnabled} );
	}

	my $halt = 0;
	foreach my $reqProperty ( @{$required} ) {
		if ( !defined $options{ovf}{current}{$reqProperty} or !exists $options{ovf}{current}{$reqProperty} ) {
			Sys::Syslog::syslog( 'err', qq{$thisSubName Missing required parameter: $reqProperty} );
			$halt = 1;
		}
	}

	Sys::Syslog::syslog( 'err', qq{$thisSubName $action ::SKIP::} ) if ( $halt );

	return $halt;
}

sub printOvfProperties ( $\% ) {

	my $printKey = shift;
	my $options  = shift;

	my @printedOptions;

	if ( $printKey ne '' ) {
		$printKey .= '.';
	}

	foreach my $key ( sort keys %{$options} ) {

		if ( ref( $options->{$key} ) ne 'HASH' ) {
			my $printable = qq{$printKey$key => } . $options->{$key};

			#Sys::Syslog::syslog( 'info', $printable );
			push( @printedOptions, $printable );
		} else {
			push( @printedOptions, &printOvfProperties( qq{$printKey$key}, $options->{$key} ) );
		}

	}

	return @printedOptions;

}

sub isSaneKey ( \$ ) {

	my $key = ${ ( shift ) };

	if ( $key !~ /$saneKeyRegex/i ) {
		return 0;
	}

	return 1;

}

sub isSaneId ( \$ ) {

	my $id = ${ ( shift ) };

	if ( $id !~ /$saneIdRegex/i ) {
		return 0;
	}

	return 1;

}

sub isSaneEqual ( \$ ) {

	my $value = ${ ( shift ) };

	# ! ' abcd ', ' = ', '= ', ' =', 'abc ', ' abc'
	if ( $value =~ /\s+[^\=\s]+\s+/ or $value =~ /\s+=\s+/ or $value =~ /^\=$/ or $value =~ /^=\s+/ or $value =~ /\s+=$/ or $value =~ /^[^\=\s]+\s+/ or $value =~ /\s+[^\=\s]+$/ ) {
		return 0;
	}

	return 1;

}

sub isSaneDoubleParens ( \$ ) {

	my $value = ${ ( shift ) };

	# ! ' ;; '
	if ( $value =~ /;;/ and ( $value =~ /\S;;/ or $value =~ /;;\S/ ) ) {
		return 0;
	}

	return 1;

}

sub parseOvfProperties ( \@ ) {

	my $ovfProperties = shift;

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;

	# Regardless of OVF ve:unitNumber use our own reference numbers.
	my $ifUnitNumber = 1;

	my %ovfPropertyCollection;

	# Lowercase all key and id declarations
	foreach my $ovfProperty ( @{$ovfProperties} ) {

		# Slurp PropertySection MAC addresses, network and unit
		if ( $ovfProperty =~ /Property oe:key\="([^"]+)"\s*oe:value\="([^"]*)"/ ) {

			my $key   = lc( $1 );
			my $value = $2;

			if ( !isSaneKey( $key ) ) {
				Sys::Syslog::syslog( 'err', "$action Invalid syntax: Found ($key)" );
				die;
			}

			if ( !isSaneDoubleParens( $value ) ) {
				Sys::Syslog::syslog( 'warning', "$action WARNING: Possible missed grouping; expecting ' ;; ' ($value)" );
			}
			
			if ( $key =~ /^lite\./) {
				#20140610 Marshal 'lite' settings into original ovf properties. Allows for ungrouping properties
				# and presenting as individual elements in the vCenter vApp properties dialog. 'lite' only supports
				# one network interface configuration.
				my $originalKey = $';
				my $item = decodeURL( $value );
				if ( $originalKey =~ /^(network\.label|network\.ipv4|network\.ipv4-bootproto|network\.ipv4-prefix)$/ ) {
					if ( $originalKey =~ /^network\./ ) {
							$originalKey = $';
					}
					$ovfPropertyCollection{'network.if'}{1}{'if'} = 1;
					$item = normalizeYesNo( $originalKey, $item );
					$item = normalizeTrueFalse( $originalKey, $item );
					if ( $originalKey =~ /^ipv4-prefix$/ ) {
						# Convert to cidr if octet
						if ( $item =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
							$item = Net::IPv4Addr::ipv4_msk2cidr( $item );
						}
					}
					$ovfPropertyCollection{'network.if'}{1}{$originalKey} = $item;
				} else {
					$item = normalizeYesNo( $originalKey, $item );
					$item = normalizeTrueFalse( $originalKey, $item );
					$ovfPropertyCollection{$originalKey} = $item;
				}
			} elsif ( $value =~ /\s+;;\s+/ or $key =~ /$groupedProperties/ ) {
			
				# Breakout 'grouped' properties like NIC, Services
				# item=val,item=val;;item=val,item=val;;item=val,item=val
				# Always set group for 'network.if' or 'storage.fs' or 'storage.lvm' since depend on at least one group.
				my $groupCount = 1;
				foreach my $groupSelection ( ( split /\s+;;\s+/, $value ) ) {

					if ( !isSaneEqual( $groupSelection ) ) {
						Sys::Syslog::syslog( 'err', "$action Invalid syntax: Found ($key)($groupCount) => $groupSelection" );
						die;
					}

					foreach my $groupProperties ( split( /\s+/, $groupSelection ) ) {
						my $id;
						my $setting;
						my $item;
						( $id, $setting ) = split( /=/, $groupProperties, 2 );
						$id = lc( $id );

						if ( !isSaneId( $id ) ) {
							Sys::Syslog::syslog( 'err', "$action Invalid syntax: Found ($key)($groupCount) => $id" );
							die;
						}

						$item = decodeURL( $setting );
						$item = normalizeYesNo( $id, $item );
						$item = normalizeTrueFalse( $id, $item );
						$ovfPropertyCollection{$key}{$groupCount}{$id} = $item;

					}
					$groupCount++;
				}

			} elsif ( $value =~ /=/ ) {

				if ( !isSaneEqual( $value ) ) {
					Sys::Syslog::syslog( 'info', "$action Invalid syntax: Found ($key) => $value" );
					die;
				}

				# item=val item=val item=val item="stuff=other=things"
				foreach my $groupProperties ( split( /\s+/, $value ) ) {
					my $id;
					my $setting;
					my $item;
					( $id, $setting ) = split( /=/, $groupProperties, 2 );
					$id = lc( $id );

					if ( !isSaneId( $id ) ) {
						Sys::Syslog::syslog( 'err', "$action Invalid syntax: Found ($id)" );
						die;
					}

					$item = decodeURL( $setting );
					$item = normalizeYesNo( $id, $item );
					$item = normalizeTrueFalse( $id, $item );
					$ovfPropertyCollection{"$key.$id"} = $item;
				}
			} else {
				my $item = decodeURL( $value );
				$item = normalizeYesNo( $key, $item );
				$item = normalizeTrueFalse( $key, $item );				
				
				$ovfPropertyCollection{$key} = $item;
			}

		}

		# Slurp ve:EthernetAdapterSection MAC addresses, network and unit
		if ( $ovfProperty =~ /Adapter ve:mac\="([^"]+)"\s*ve:network\="([^"]*)"\s*ve:unitNumber\="([^"]*)"/ ) {

			my $mac     = $1;
			my $network = $2;
			my $unitNum = $3;

			$ovfPropertyCollection{'network.if'}{$ifUnitNumber}{'mac'}     = $mac;
			$ovfPropertyCollection{'network.if'}{$ifUnitNumber}{'unit'}    = $unitNum;
			$ovfPropertyCollection{'network.if'}{$ifUnitNumber}{'network'} = $network;

			$ifUnitNumber++;

		}

	}

	if ( %ovfPropertyCollection ) {
		dbg_hash('Parsed Properties', \%ovfPropertyCollection);
		return \%ovfPropertyCollection;
	} else {
		return {};
	}

}

sub propertiesGetCurrent ( \% ) {

	my $options = shift;

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $getOvfCmd      = $OVF::Vars::Common::getOvfPropertiesCmd;
	my $getOvfDefaults = $OVF::Vars::Common::sysVars{'fvorge'}{'ovf-defaults'};

	my $halt = 0;
	Sys::Syslog::syslog( 'info', qq{$action ... } );

	if ( -e $getOvfDefaults ) {
		tie @currentOvfProperties, 'Tie::File', $getOvfDefaults, autochomp => 1 or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't open OVF Defaults Properties file [ $getOvfDefaults ] ($?:$!)} ) and die );
		Sys::Syslog::syslog( 'info', qq{$action Using OVF Defaults Properties found in file [ $getOvfDefaults ]} );
	} else {
		@currentOvfProperties = qx{ $getOvfCmd } or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't retrieve OVF Properties using [ $getOvfCmd ] ($?:$!)} ) and die );
		Sys::Syslog::syslog( 'info', qq{$action Using OVF Properties fetched from [ $getOvfCmd ]} );
	}

	$options->{ovf}{current} = parseOvfProperties( @currentOvfProperties );
	dbg_hash('Current Properties', $options->{ovf}{current});
	my $required = [ 'host.architecture', 'host.cluster', 'host.distribution', 'host.instance', 'host.major', 'host.minor' ];
	my $requiredEnabled = [];
	die if ( checkRequired( $action, $required, '', $requiredEnabled, %{$options} ) );

	my $distrosRegex      = $OVF::Vars::Common::sysVars{distrosRegex};
	my $archsRegex        = $OVF::Vars::Common::sysVars{archsRegex};
	my $rhelVersionsRegex = $OVF::Vars::Common::sysVars{rhelVersionsRegex};
	my $slesVersionsRegex = $OVF::Vars::Common::sysVars{slesVersionsRegex};
	my $ubuntuVersionsRegex = $OVF::Vars::Common::sysVars{ubuntuVersionsRegex};

	my $distro   = $options->{ovf}{current}{'host.distribution'};
	my $arch     = $options->{ovf}{current}{'host.architecture'};
	my $major    = $options->{ovf}{current}{'host.major'};
	my $minor    = $options->{ovf}{current}{'host.minor'};
	my $cluster  = $options->{ovf}{current}{'host.cluster'};
	my $instance = $options->{ovf}{current}{'host.instance'};

	( Sys::Syslog::syslog( 'err', qq{$action Unknown host.distribution ($distro): Expecting $distrosRegex} ) and die ) if ( $distro !~ /^($distrosRegex)$/ );
	( Sys::Syslog::syslog( 'err', qq{$action Unknown host.architecture ($arch): Expecting $archsRegex} )     and die ) if ( $arch !~ /^($archsRegex)$/ );
	( Sys::Syslog::syslog( 'err', qq{$action Unknown host.cluster ($cluster): Expecting only digit(s)} )     and die ) if ( $cluster !~ /^\d+$/ );
	( Sys::Syslog::syslog( 'err', qq{$action Unknown host.instance ($instance): Expecting only digit(s)} )   and die ) if ( $instance !~ /^\d+$/ );

	my $compoundVersion = qq{$major.$minor};

    if ( $distro eq 'SLES' ) {
		( Sys::Syslog::syslog( 'err', qq{$action Unsupported version ($compoundVersion) for distribution ($distro): Expecting host.major.host.minor matching $slesVersionsRegex} ) and die ) if ( $compoundVersion !~ /^($slesVersionsRegex)$/ );
	} elsif ( $distro eq 'Ubuntu' ) {
        ( Sys::Syslog::syslog( 'err', qq{$action Unsupported version ($compoundVersion) for distribution ($distro): Expecting host.major.host.minor matching $ubuntuVersionsRegex} ) and die ) if ( $compoundVersion !~ /^($ubuntuVersionsRegex)$/ );		
	} else {
		( Sys::Syslog::syslog( 'err', qq{$action Unsupported version ($compoundVersion) for distribution ($distro): Expecting host.major.host.minor matching $rhelVersionsRegex} ) and die ) if ( $compoundVersion !~ /^($rhelVersionsRegex)$/ );
	}

}

sub propertiesGetPrevious ( $\% ) {

	my $appliedType = shift;
	my $options     = shift;

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName ($appliedType)";

	my $previousPath = qq{$ovfPath-$appliedType};

	Sys::Syslog::syslog( 'info', qq{$action ... } );

	# If no previous then leave NONEXISTENT, otherwise use previous
	if ( -e $previousPath ) {
		tie @previousOvfProperties, 'Tie::File', $previousPath, autochomp => 1 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't open $previousPath ($?:$!)} );
		$options->{ovf}{previous} = parseOvfProperties( @previousOvfProperties );
	} else {

		# 'previous' may have been set from previous groups, like 'network' so clear out since not previous settings for this current group.
		delete( $options->{ovf}{previous} );
		Sys::Syslog::syslog( 'info', qq{$action NO PREVIOUS OVF PROPERTIES FILE FOUND NAMED [ $previousPath ]; ASSUMING INITILIZATION} );
	}

}

sub propertiesGetGroup ( $\@ ) {

	my $groupType      = shift;
	my $printedOptions = shift;

	my @groupProperties;

	foreach my $key ( @{$printedOptions} ) {

		if ( $groupType eq 'network' and ( $key =~ /^(host|network)\./ or $key =~ /^custom\.$groupType/ ) ) {
			push( @groupProperties, $key );
		}

		if ( $groupType eq 'packages' and ( $key =~ /\.(packages|packages-32bit)\s+/ or $key =~ /^sios\.(automation\.|prerequisites|product)/ or $key =~ /^custom\.$groupType/ ) ) {
			push( @groupProperties, $key );
		}

		if ( $groupType eq 'host-services' and ( $key =~ /^service\.[^\.]+\.(apparmor|firewall|ntp|pam\.ldap|selinux|snmp|sshd|syslog|xserver|md|iscsi|multipath)\./ or $key =~ /^host\.(locale|time)\./ or $key =~ /^sios\.automation\./ or $key =~ /^custom\.$groupType/ ) ) {
			push( @groupProperties, $key );
		}

		if ( $groupType eq 'storage' and ( $key =~ /^storage\./ or $key =~ /^custom\.$groupType/ ) ) {
			push( @groupProperties, $key );
		}

		if ( $groupType eq 'app-services' and ( $key =~ /^(service)\.[^\.]+\.(apache|oracle|sap|sapdb|nfs|mysql|postgresql|sybase|postfix|samba)\./ or $key =~ /^sios\.(product|setup|setup-args)/ or $key =~ /^custom\.$groupType/ ) ) {
			push( @groupProperties, $key );
		}

	}

	return @groupProperties;

}

sub propertiesApplied ( $\%) {

	my $appliedType = shift;
	my $options     = shift;

	#If no type(group) then process the properties regardless of any previous settings
	return 0 if ( !$appliedType );
	
	# If asked not to apply any properties
	return 1 if ( exists $options->{ovf}{current}{'fvorge.disabled'} and $options->{ovf}{current}{'fvorge.disabled'} );

	propertiesGetPrevious( $appliedType, %{$options} );
	
	# If no previous then apply any current changes
	return 0 if ( !exists $options->{ovf}{previous} or !defined $options->{ovf}{previous} );

	my @printedCurrentProperties;
	@printedCurrentProperties = printOvfProperties( '', %{ $options->{ovf}{current} } );

	my @printedPreviousProperties;
	@printedPreviousProperties = printOvfProperties( '', %{ $options->{ovf}{previous} } );

	my @current  = propertiesGetGroup( $appliedType, @printedCurrentProperties );
	my @previous = propertiesGetGroup( $appliedType, @printedPreviousProperties );

	dbg "prev: @previous\ncur: @current\n";
	my $currentMd5  = Digest::MD5::md5_hex( @current );
	my $previousMd5 = Digest::MD5::md5_hex( @previous );

	if ( $currentMd5 eq $previousMd5 ) {
		return 1;
	} else {
		return 0;
	}

}

sub propertiesSave ( $\% ) {

	my $saveType = shift;
	my $options  = shift;

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = "$thisSubName ($saveType)";

	die if ( !@currentOvfProperties );

	my $currentPath       = qq{$ovfPath-$saveType};
	my $currentParsedPath = qq{$ovfPath-$saveType-parsed};
	my @printedCurrentProperties;

	Sys::Syslog::syslog( 'info', qq{$action $currentPath} );
	open( 'OVFPW', '>', $currentPath ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't save OVF Properties file [ $currentPath ] ($?:$!)} ) and die );
	print OVFPW join( "\n", @currentOvfProperties );
	close OVFPW;

	Sys::Syslog::syslog( 'info', qq{$action $currentParsedPath} );
	@printedCurrentProperties = printOvfProperties( '', %{ $options->{ovf}{current} } );
	open( 'OVFPW', '>', $currentParsedPath ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't save PARSED OVF Properties file [ $currentParsedPath ] ($?:$!)} ) and die );
	print OVFPW join( "\n", @printedCurrentProperties );
	close OVFPW;

}

1;

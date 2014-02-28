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

my $groupedProperties = q{^(network\.if|network\.alias|network\.bond|storage\.(fs|lvm)|custom\..+)$};
my $yesRegex          = 'y|yes|true|t|1';
my $noRegex           = 'n|no|false|f|0';
my $saneKeyRegex      = q{[a-z\-\_\.0-9]+};
my $saneIdRegex       = q{[a-z\-\_0-9]+};

sub envSetup ( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;

	if ( !-d $propertiesPath ) {
		mkpath( $propertiesPath ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't create [ $propertiesPath ] ($?:$!)} ) and die );
	}

	if ( !-d $originalsPath ) {
		mkpath( $originalsPath ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't create [ $originalsPath ] ($?:$!)} ) and die );
	}

}

sub ovfCompareNotEqual ( $\% ) {

	my $ovf = shift;
	my %options = %{ ( shift ) };

	# These are 'grouped' items
	if ( $ovf =~ /$groupedProperties/ ) {

		foreach my $itemNum ( keys %{ $options{ovf}{current}{$ovf} } ) {

			# Value is always changed if there was no previous applied property
			return 1 if !defined $options{ovf}{previous}{$ovf}{$itemNum};

			foreach my $scanProperty ( sort keys %{ $options{ovf}{previous}{$ovf}{$itemNum} } ) {
				my $current  = $options{ovf}{current}{$ovf}{$itemNum}{$scanProperty};
				my $previous = $options{ovf}{previous}{$ovf}{$itemNum}{$scanProperty};
				return 1 if ( Digest::MD5::md5_hex( $current ) ne Digest::MD5::md5_hex( $previous ) );
			}
		}

	} else {

		# Value is alwasy changed if there was no previous applied property
		return 1 if !defined $options{ovf}{previous}{$ovf};

		my $current  = $options{ovf}{current}{$ovf};
		my $previous = $options{ovf}{previous}{$ovf};
		return 1 if ( Digest::MD5::md5_hex( $current ) ne Digest::MD5::md5_hex( $previous ) );
	}

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

			if ( $ovf =~ /$class\..+/ ) {

				return ovfCompareNotEqual( $ovf, %options );

			}
		}

	} else {

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
	my $requiredTrueFalse = '^(enabled|packages|setup|change|initdb|clear-storage|prerequisites|fstab|mount|rsa-auth|gssapi-auth|pubkey-auth|permit-root|packages-32bit|add-sshd|syslog-emerg|onboot)$';
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
	my $requiredTrueFalse = '\.(onboot|onparent)$';
	return $item if ( $key ne '' and $key !~ /$requiredTrueFalse/ );

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

			# Breakout 'grouped' properties like NIC, Services
			# item=val,item=val;;item=val,item=val;;item=val,item=val
			# Always set group for 'network.if' or 'storage.fs' or 'storage.lvm' since depend on at least one group.
			if ( $value =~ /\s+;;\s+/ or $key =~ /$groupedProperties/ ) {

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

		#printOvfProperties( '', %ovfPropertyCollection );

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

	my $required = [ 'host.architecture', 'host.cluster', 'host.distribution', 'host.instance', 'host.major', 'host.minor' ];
	my $requiredEnabled = [];
	die if ( checkRequired( $action, $required, '', $requiredEnabled, %{$options} ) );

	my $distrosRegex      = $OVF::Vars::Common::sysVars{distrosRegex};
	my $archsRegex        = $OVF::Vars::Common::sysVars{archsRegex};
	my $rhelVersionsRegex = $OVF::Vars::Common::sysVars{rhelVersionsRegex};
	my $slesVersionsRegex = $OVF::Vars::Common::sysVars{slesVersionsRegex};

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

	if ( $distro ne 'SLES' ) {
		( Sys::Syslog::syslog( 'err', qq{$action Unsupported version ($compoundVersion) for distribution ($distro): Expecting host.major.host.minor matching $rhelVersionsRegex} ) and die ) if ( $compoundVersion !~ /^($rhelVersionsRegex)$/ );
	} else {
		( Sys::Syslog::syslog( 'err', qq{$action Unsupported version ($compoundVersion) for distribution ($distro): Expecting host.major.host.minor matching $slesVersionsRegex} ) and die ) if ( $compoundVersion !~ /^($slesVersionsRegex)$/ );
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

		if ( $groupType eq 'host-services' and ( $key =~ /^service\.[^\.]+\.(apparmor|firewall|ntp|pam\.ldap|selinux|snmp|sshd|syslog|xserver|md|iscsi|multipath)\./ or $key =~ /^host\.locale\./ or $key =~ /^sios\.automation\./ or $key =~ /^custom\.$groupType/ ) ) {
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

	return 0 if ( !$appliedType );

	propertiesGetPrevious( $appliedType, %{$options} );

	return 0 if ( !exists $options->{ovf}{previous} or !defined $options->{ovf}{previous} );

	my @printedCurrentProperties;
	@printedCurrentProperties = printOvfProperties( '', %{ $options->{ovf}{current} } );

	my @printedPreviousProperties;
	@printedPreviousProperties = printOvfProperties( '', %{ $options->{ovf}{previous} } );

	my @current  = propertiesGetGroup( $appliedType, @printedCurrentProperties );
	my @previous = propertiesGetGroup( $appliedType, @printedPreviousProperties );

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

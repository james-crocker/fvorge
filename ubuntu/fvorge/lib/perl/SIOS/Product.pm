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

package SIOS::Product;

use strict;
use warnings;

use Storable;

use lib '../../perl';

use SIOS::ArkVars;
use SIOS::BuildVars;
use SIOS::CommonVars;
use SIOS::LicenseVars;
use SIOS::Logger;
use Switch;

#use Data::Dumper;

my $parentCaller = ( caller( 0 ) )[ 1 ];

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

## HELPERS -------------------------------------------------------------

sub backupProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'BACKUP PRODUCT';
	my $backup    = $options{backup};
	my $product   = $options{product};
	my $related   = $options{related};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $backupCmd = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup};

	unless ( $backup ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{$action $backupCmd ... } );

	system( qq{$backupCmd$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't $action ($?:$!) \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

}

sub confirmAction ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my ( %options ) = %{ ( shift ) };

	my $action    = $options{action};
	my $build     = $options{build};
	my $confirm   = $options{confirm};
	my $product   = $options{product};
	my $version   = $options{version};
	my $gaVersion = $options{gaVersion};

	return unless ( $confirm );

	# Regardless of verbosity setting, always display if confirmation is requested.

	SIOS::Logger::logIt( 1, $parentCaller, 1, 'print', qq{CONFIRM $action of [ $product - $SIOS::CommonVars::product{$product}{name}, Version($version)} );
	SIOS::Logger::logIt( 1, undef, 0, 'print', qq{, Build($build)} )               if ( $build );
	SIOS::Logger::logIt( 1, undef, 0, 'print', qq{, GA-ARKS-Version($gaVersion)} ) if ( defined( $gaVersion ) );
	SIOS::Logger::logIt( 1, undef, 0, 'print', qq{ ] (y/n) [n]: } );

	my $choice = <STDIN>;

	if ( $choice !~ /^y$/ios ) {
		SIOS::Logger::logIt( 1, $parentCaller, 1, 'print', qq{$action CANCELED ! \n} );
		exit 1;
	}

}

sub confirmVersion ( % ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $options = shift;

	my $product   = $options->{product};
	my $verbosity = $options->{verbosity};
	my $version   = $options->{version};

	my $productRegexPattern = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern};

	my @rpmList = getRpmList();

	my $definedVersionMatch = 0;

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{CHECKING VERSION REQUEST $version ... } );

	# Confirm requested version is in the defined list of known versions for the product.
	foreach my $ver ( @{ $SIOS::CommonVars::product{$product}{versions} } ) {
		if ( $version =~ /^$ver$/ ) {
			$definedVersionMatch = 1;
			last;
		}
	}

	# If 'latest'; try and get installed version
	if ( $version =~ /^$SIOS::CommonVars::productVersionLatest$/ios ) {

		# Try and get installed version
		my $rpm = rpmInstalled( $productRegexPattern );

		if ( $rpm and $rpm =~ /^$productRegexPattern/ ) {
			my $installedVersion = $1;
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{found $installedVersion \n} );
			$options->{version} = $installedVersion;
			return;
		} elsif ( $SIOS::CommonVars::product{$product}{versions}[ 1 ] ) {

			# 'First' index is 'latest' unless changed.
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{installed version not found; assuming $SIOS::CommonVars::product{$product}{versions}[1] \n} );
			$options->{version} = $SIOS::CommonVars::product{$product}{versions}[ 1 ];
			return;
		}

	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Could not determine supported version. Please specify a recognized version ! \n} );

}

sub stopProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'STOP PRODUCT';
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $stopCmds = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	foreach my $stopCmd ( @{$stopCmds} ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$stopCmd ... } );
		if ( system( qq{$stopCmd$quietCmd} ) == 0 ) {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
		} else {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $action ($?:$!) \n} );
		}
	}

}

sub killProcesses ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'KILL PROCESSES';
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $grepCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{grepCmd};
	my $killCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{killCmd};
	my $psCmd   = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{psCmd};

	my $processName = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{processName};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{$action named: '$processName' ... } );

	# Let stopProduct settle...
	sleep( 4 );

	my @processes = qx{$psCmd | $grepCmd $processName} or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch process list ($?:$!) \n} );

	# Running the commands will generate 2 self referencing entries for ps and grep
	if ( $#processes > 2 ) {
		SIOS::Logger::logIt( $verbosity, undef, 0, 'print', qq{\n} );
	} else {
		SIOS::Logger::logIt( $verbosity, undef, 0, 'print', qq{none found \n} );
		return;
	}

	foreach my $ps ( @processes ) {

		# exclude self-references
		next if ( $ps =~ /($psCmd|$grepCmd)/ );
		if ( $ps =~ /^\s*(\d+)\s+/ ) {
			my $psNum = $1;
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$killCmd: $ps ... } );
			system( qq{$killCmd $psNum$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $action: $ps ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
		}
	}

}

sub getRpmList ( ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my @rpmList = qx{$SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rpmCmd}};

	return @rpmList;

}

sub rpmInstalled ( $ ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $rpmMatch = shift;

	my @rpmList = getRpmList();

	foreach my $rpm ( @rpmList ) {
		return $rpm if ( $rpm =~ /^$rpmMatch/ );
	}

	return undef;

}

sub removeRpms ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE RPM\'s';
	my $allrpm    = $options{allrpm};
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $grepCmd     = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{grepCmd};
	my $rpmFetchCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rpmFetchCmd};
	my $rpmRmCmd    = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rpmRmCmd};
	my $sortCmd     = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{sortCmd};

	my $rpmGlobs = q{'} . join( '\|', @{ $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{rpm}{globs} } ) . q{'};

	my $rpmExcludeRegex = '(' . join( '|', @{ $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{rpm}{exclude} } ) . ')';

	my @lkRpms = qx{$rpmFetchCmd | $grepCmd $rpmGlobs | $sortCmd};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{$action ($rpmGlobs)* ... } );

	if ( !@lkRpms ) {
		SIOS::Logger::logIt( $verbosity, undef, 0, 'print', qq{none found \n} );
	} else {
		SIOS::Logger::logIt( $verbosity, undef, 0, 'print', qq{ \n} );
	}

	foreach my $delItem ( @lkRpms ) {
		chomp( $delItem );

		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$delItem ... } );
		if ( $allrpm or $delItem !~ /$rpmExcludeRegex/ ) {
			system( qq{$rpmRmCmd $delItem$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rpmRmCmd $delItem ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
		} else {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{excluded \n} );
		}

	}

}

sub removeFiles ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE FILES';
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $rmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	my $rmFiles = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{file};

	#print Dumper ( $rmFiles );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	foreach my $rmFile ( keys %$rmFiles ) {
		my $rmItem = $rmFiles->{$rmFile};
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$rmItem ... } );
		if ( $rmItem !~ /\*/ and ( !-e $rmItem or !-f $rmItem ) ) { SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{not found \n} ); next; }
		if ( $rmItem =~ /\*/ ) {
			if ( system( qq{$rmCmd $rmItem$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			}
		} else {
			system( qq{$rmCmd $rmItem$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
		}
	}

}

sub removeLinks ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE LINKS';
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $rmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	my $rmLinks = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{link};

	#print Dumper ( $rmLinks );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	foreach my $rmLink ( keys %$rmLinks ) {
		my $rmItem = $rmLinks->{$rmLink};
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$rmItem ... } );
		if ( $rmItem !~ /\*/ and ( !-e $rmItem or !-l $rmItem ) ) { SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{not found \n} ); next; }
		if ( $rmItem =~ /\*/ ) {
			if ( system( qq{$rmCmd $rmItem$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			}
		} else {
			system( qq{$rmCmd $rmItem$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
		}
	}

}

sub removePaths ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE PATHS';
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $rmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	my $rmPaths = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{path};

	#print Dumper ( $rmPaths );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	# sort reverse $b, $a for long path first
	foreach my $rmPath ( sort { $rmPaths->{$b} cmp $rmPaths->{$a} } keys %$rmPaths ) {
		my $rmItem = $rmPaths->{$rmPath};
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$rmItem ... } );
		if ( $rmItem !~ /\*/ and ( !-e $rmItem or !-d $rmItem ) ) { SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{not found \n} ); next; }
		if ( $rmItem =~ /\*/ ) {
			if ( system( qq{$rmCmd $rmItem$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed\n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			}
		} else {
			system( qq{$rmCmd $rmItem$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rmCmd $rmItem ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed\n} );
		}
	}

}

sub removeRelatedRpms ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE RELATED RPM\'s';
	my $product   = $options{product};
	my $related   = $options{related};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $rpmRmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rpmRmCmd};

	my $relatedRpms = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm};

	# Skip if no related rpms defined.
	return if ( scalar( keys %$relatedRpms ) <= 0 );

	unless ( $related ) {

		#print "$parentCaller\t::SKIP:: $action ...\n";
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	foreach my $rmRpm ( keys %$relatedRpms ) {
		my $rmItem = $relatedRpms->{$rmRpm};
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$rmItem ...} );
		if ( !rpmInstalled( $rmItem ) ) { SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{not found \n} ); next; }
		system( qq{$rpmRmCmd $rmItem$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rpmRmCmd $rmItem ($?:$!) \n} );
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
	}

}

sub removeRelatedOther ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE RELATED OTHER ITEMS';
	my $product   = $options{product};
	my $related   = $options{related};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $relatedHash = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{related};

	my %relatedOther;

	# Slurp NON RPM related items as 'other'.
	foreach my $otherItem ( keys %{$relatedHash} ) {
		$relatedOther{$otherItem} = $relatedHash->{$otherItem} if ( $otherItem ne 'rpm' );
	}

	# Skip if no related special items defined.
	return if ( scalar( keys %relatedOther ) <= 0 );

	unless ( $related ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	switch ( $product ) {

		#case 'lk'    { }
		#case 'vapp'  { }
		case 'smc' {

			#VMware SDK
			#my $vmwSdk = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{related}{other}{vmwareSdk}{unInstall};
			my $vmwSdk = $relatedOther{vmwareSdk}{unInstall};
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$vmwSdk ... } );
			if ( system( qq{$vmwSdk$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed \n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't un-install VMWare SDK ($?:$!) \n} );
			}

		}
	}

}

sub removeGroups ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE GROUPS';
	my $groups    = $options{groups};
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $awkCmd         = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{awkCmd};
	my $groupDeleteCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{groupDelCmd};
	my $getentCmd      = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{getentCmd};

	my $productLkGroups = '(' . join( '|', @{ $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{lkgroups} } ) . ')';

	my @sysGroups = qx{$getentCmd | $awkCmd} or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch system groups ($?:$!) \n} );

	unless ( $groups ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action $productLkGroups ... \n} );

	foreach my $group ( @sysGroups ) {
		chomp( $group );
		if ( $group =~ /$productLkGroups/ ) {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$group ... } );
			if ( system( qq{$groupDeleteCmd $group$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed\n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $groupDeleteCmd $group ($?:$!) \n} );
			}
		}
	}

}

sub removeUsers ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'REMOVE USERS';
	my $product   = $options{product};
	my $users     = $options{users};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $awkCmd        = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{awkCmd};
	my $userDeleteCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{userDelCmd};
	my $getentCmd     = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{getentCmd};

	my $productLkUsers = '(' . join( '|', @{ $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{lkusers} } ) . ')';

	my @sysUsers = qx{$getentCmd | $awkCmd} or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch system users ($?:$!) \n} );

	unless ( $users ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action $productLkUsers ... \n} );

	foreach my $user ( @sysUsers ) {
		chomp( $user );
		if ( $user =~ /$productLkUsers/ ) {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$user ... } );
			if ( system( qq{$userDeleteCmd $user$quietCmd} ) == 0 ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{removed\n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'warn', qq{WARNING: Couldn't $userDeleteCmd $user ($?:$!) \n} );
			}
		}
	}

}

sub postCommands ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = 'RUN POST COMMANDS';
	my $product   = $options{product};
	my $post      = $options{post};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $postCommands = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{post};

	# Skip if no related rpms defined.
	return if ( scalar @{$postCommands} <= 0 );

	unless ( $post ) {

		#print "$parentCaller\t::SKIP:: $action ...\n";
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	foreach my $runCmd ( @{$postCommands} ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$runCmd ...} );
		system( qq{$runCmd $quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $runCmd ($?:$!) \n} );
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
	}

}

sub setBuildVersion ( % ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $options = shift;

	my $verbosity = $options->{verbosity};
	my $product   = $options->{product};
	my $version   = $options->{version};

	return if ( $version ne $SIOS::BuildVars::build{default}{version} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{DISCOVER LATEST BUILD VERSION NUMBER ... \n} );

	my $userName = $options->{userName};
	my $host     = $SIOS::BuildVars::build{source}{host};
	my $base     = $SIOS::BuildVars::build{source}{base};

	my $lsCmd   = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{lsCmd};
	my $sshCmd  = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{sshCmd};
	my $tailCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tailCmd};

	my $recentBuildVersion;

	chomp( $recentBuildVersion = qx{$sshCmd $userName\@$host "$lsCmd $base | $tailCmd"} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{got version => $recentBuildVersion \n} );

	$SIOS::CommonVars::product{$product}{$recentBuildVersion}{$sysDistro}{$sysVersion}{$sysArch} = Storable::dclone( $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch} );
	$SIOS::ArkVars::type{$product}{$recentBuildVersion}                                          = Storable::dclone( $SIOS::ArkVars::type{$product}{$version} );
	$SIOS::LicenseVars::type{$product}{$recentBuildVersion}                                      = Storable::dclone( $SIOS::LicenseVars::type{$product}{$version} );
	$SIOS::LicenseVars::kitLicsList{$product}{$recentBuildVersion}                               = Storable::dclone( $SIOS::LicenseVars::kitLicsList{$product}{$version} );

	$options->{version} = $recentBuildVersion;

}

sub setBuildNumber ( % ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $options = shift;

	my $verbosity = $options->{verbosity};
	my $version   = $options->{version};

	return if ( $options->{build} ne $SIOS::BuildVars::build{default}{build} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{DISCOVER LATEST BUILD NUMBER ... \n} );

	my $userName = $options->{userName};
	my $host     = $SIOS::BuildVars::build{source}{host};
	my $base     = $SIOS::BuildVars::build{source}{base};

	my $lsCmd   = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{lsCmd};
	my $sshCmd  = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{sshCmd};
	my $tailCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tailCmd};

	my $recentBuildNumber;

	chomp( $recentBuildNumber = qx{$sshCmd $userName\@$host "$lsCmd $base/$version | $tailCmd"} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{got build => $recentBuildNumber \n} );

	$options->{build} = $recentBuildNumber;

}

sub setGaVersion ( % ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $options = shift;

	my $verbosity = $options->{verbosity};
	my $gaVersion = $options->{gaVersion};

	return if ( !defined( $gaVersion ) or $gaVersion ne $SIOS::BuildVars::build{default}{gaVersion} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{DISCOVER LATEST GA VERSION NUMBER ... \n} );

	my $userName = $options->{userName};
	my $host     = $SIOS::BuildVars::build{ga}{host};
	my $base     = $SIOS::BuildVars::build{ga}{base};

	my $lsCmd   = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{lsCmd};
	my $sshCmd  = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{sshCmd};
	my $tailCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tailCmd};

	my $recentGaVersion;

	# Folks keep touching items out of order. Use CommonVars array instead
	chomp( $recentGaVersion = qx{$sshCmd $userName\@$host "$lsCmd $base | $tailCmd"} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{got version => $recentGaVersion \n} );

	$options->{gaVersion} = $recentGaVersion;

}

sub makeSetupTarget ( % ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $options = shift;

	my $build     = $options->{build};
	my $overwrite = $options->{overwrite};
	my $path      = $options->{path};
	my $product   = $options->{product};
	my $verbosity = $options->{verbosity};
	my $version   = $options->{version};
	my $gaVersion = $options->{gaVersion};

	my $rmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	# Build up PATHS
	my $targetPath       = $path . "/$product-$version-$build";
	my $gaKitsTargetPath = undef;

	my @subPaths = ( $SIOS::BuildVars::build{setup}{licPath}, $SIOS::BuildVars::build{setup}{isoPath}, $SIOS::BuildVars::build{setup}{kitsPath} );

	if ( defined( $gaVersion ) ) {
		$gaKitsTargetPath = $gaVersion . '-ga';
		push( @subPaths, $gaKitsTargetPath );
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{MAKE SETUP TARGET ... \n} );

	if ( -e $targetPath ) {

		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{TARGET $targetPath EXISTS ... } );

		if ( $overwrite ) {
			SIOS::Logger::logIt( $verbosity, undef, 0, 'print', qq{REMOVING ... } );
			system( qq{$rmCmd $targetPath$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $rmCmd $targetPath ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
		} else {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: $targetPath exists and OVERWRITE was disabled ($?:$!) \n} );
		}

	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{MAKE PRODUCT TARGET $targetPath ... } );
	mkdir $targetPath or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't mkdir $targetPath ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{MAKE PRODUCT SUB TARGETS ... \n} );
	foreach my $subPath ( @subPaths ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'action', qq{$subPath ... } );
		my $subTargetPath = join( '/', ( $targetPath, $subPath ) );
		mkdir $subTargetPath or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't mkdir $subTargetPath ($?:$!) \n} );
		SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );
	}

	$options->{path} = $targetPath;

	if ( defined( $gaVersion ) ) {
		$options->{gaKitsPath} = join( '/', ( $targetPath, $gaKitsTargetPath ) );
	} else {
		$options->{gaKitsPath} = undef;
	}

}

sub fetchBuildProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $build     = $options{build};
	my $path      = $options{path};
	my $product   = $options{product};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $userName = $options{userName};
	my $host     = $SIOS::BuildVars::build{source}{host};
	my $base     = $SIOS::BuildVars::build{source}{base};

	my $isoPath  = $SIOS::BuildVars::build{setup}{isoPath};
	my $kitsPath = $SIOS::BuildVars::build{setup}{kitsPath};

	my $isoImage = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image};

	my $scpCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{scpCmd};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{FETCH PRODUCT BUILD ... \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{FETCH $product ISO IMAGE $isoImage ($base/$version/$build/$product/*) ... \n} );
	system( qq{$scpCmd $userName\@$host:$base/$version/$build/$product/* $path/$isoPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't fetch the ISO ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print', qq{completed \n} );

	### !!! May be special case for SAP till after certfication - currently NO kits in build dirs for 7.5.1
	return if ( $product eq 'sap' );

	if ( defined( $SIOS::CommonVars::product{$product}{gaKits} ) and $SIOS::CommonVars::product{$product}{gaKits} eq $version ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{FETCH BUILD KITS ($base/$version/$build/$kitsPath/*) ... \n} );
		system( qq{$scpCmd $userName\@$host:$base/$version/$build/$kitsPath/* $path/$kitsPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't fetch the KITS ($?:$!) \n} );
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print', qq{completed \n} );
	}

}

sub fetchGaKits ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $path      = $options{gaKitsPath};
	my $product   = $options{product};
	my $gaVersion = $options{gaVersion};
	my $verbosity = $options{verbosity};

	my $userName = $options{userName};
	my $host     = $SIOS::BuildVars::build{ga}{host};
	my $base     = $SIOS::BuildVars::build{ga}{base};
	my $subDir   = $SIOS::BuildVars::build{ga}{subDir};
	my $arks     = $SIOS::BuildVars::build{ga}{arks};

	return if ( !defined( $gaVersion ) );

	my $core = '';

	if ( $SIOS::BuildVars::build{ga}{core}{$gaVersion} ne '' ) {
		$core = '/' . $SIOS::BuildVars::build{ga}{core}{$gaVersion};
	} elsif ( !defined $SIOS::BuildVars::build{ga}{core}{$gaVersion} ) {
		$core = '/' . $SIOS::BuildVars::build{ga}{core}{previous};
	}

	my $scpCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{scpCmd};

	if ( $SIOS::CommonVars::product{$product}{gaKits} ) {
		foreach my $kitVersion ( @{ $SIOS::CommonVars::product{$product}{gaKits} } ) {
			if ( $kitVersion eq $gaVersion ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{FETCH GA KITS ($base/$gaVersion/$subDir/$arks) ... \n} );
				system( qq{$scpCmd $userName\@$host:"$base/$gaVersion/$subDir/$arks" $path/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch the GA KITS ($?:$!) \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{completed \n} );
			}
		}
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{FETCH GA ISO ($base/$gaVersion/$subDir$core) ... \n} );
	system( qq{$scpCmd $userName\@$host:"$base/$gaVersion/$subDir$core" $path/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch the GA ISO ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{completed \n} );

}

sub fetchLicenses ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $build       = $options{build};
	my $licEvalDays = $options{licEvalDays};
	my $path        = $options{path};
	my $product     = $options{product};
	my $verbosity   = $options{verbosity};
	my $version     = $options{version};

	return if ( !defined( $SIOS::BuildVars::build{licenses}{$product}{corePath} ) and !defined( $SIOS::BuildVars::build{licenses}{$product}{kitsPath} ) );

	my $userName = $options{userName};
	my $host     = $SIOS::BuildVars::build{licenses}{host};
	my $base     = $SIOS::BuildVars::build{licenses}{base};
	my $licPath  = $path . '/' . $SIOS::BuildVars::build{setup}{licPath};

	my $scpCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{scpCmd};

	my $licSourcePath;
	my $licSourceKitsPath;

	$licSourcePath     = qq{$base/$licEvalDays/} . $SIOS::BuildVars::build{licenses}{$product}{corePath} if ( defined( $SIOS::BuildVars::build{licenses}{$product}{corePath} ) );
	$licSourceKitsPath = qq{$base/$licEvalDays/} . $SIOS::BuildVars::build{licenses}{$product}{kitsPath} if ( defined( $SIOS::BuildVars::build{licenses}{$product}{kitsPath} ) );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{FETCH ($licEvalDays) DAY EVALUATION LICENSES $licSourcePath, $licSourceKitsPath ... \n} );

	system( qq{$scpCmd $userName\@$host:"$licSourcePath $licSourceKitsPath" $licPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't fetch the licenses ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{completed \n} );

}

sub mountProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action     = 'MOUNTING PRODUCT SETUP ISO IMAGE';
	my $mountPoint = $options{mountPoint};
	my $path       = $options{path};
	my $product    = $options{product};
	my $setup      = $options{setup};
	my $verbosity  = $options{verbosity};
	my $version    = $options{version};

	my $isoPath = $SIOS::BuildVars::build{setup}{isoPath};

	my $isoImage = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image};

	my $dfCmd     = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{dfCmd};
	my $mountCmd  = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{mountCmd};
	my $umountCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{umountCmd};

	unless ( $setup ) {

		#print "$parentCaller\t::SKIP:: $action ...\n";
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action $isoImage to $mountPoint ... \n} );

	if ( -e $mountPoint ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{MOUNT POINT EXISTS ... } );
		my $chkMount = qx{$dfCmd};
		if ( $chkMount =~ /$mountPoint/ ) {
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{PREVIOUSLY MOUNTED; UNMOUNTING ... } );
			system( qq{$umountCmd $mountPoint$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $umountCmd $mountPoint ($?:$!) \n} );
		}
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
	} else {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{CREATING MOUNT POINT ... } );
		mkdir $mountPoint or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $mountCmd $mountPoint ($?:$!) \n} );
		SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{MOUNTING ISO IMAGE ... } );
	system( qq{$mountCmd $path/$isoPath/$isoImage $mountPoint$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't $mountCmd $path/$isoPath/$isoImage ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );

}

sub setupProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action     = 'RUNNING ISO IMAGE SETUP SCRIPT';
	my $mountPoint = $options{mountPoint};
	my $path       = $options{path};
	my $product    = $options{product};
	my $setup      = $options{setup};
	my $verbosity  = $options{verbosity};
	my $version    = $options{version};
	my $ySetup     = $options{ySetup};
	my $setupOpts  = '';

	my $setupScript = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{setup}{script};

	unless ( $setup ) {

		#print "$parentCaller\t::SKIP:: $action ...\n";
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	$setupOpts = '-y' if ( $ySetup );

	my $setupCmd = qq{$mountPoint/$setupScript $setupOpts};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{$action $setupCmd ... } );

	# Be quiet when requested and accepting defaults, except for SMC which requires admin prompts.
	if ( $setupOpts and $product ne 'smc' ) {
		$setupCmd .= $quietCmd;
	}

	system( qq{$setupCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: $setupScript $setupOpts FAILED ($?:$!) \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

}

sub setupKits ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action     = "INSTALL REQUESTED KITS";
	my $arks       = $options{arks};
	my $mountPoint = $options{mountPoint};
	my $path       = $options{path};
	my $gaKitsPath = $options{gaKitsPath};
	my $setup      = $options{setup};
	my $verbosity  = $options{verbosity};
	my $product    = $options{product};
	my $version    = $options{version};
	my $ySetup     = $options{ySetup};
	my $setupOpts  = '';

	my $buildKitsPath = join( '/', ( $path, $SIOS::BuildVars::build{setup}{kitsPath} ) );

	my $rpmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rpmCmd};

	my $setupScript = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{setup}{script};

	unless ( $setup ) {

		#print "$parentCaller\t::SKIP:: $action ...\n";
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	$setupOpts = '-y' if ( $ySetup );

	my $setupCmd = qq{$mountPoint/$setupScript $setupOpts -k};

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	# For enabling 'all' at a later time. CHECK IF gaKitsPath defined as gaVersion may not have been requested.
	#my @buildArks = <$buildKitsPath/*>;
	#my @gaArks    = <$gaKitsPath/*>;

	foreach my $kit ( @{$arks} ) {

		if ( $kit eq 'none' ) {

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{::SKIP:: $action ($kit)... \n} );
			last;

		} elsif ( $kit eq 'all' ) {

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{::SKIP:: $action ($kit) - NOT SUPPORTED YET ... \n} );
			last;

		} elsif ( $SIOS::ArkVars::type{$product}{$version}{setupKits}{$kit} ) {

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{($kit) ... } );
			system( qq{$setupCmd $SIOS::ArkVars::type{$product}{$version}{setupKits}{$kit} $quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: $setupCmd FAILED ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

		} else {

			my $arkName = $SIOS::BuildVars::build{default}{arkPrefix} . $SIOS::ArkVars::type{$product}{$version}{kits}{$kit} . '-*';

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{($kit) $arkName ... } );

			# Install build version first if there is a match. Otherwise grab from the ga kits versions.

			if ( -e "$buildKitsPath/$arkName" ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print', qq{Found in $buildKitsPath ... } );

				#system ( qq{$rpmCmd "$buildKitsPath/$arkName" $quietCmd} ) == 0 or SIOS::Logger::logIt ( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't $rpmCmd $kit ($?:$!) \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );
			} elsif ( -e "$gaKitsPath/$arkName" ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print', qq{Found in $gaKitsPath ... } );

				#system ( qq{$rpmCmd "$gaKitsPath/$arkName" $quietCmd} ) == 0 or SIOS::Logger::logIt ( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't $rpmCmd $kit ($?:$!) \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );
			} else {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{WARNING! :: NOT INSTALLED :: NOT FOUND in $buildKitsPath or $gaKitsPath\n} );
			}

		}

	}

}

sub preApplyEdits ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $editFile  = $options{preEditFile};
	my $action    = "PRE-APPLY ($editFile) EDITS";
	my $path      = $options{path};
	my $product   = $options{product};
	my $setup     = $options{setup};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	unless ( $editFile ) {
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	system( qq{$editFile $quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't apply the edit files ($editFile) ($?:$!) \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

}

sub postApplyEdits ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $editFile  = $options{postEditFile};
	my $action    = "POST-APPLY ($editFile) EDITS";
	my $path      = $options{path};
	my $product   = $options{product};
	my $setup     = $options{setup};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	unless ( $editFile ) {
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action ... \n} );

	system( qq{$editFile $quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't apply the edit files ($editFile) ($?:$!) \n} );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

}

sub copyLicenses ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $licEval     = $options{licEval};
	my $licEvalDays = $options{licEvalDays};
	my $licEvalKits = $options{licEvalKits};
	my $action      = "COPY ($licEvalDays) DAY EVALUATION LICENSES";
	my $path        = $options{path};
	my $product     = $options{product};
	my $setup       = $options{setup};
	my $verbosity   = $options{verbosity};
	my $version     = $options{version};

	return if ( !defined( $SIOS::BuildVars::build{licenses}{$product}{corePath} ) and !defined( $SIOS::BuildVars::build{licenses}{$product}{kitsPath} ) );

	my $licPath     = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{path}{license};
	my $licCorePath = $path . '/' . $SIOS::BuildVars::build{setup}{licPath} . '/' . $SIOS::BuildVars::build{licenses}{$product}{corePath};
	my $licKitsPath = $path . '/' . $SIOS::BuildVars::build{setup}{licPath} . '/' . $SIOS::BuildVars::build{licenses}{$product}{kitsPath};

	my $licCore = $SIOS::LicenseVars::type{$product}{$version}{core};

	my $cpCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{cpCmd};
	my $rmCmd = $SIOS::CommonVars::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	unless ( $licEval and $setup ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ...\n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$action to $licPath ... \n} );

	## CORE - Lic ----------------------------------------
	$action = 'COPY CORE LICENSES';

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'action', qq{$action $licCore* ... } );
	system( qq{$cpCmd $licCorePath/$licCore* $licPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'die', qq{ERROR: Couldn't copy $licCore* evaluation license ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'result', qq{completed \n} );

	## KIT - Lic ----------------------------------------
	$action = 'COPY KIT LICENSES';

	foreach my $licKit ( @{$licEvalKits} ) {

		if ( $licKit eq 'none' ) {

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{::SKIP:: $action ... \n} );
			last;

		} elsif ( $licKit eq 'all' ) {

			SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{$action ... \n} );

			foreach my $eachKit ( @{ $SIOS::LicenseVars::kitLicsList{$product}{$version} } ) {

				next if ( $eachKit eq 'all' or $eachKit eq 'none' );

				my $lic = $SIOS::LicenseVars::type{$product}{$version}{kits}{$eachKit};

				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'action', qq{$eachKit: $lic* ... } );
				system( qq{$cpCmd $licKitsPath/$lic* $licPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't copy $eachKit evaluation license ($?:$!) \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );

				## Handle vAppKeeper seperately since core/bundle are a bit different...
				if ( $product =~ /^vapp|lkssp$/ ) {
					SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print',  qq{KIT LICENSE $SIOS::CommonVars::product{$product}{name} REQUESTED. KIT $eachKit INCLUDES 'CORE' ... \n} );
					SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'action', qq{REMOVE $licCore ... } );
					system( qq{$rmCmd $licPath/$licCore*$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't $rmCmd $licPath/$licCore* ($?:$!) \n} );
					SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );
				}

			}

		} else {

			my $lic = $SIOS::LicenseVars::type{$product}{$version}{kits}{$licKit};

			SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'action', qq{$licKit: $lic* ... } );
			system( qq{$cpCmd $licKitsPath/$lic* $licPath/.$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't copy $licKit evaluation license ($?:$!) \n} );
			SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );

			## Handle vAppKeeper seperately since core/bundle are a bit different...
			if ( $product =~ /^vapp|lkssp$/ ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'print',  qq{KIT LICENSE $SIOS::CommonVars::product{$product}{name} REQUESTED. KIT $licKit INCLUDES 'CORE' ... \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 3, 'action', qq{REMOVE $licCore ... } );
				system( qq{$rmCmd $licPath/$licCore*$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'die', qq{ERROR: Couldn't $rmCmd $licPath/$licCore* ($?:$!) \n} );
				SIOS::Logger::logIt( $verbosity, $parentCaller, 4, 'result', qq{completed \n} );
			}

		}

	}

}

sub startProduct ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	my $action    = "START PRODUCT";
	my $product   = $options{product};
	my $setup     = $options{setup};
	my $start     = $options{start};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	my $startCmd = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start};

	unless ( $setup and $start ) {
		SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{::SKIP:: $action ... \n} );
		return;
	}

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'action', qq{$action $startCmd ... } );
	system( qq{$startCmd$quietCmd} ) == 0 or SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'die', qq{ERROR: Couldn't $action ($?:$!) \n} );
	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'result', qq{completed \n} );

}

## RUNNERS -------------------------------------------------------------

sub setup ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	$options{action} = 'SETUP';

	my $build     = $options{build};
	my $product   = $options{product};
	my $related   = $options{related};
	my $setup     = $options{setup};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	$quietCmd = '' if ( $verbosity > 1 );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$options{action} [$product - $SIOS::CommonVars::product{$product}{name} Version($version) Build($build)] ---------------------------------- \n} );

	confirmAction( %options );
	setBuildVersion( \%options );
	setBuildNumber( \%options );
	setGaVersion( \%options );
	makeSetupTarget( \%options );     # Depends setBuildNumber, setBuildVersion
	fetchBuildProduct( %options );    # Depends makeSetupTarget
	fetchGaKits( %options );          # Depends makeSetupTarget
	fetchLicenses( %options );        # Depends makeSetupTarget
	mountProduct( %options );         # Depends all previous
	setupProduct( %options );         # Depends mountProduct
	setupKits( %options );
	copyLicenses( %options );
	preApplyEdits( %options );
	startProduct( %options );
	postApplyEdits( %options );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$options{action} DONE !\n} );

}

sub erase ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( %options ) = %{ ( shift ) };

	#   confirmVersion ( \%options );

	$options{action} = 'ERASURE';

	my $product   = $options{product};
	my $related   = $options{related};
	my $verbosity = $options{verbosity};
	my $version   = $options{version};

	$quietCmd = '' if ( $verbosity > 1 );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$options{action} [$product - $SIOS::CommonVars::product{$product}{name} Version($version)] ---------------------------------- \n} );

	confirmVersion( \%options );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{WARNING: Does NOT remove \$HOME/.lifekeeper related dot files yet!! \n} );

	unless ( $related ) {
		my $relatedItems = $SIOS::CommonVars::product{$product}{$version}{$sysDistro}{$sysVersion}{$sysArch}{related};

		#print Dumper( $relatedItems );

		foreach my $itemCollection ( keys %$relatedItems ) {
			my $rItems = $relatedItems->{$itemCollection};
			foreach my $item ( keys %$rItems ) {
				SIOS::Logger::logIt( $verbosity, $parentCaller, 2, 'print', qq{NOTE: Not erasing related [$itemCollection] item [$item ($rItems->{$item}\*)] ! \n} );
			}
		}
	}

	confirmAction( %options );
	backupProduct( %options );
	stopProduct( %options );
	killProcesses( %options );
	removeRelatedOther( %options );
	removeRpms( %options );
	removeRelatedRpms( %options );
	removeFiles( %options );
	removeLinks( %options );
	removePaths( %options );
	removeUsers( %options );
	removeGroups( %options );
	postCommands( %options );

	SIOS::Logger::logIt( $verbosity, $parentCaller, 1, 'print', qq{$options{action} DONE ! \n} );

}

1;

#!/usr/bin/perl

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

BEGIN { @INC = ( "/opt/fvorge/lib/perl", "../lib/perl", @INC ); }

use strict;
use warnings;

#use Switch;
use Getopt::Long;
use File::Path;
use Pod::Usage;

use SIOS::Product;

my @useError     = ();
my @arks         = $SIOS::BuildVars::build{default}{arks};
my $build        = $SIOS::BuildVars::build{default}{build};
my $confirm      = 1;
my $gaVersion    = undef;
my $help         = 0;
my $licEval      = 1;
my $licEvalDays  = $SIOS::BuildVars::build{licEval}{default}{days};
my @licEvalKits  = $SIOS::BuildVars::build{licEval}{default}{kits};
my $man          = 0;
my $mountPoint   = $SIOS::BuildVars::build{setup}{mountPoint};
my $overwrite    = 1;
my $path         = $SIOS::BuildVars::build{setup}{path};
my $postEditFile = 0;
my $preEditFile  = 0;
my $product      = $SIOS::CommonVars::productDefault{product};
my $setup        = 1;
my $start        = 1;
my $userName     = $SIOS::BuildVars::build{scp}{userName};
my $verbosity    = 1;
my $version      = $SIOS::BuildVars::build{default}{version};
my $ySetup       = 1;
my %options      = ();

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'arks|a=s{,}'        => \@arks,
	'build|b=i'          => \$build,
	'confirm|c!'         => \$confirm,
	'gaversion|ga=s'     => \$gaVersion,
	'help|h'             => \$help,
	'liceval|e!'         => \$licEval,
	'licevaldays|d=i'    => \$licEvalDays,
	'licevalkits|k=s{,}' => \@licEvalKits,
	'man|m'              => \$man,
	'mountpoint|mp=s'    => \$mountPoint,
	'overwrite|o!'       => \$overwrite,
	'path|t=s'           => \$path,
	'postedits|post=s'   => \$postEditFile,
	'preedits|pre=s'     => \$preEditFile,
	'product|p=s'        => \$product,
	'setup|s!'           => \$setup,
	'start|x!'           => \$start,
	'username|u=s'       => \$userName,
	'verbosity|n=i'      => \$verbosity,
	'version|v=s'        => \$version,
	'ysetup|y!'          => \$ySetup
) or pod2usage( 2 );

pod2usage( 1 ) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

## HANDLE 'licEvalKit' quirks ---------------------------
# Getopt::Long doesn't overwrite a set array.
# POP off the 'default' value if provided additional kit lics
shift( @licEvalKits ) if ( scalar( @licEvalKits ) > 1 );

# Set 'unique' values
my %licEvalKits;
foreach my $licKit ( @licEvalKits ) {
	$licEvalKits{$licKit}++;
}

## HANDLE 'arks' quirks ---------------------------
# Getopt::Long doesn't overwrite a set array.
# POP off the 'default' value if provided additional kits
shift( @arks ) if ( scalar( @arks ) > 1 );

# Set 'unique' values
my %arks;
foreach my $kit ( @arks ) {
	$arks{$kit}++;
}

## PARSE Command Options --------------------------------
if ( $postEditFile and ( !-f $postEditFile or !-x $postEditFile ) ) {
	push( @useError, "--postedits $postEditFile doesn't exist or isn't executable!\n" );
}

if ( $preEditFile and ( !-f $preEditFile or !-x $preEditFile ) ) {
	push( @useError, "--preedits $preEditFile doesn't exist or isn't executable!\n" );
}

if ( $licEvalDays !~ /$SIOS::BuildVars::buildLicEvalDaysRegexPattern/ ) {
	push( @useError, "--licevaldays # $SIOS::BuildVars::buildLicEvalDaysHelp required ! : Got ($licEvalDays)\n" );
}

if ( $product !~ /$SIOS::CommonVars::productRegex/ ) {
	push( @useError, "--product $SIOS::CommonVars::productHelp required ! : Got ($product)\n" );
}

if ( $licEvalKits{all} and $licEvalKits{none} ) {
	push( @useError, "--licevalkits all|none|KITS ! : Got (all AND none)\n" );
} elsif ( $licEvalKits{none} and scalar( keys %licEvalKits ) > 1 ) {
	push( @useError, "--licevalkits all|none|KITS ! : Got (none PLUS KITS)\n" );
} else {
	my $licKitList = $SIOS::LicenseVars::kitLicsList{$product}{$version};
	foreach my $licKit ( keys %licEvalKits ) {
		if ( scalar( grep ( /^$licKit$/, @{$licKitList} ) ) < 1 ) {
			push( @useError, "--licevalkits [" . join( ' ', @{$licKitList} ) . "] valid for product '$product' ! : Got ($licKit)\n" );
		}
	}
}

if ( $arks{all} and $arks{none} ) {
	push( @useError, "--arks all|none|KITS ! : Got (all AND none)\n" );
} elsif ( $arks{none} and scalar( keys %arks ) > 1 ) {
	push( @useError, "--arks all|none|KITS ! : Got (none PLUS KITS)\n" );
} else {
	my $arksList = $SIOS::ArkVars::kitList{$product}{$version};
	foreach my $kit ( keys %arks ) {
		next if ( $kit eq 'all' or $kit eq 'none' );
		if ( scalar( grep ( /^$kit$/, @{$arksList} ) ) < 1 ) {
			push( @useError, "--arks [" . join( ' ', @{$arksList} ) . "] valid for product '$product' ! : Got ($kit)\n" );
		}
	}
}

if ( $version !~ /$SIOS::CommonVars::product{$product}{versionsRegexPattern}/ ) {
	push( @useError, "--version #.#.# required. $SIOS::CommonVars::product{$product}{versionsHelp} valid for product '$product' ! : Got ($version)\n" );
}

if (defined( $gaVersion ) and  $gaVersion !~ /$SIOS::CommonVars::product{$product}{versionsRegexPattern}/ ) {
	push( @useError, "--gaversion #.#.# required. $SIOS::CommonVars::product{$product}{versionsHelp} valid for product '$product' ! : Got ($gaVersion)\n" );
}

if ( $build !~ /$SIOS::BuildVars::buildRegexPattern/ ) {
	push( @useError, "--build # required. $SIOS::BuildVars::buildHelp valid for product '$product' ! : Got ($build)\n" );
}

# SMC starts the service during the installation. Starting up the app is redundant.
if ( $start and $product =~ /^smc$/ ) {
	$start = 0;
}

pod2usage( @useError ) if @useError;

$options{arks}         = [ keys %arks ];
$options{build}        = $build;
$options{confirm}      = $confirm;
$options{gaVersion}    = $gaVersion;
$options{licEval}      = $licEval;
$options{licEvalDays}  = $licEvalDays;
$options{licEvalKits}  = [ keys %licEvalKits ];
$options{mountPoint}   = $mountPoint;
$options{overwrite}    = $overwrite;
$options{path}         = $path;
$options{postEditFile} = $postEditFile;
$options{preEditFile}  = $preEditFile;
$options{product}      = $product;
$options{setup}        = $setup;
$options{start}        = $start;
$options{userName}     = $userName;
$options{verbosity}    = $verbosity;
$options{version}      = $version;
$options{ySetup}       = $ySetup;

## ERASE -------------------------------------------
SIOS::Product::setup( %options );

1;

__END__

=head1 NAME

SIOS Product SETUP

=head1 SYNOPSIS

sp-setup [--product|-p PRODUCT_NAME] [--version|-v #.#.#|latest] [--build|-b #|latest] [--gaversion|-ga #.#.#|latest] [--arks|-a none|KIT_LIST] [--username|-u USERNAME] [--path|-t SETUP_PATH] [--no-confirm|-no-c] [--licevaldays|-d #] [--licevalkits|-k all|none|KIT_LIC_LIST] [--no-liceval|-no-e] [--no-overwrite|-no-o] [--no-setup|-no-s] [--no-ysetup|-no-y] [--no-start|-no-x] [--preedits|-pre EXEC_FILE] [--postedits|-post EXEC_FILE] [--mountpoint|-mp MOUNT_PATH] [--verbosity|-n #] [--help|-h] [--man|-m]

=head1 OPTIONS

=over 8

=item B<--product|-p PRODUCT_NAME>

The SIOS product to fetch and setup. Either 'sps' (SteelEye Protection Suite), 'smc' (SteelEye Management Console) or 'lkssp' (Life Keeper Single Server Protection), etc. Defaults to SIOS::CommonVars::productDefault{product}

=item B<--version|-v #.#.#|latest>

Identify a specific version to fetch. #.#.# eg. 7.5.0 Defaults to latest version number -OR- SIOS::CommonVars::productDefault{version}

=item B<--build|-b #|latest>

Identify a specific build number. Defaults to latest build number.

=item B<--preedits|-pre EXEC_FILE>

Execute an edit file after installation but before product start. EXEC_FILE must exist and be executable. eg. '#!/bin/bash echo INTERFACELIST=se0 >> /etc/default/LifeKeeper'

=item B<--postedits|-post EXEC_FILE>

Execute an edit file after installation and product start. EXEC_FILE must exist and be executable. eg. '#!/bin/bash /opt/LifeKeeper/bin/lk_confrimso -n system'

=item B<--gaversion|-ga #.#.#|latest>

Identify a specific GA version to fetch KITS. #.#.# eg. 7.5.0 Defaults to latest version number -OR- SIOS::CommonVars::productDefault{version}

=item B<--arks|-a none|KIT_LIST>

Request application resource kits to install. May specify 'none' or some combination of product kits.
eg. sap oracle dmmp postgres ip gui ... | none. Defaults to SIOS::BuildVars::build{default}{arks}.

=item B<--path|-t SETUP_PATH>

Identify an alternate path path. eg. /root. Defaults to SIOS::BuildVars::build{setup}{path}

=item B<--username|-u USERNAME>

Identify an alternate scp username. Defaults to SIOS::BuildVars::build{scp}{userName}

=item B<--no-confirm|-no-c>

Disable confirmation before continuing the setup process. Default is to prompt for confirmation before continuing.

=item B<--licevaldays|-d #>

Request evaluation licenses with a specific term. Defaults to SIOS::BuildVars::build{licEval}{default}{days}

=item B<--licevalkits|-k all|none|KIT_LIC_LIST>

Request specific evaluation kit licenses. May specify 'all', 'none' or some combination of product kit licenses.
eg. sap oracle ... | all | none. Defaults to SIOS::BuildVars::build{licEval}{default}{kits}. Available evaluation kit licenses defined in SIOS::LicenseVars::{type}{'product'}{kits} 

=item B<--no-liceval|-no-e>

Bypass installation of product evaluation licenses. Default action is to install them after the product setup is complete.
If not installed, they should be stored in SETUP_PATH/licenses.

=item B<--no-overwrite|-no-o>

Bypass overwrite of any existing material. Default action is to overwrite any existing material.

=item B<--no-setup|-no-s>

Bypass mounting the setup image and running product setup. Default action is to mount the image and run the product setup.

=item B<--no-ysetup|-no-y>

Disable running product setup while accpting defaults; '-y'. Defaults to providing '-y' to the setup script.

=item B<--no-start|-no-x>

Start the product after setup is completed. Default action is to complete setup and start of the product. If product 'smc' requested --start will be unset as the product setup automatically starts the product.

=item B<--mountpoint|-mp MOUNT_PATH>

Designate a specific mount point where the product setup image is mounted and executed. Default is to use the SIOS::BuildVars::build{setup}{mountPoint} setting.

=item B<--verbosity|-n #>

Set a specific verbosity level. Default is 1 and surpresses STDOUT and STDERR. To disable ALL messaging set to 0.

=item B<--help|-h>

Print help and exit.

=item B<--man|m>

Print detailed man style information and exit.

=cut


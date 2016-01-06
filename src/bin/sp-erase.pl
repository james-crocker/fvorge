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

my @useError  = ();
my $allrpm    = 0;
my $backup    = 1;
my $confirm   = 1;
my $force     = 0;
my $groups    = 1;
my $help      = 0;
my $man       = 0;
my $post      = 1;
my $product   = $SIOS::CommonVars::productDefault{product};
my $related   = 1;
my $users     = 1;
my $verbosity = 1;
my $version   = $SIOS::CommonVars::productDefault{version};
my %options   = ();

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'allrpm|a'      => \$allrpm,
	'backup|b!'     => \$backup,
	'confirm|c!'    => \$confirm,
	'force|f'       => \$force,
	'groups|g!'     => \$groups,
	'help|h'        => \$help,
	'man|m'         => \$man,
	'post|x!'       => \$post,
	'product|p=s'   => \$product,
	'related|r!'    => \$related,
	'users|u!'      => \$users,
	'verbosity|n=i' => \$verbosity,
	'version|v=s'   => \$version
) or pod2usage( 2 );

pod2usage( 1 ) if $help;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

## PARSE Command Options --------------------------------
if ( $product !~ /$SIOS::CommonVars::productRegex/ ) {
	push( @useError, "--product $SIOS::CommonVars::productHelp required ! : Got ($product)\n" );
}
if ( $version !~ /$SIOS::CommonVars::product{$product}{versionsRegexPattern}/ ) {
	push( @useError, "--version #.#.# required. $SIOS::CommonVars::product{$product}{versionsHelp} valid for product '$product' ! : Got ($version)\n" );
}

pod2usage( @useError ) if @useError;

$options{allrpm}    = $allrpm;
$options{backup}    = $backup;
$options{confirm}   = $confirm;
$options{force}     = $force;
$options{groups}    = $groups;
$options{post}      = $post;
$options{product}   = $product;
$options{related}   = $related;
$options{users}     = $users;
$options{verbosity} = $verbosity;
$options{version}   = $version;

## ERASE -------------------------------------------
SIOS::Product::erase( %options );

1;

__END__

=head1 NAME

SIOS Product ERASE

=head1 SYNOPSIS

sp-erase [--product|-p PRODUCT_NAME] [--no-backup|-no-b] [--no-confirm|-no-c] [--no-related|-no-r] [--force|-f] [--version|-v #.#.#|latest] [--verbosity|-n #] [--help|-h] [--man|-m]

=head1 OPTIONS

=over 8

=item B<--product|-p PRODUCT_NAME>

The SIOS product to fetch and setup. Either 'sps' (SteelEye Protection Suite), 'smc' (SteelEye Management Console) or 'lkssp' (Life Keeper Single Server Protection), etc. Defaults to SIOS::CommonVars::productDefault{product}

=item B<--force|-f>

Override 'nice' attempt to erase the SIOS products in an orderly fashion. Default is to attempt 'nice' erasure.

=item B<--no-groups|-no-g>

Bypass removing LK Groups from system credentials.

=item B<--no-backup|-no-b>

Bypass backup of the product. Default is to backup currently installed product.

=item B<--no-confirm|-no-c>

Disable confirmation of erasure action. Default is to prompt for confirmation before continuing.

=item B<--no-related|-no-r>

Bypass erasure of related RPM packages particular to the selected product. ie. pdksh, jre. Default is to remove SIOS product related RPM pacakages.

=item B<--no-users|-no-u>

Bypass erasure of LK Users from system credentials.

=item B<--no-post|-no-x>

Bypass execution of any post process commands.

=item B<--allrpm|-a>

Remove all product related RPM's.

=item B<--version|-v #.#.#|latest>

Identify a specific version to erase. #.#.# eg. 7.5.0 OR 'latest'. Defaults to SIOS::CommonVars::productDefault{version}. If 'latest' then attempts to get version from RPM's installed. If that can't be determined then it defaults to the highest number in the supported product version matrix.

=item B<--verbosity|-n #>

Set a specific verbosity level. Default is 1 and supreses STDOUT and STDERR. To disable ALL messaging set to 0. 

=item B<--help|-h>

Print help and exit.

=item B<--man|m>

Print detailed man style information and exit.

=cut


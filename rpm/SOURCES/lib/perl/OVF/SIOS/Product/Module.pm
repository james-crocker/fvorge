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

package OVF::SIOS::Product::Module;

use strict;
use warnings;

use lib '../../../../perl';
use OVF::Manage::Tasks;
use OVF::SIOS::Product::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action  = $thisSubName;
	my $arch    = $options{ovf}{current}{'host.architecture'};
	my $distro  = $options{ovf}{current}{'host.distribution'};
	my $major   = $options{ovf}{current}{'host.major'};
	my $minor   = $options{ovf}{current}{'host.minor'};
	my $product = $options{ovf}{current}{'sios.product'};

	my $propertySetup     = 'sios.setup';
	my $propertySetupArgs = 'sios.setup-args';
	my $propertyProduct   = 'sios.product';

	if ( !defined $options{ovf}{current}{$propertySetup} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $propertySetup undefined} );
		return;
	}

	if ( !defined $OVF::SIOS::Product::Vars::product{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( !defined $options{ovf}{current}{$propertyProduct} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $propertyProduct undefined} );
		return;
	}

	if ( !OVF::State::ovfIsChanged( $propertySetup, %options ) and !OVF::State::ovfIsChanged( $propertySetupArgs, %options ) and !OVF::State::ovfIsChanged( $propertyProduct, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $propertyProduct and $propertySetup and $propertySetupArgs same as Previous properties} );
		return;
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ($product) ...} );
		if ( $options{ovf}{current}{$propertySetup} ) {

			if ( exists $options{ovf}{previous} and defined $options{ovf}{previous}{$propertyProduct} and OVF::State::ovfIsChanged( 'sios.*', %options ) ) {
				erase( 'previous', \%options );
			}

			setup( \%options );
		} else {
			erase( 'current', \%options );
		}
	}

}

sub setup ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action  = $thisSubName;
	my $arch    = $options{ovf}{current}{'host.architecture'};
	my $distro  = $options{ovf}{current}{'host.distribution'};
	my $major   = $options{ovf}{current}{'host.major'};
	my $minor   = $options{ovf}{current}{'host.minor'};
	my $product = $options{ovf}{current}{'sios.product'};
	my $sargs   = $options{ovf}{current}{'sios.setup-args'};

	my %productVars = %{ $OVF::SIOS::Product::Vars::product{$distro}{$major}{$minor}{$arch} };

	my $required        = [ 'sios.product' ];
	my $requiredEnabled = [ 'sios.setup-args' ];
	return if ( OVF::State::checkRequired( $action, $required, 'sios.product.setup', $requiredEnabled, %options ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($product) ...} );

	$productVars{task}{setup}[ 0 ] =~ s/<SIOS_PRODUCT>/$product/;
	$productVars{task}{setup}[ 0 ] =~ s/<SIOS_SETUP_ARGS>/$sargs/;

	OVF::Manage::Tasks::run( %options, @{ $productVars{task}{setup} } );
	OVF::Manage::Files::create( %options, %{ $productVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub erase ( $\% ) {

	my $level = shift;
	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];
	my $action      = $thisSubName;
	my $arch        = $options{ovf}{current}{'host.architecture'};
	my $distro      = $options{ovf}{current}{'host.distribution'};
	my $major       = $options{ovf}{current}{'host.major'};
	my $minor       = $options{ovf}{current}{'host.minor'};
	my $product     = $options{ovf}{$level}{'sios.product'};
	my $sargs       = $options{ovf}{current}{'sios.erase-args'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %productVars = %{ $OVF::SIOS::Product::Vars::product{$distro}{$major}{$minor}{$arch} };

	# sios.erase-args can be '' (and likely should be)so don't check for it.
	my $required        = [ 'sios.product' ];
	my $requiredEnabled = [];
	return if ( OVF::State::checkRequired( $action, $required, '', $requiredEnabled, %options ) );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($product) ...} );

	$productVars{task}{erase}[ 0 ] =~ s/<SIOS_PRODUCT>/$product/;
	$productVars{task}{erase}[ 0 ] =~ s/<SIOS_ERASE_ARGS>/$sargs/;

	OVF::Manage::Tasks::run( %options, @{ $productVars{task}{erase} } );
	OVF::Manage::Files::destroy( %options, %{ $productVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

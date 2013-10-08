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

package OVF::SIOS::Automation::Module;

use strict;
use warnings;

use lib '../../../../perl';
use OVF::Manage::Files;
use OVF::Manage::Init;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::Manage::Users;
use OVF::SIOS::Automation::Vars;
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

	my $propertySetup   = 'sios.automation.setup';
	my $propertyProduct = 'sios.product';

	if ( !defined $options{ovf}{current}{$propertyProduct} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $propertyProduct undefined} );
		return;
	}

	if ( !defined $OVF::SIOS::Automation::Vars::automate{$distro}{$major}{$minor}{$arch}{$product} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( !defined $options{ovf}{current}{$propertySetup} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $propertySetup undefined} );
		return;
	}

	if ( !OVF::State::ovfIsChanged( $propertySetup, %options ) and !OVF::State::ovfIsChanged( $propertyProduct, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $propertyProduct and $propertySetup same as Previous properties} );
		return;
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ($product) ...} );
		if ( $options{ovf}{current}{$propertySetup} ) {
			setup( \%options );
		} else {
			erase( \%options );
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

	my %productVars = %{ $OVF::SIOS::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} };

	my @required = ( 'sios.product' );
	my $halt     = 0;
	foreach my $reqProperty ( @required ) {
		if ( !$options{ovf}{current}{$reqProperty} ) {
			Sys::Syslog::syslog( 'err', qq{Missing required parameter: $reqProperty} );
			$halt = 1;
		}
	}
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP::} ) and return ) if ( $halt );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($product) ...} );

	my $source       = $productVars{$product}{mount}{source};
	my $target       = $productVars{$product}{mount}{target};
	my $fstype       = $productVars{$product}{mount}{fstype};
	my $fstaboptions = $productVars{$product}{defaults}{fstabOptions};

	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_DEVICE>/$source/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_PATH>/$target/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_FS_TYPE>/$fstype/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_FSTAB_OPTIONS>/$fstaboptions/;

	OVF::Manage::Users::create( %options, %{ $productVars{$product}{users} } );
	OVF::Manage::Files::create( %options, %{ $productVars{$product}{files} } );
	OVF::Manage::Init::enable( %options, %{ $productVars{$product}{init} } );
	OVF::Manage::Storage::mount( %options, %{ $productVars{$product}{mount} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub erase ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action  = $thisSubName;
	my $arch    = $options{ovf}{current}{'host.architecture'};
	my $distro  = $options{ovf}{current}{'host.distribution'};
	my $major   = $options{ovf}{current}{'host.major'};
	my $minor   = $options{ovf}{current}{'host.minor'};
	my $product = $options{ovf}{current}{'sios.product'};
	my $sargs   = $options{ovf}{current}{'sios.erase-args'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %productVars = %{ $OVF::SIOS::Automation::Vars::automate{$distro}{$major}{$minor}{$arch} };

	my @required = ( 'sios.product' );
	my $halt     = 0;
	foreach my $reqProperty ( @required ) {
		if ( !$options{ovf}{current}{$reqProperty} ) {
			Sys::Syslog::syslog( 'err', qq{Missing required parameter: $reqProperty} );
			$halt = 1;
		}
	}
	( Sys::Syslog::syslog( 'err', qq{$action ::SKIP::} ) and return ) if ( $halt );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($product) ...} );

	my $source       = $productVars{$product}{mount}{source};
	my $target       = $productVars{$product}{mount}{target};
	my $fstype       = $productVars{$product}{mount}{fstype};
	my $fstaboptions = $productVars{$product}{defaults}{fstabOptions};

	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_DEVICE>/$source/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_PATH>/$target/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_FS_TYPE>/$fstype/;
	$productVars{$product}{files}{fstab}{apply}{1}{content} =~ s/<FS_FSTAB_OPTIONS>/$fstaboptions/;

	OVF::Manage::Storage::umount( %options, %{ $productVars{$product}{mount} } );
	OVF::Manage::Init::disable( %options, %{ $productVars{$product}{init} } );
	OVF::Manage::Files::destroy( %options, %{ $productVars{$product}{files} } );
	OVF::Manage::Users::destroy( %options, %{ $productVars{$product}{users} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

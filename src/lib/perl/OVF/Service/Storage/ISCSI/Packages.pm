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

package OVF::Service::Storage::ISCSI::Packages;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Packages;
use OVF::Service::Storage::ISCSI::Vars;
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

	my $property = 'service.storage.iscsi.packages';

	if ( !defined $OVF::Service::Storage::ISCSI::Vars::iscsi{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( !defined $options{ovf}{current}{$property} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $property undefined} );
		return;
	}

	if ( !OVF::State::ovfIsChanged( $property, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $property same as Previous property} );
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ...} );
		if ( $options{ovf}{current}{$property} ) {
			install( \%options );
		} else {
			remove( \%options );
		}
	}

}

sub install ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %iscsiVars = %{ $OVF::Service::Storage::ISCSI::Vars::iscsi{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ... } );

	OVF::Manage::Packages::install( %options, @{ $iscsiVars{packages} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub remove ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %iscsiVars = %{ $OVF::Service::Storage::ISCSI::Vars::iscsi{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ... } );

	OVF::Manage::Packages::remove( %options, @{ $iscsiVars{packages} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}
1;

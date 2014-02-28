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

package OVF::Service::Security::PAM::LDAP::Packages;

use strict;
use warnings;

use lib '../../../../../../perl';
use OVF::Manage::Packages;
use OVF::Service::Security::PAM::LDAP::Vars;
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

	my $property = 'service.security.pam.ldap.packages';

	if ( !defined $OVF::Service::Security::PAM::LDAP::Vars::pam{$distro}{$major}{$minor}{$arch} ) {
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

	my $action     = $thisSubName;
	my $arch       = $options{ovf}{current}{'host.architecture'};
	my $distro     = $options{ovf}{current}{'host.distribution'};
	my $major      = $options{ovf}{current}{'host.major'};
	my $minor      = $options{ovf}{current}{'host.minor'};
	my $packages32 = $options{ovf}{current}{'service.security.pam.ldap.packages-32bit'};

	my %pamVars = %{ $OVF::Service::Security::PAM::LDAP::Vars::pam{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE 64bit ... } );
	OVF::Manage::Packages::install( %options, @{ $pamVars{packages} } );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE 64bit} );

	if ( $packages32 ) {
		Sys::Syslog::syslog( 'info', qq{$action INITIATE 32bit ... } );
		OVF::Manage::Packages::install( %options, @{ $pamVars{'packages-32bit'} } );
		Sys::Syslog::syslog( 'info', qq{$action COMPLETE 32bit} );
	}

}

sub remove ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action     = $thisSubName;
	my $arch       = $options{ovf}{current}{'host.architecture'};
	my $distro     = $options{ovf}{current}{'host.distribution'};
	my $major      = $options{ovf}{current}{'host.major'};
	my $minor      = $options{ovf}{current}{'host.minor'};
	my $packages32 = $options{ovf}{current}{'service.security.pam.ldap.packages-32bit'};

	( Sys::Syslog::syslog( 'info', qq{::SKIP:: $action SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %pamVars = %{ $OVF::Service::Security::PAM::LDAP::Vars::pam{$distro}{$major}{$minor}{$arch} };

	if ( $packages32 ) {
		Sys::Syslog::syslog( 'info', qq{$action INITIATE 32bit ... } );
		OVF::Manage::Packages::remove( %options, @{ $pamVars{'packages-32bit'} } );
		Sys::Syslog::syslog( 'info', qq{$action COMPLETE 32bit} );
	}

	Sys::Syslog::syslog( 'info', qq{$action INITIATE 64bit ... } );
	OVF::Manage::Packages::remove( %options, @{ $pamVars{packages} } );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE 64bit} );

}

1;

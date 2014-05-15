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

package OVF::Service::Security::PAM::LDAP::Module;

use strict;
use warnings;

use lib '../../../../../../perl';
use OVF::Manage::Tasks;
use OVF::Service::Security::PAM::LDAP::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property = 'service.security.pam.ldap.enabled';

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
			enable( \%options );
		} else {
			disable( \%options );
		}
	}

}

sub enable ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my %pamVars = %{ $OVF::Service::Security::PAM::LDAP::Vars::pam{$distro}{$major}{$minor}{$arch} };

	my $required = [];
	my $requiredEnabled = [ 'service.security.pam.ldap.server', 'service.security.pam.ldap.basedn' ];
	return if ( OVF::State::checkRequired( $action, $required, 'service.security.pam.ldap.enabled', $requiredEnabled, %options ) );

	if ( $distro eq 'Ubuntu' ) {
		
		if ( !defined $options{ovf}{current}{'service.security.pam.ldap.rootbindpw'} ) {
			$options{ovf}{current}{'service.security.pam.ldap.rootbindpw'} = '';
		}
		if ( !defined $options{ovf}{current}{'service.security.pam.ldap.rootbinddn'} ) {
			$options{ovf}{current}{'service.security.pam.ldap.rootbinddn'} = '';
		}
		if ( !defined $options{ovf}{current}{'service.security.pam.ldap.binddn'} ) {
			$options{ovf}{current}{'service.security.pam.ldap.binddn'} = '';
		}

		$pamVars{files}{'ldap-auth-config'}{apply}{1}{content} =~ s/<LDAP_SERVER>/$options{ovf}{current}{'service.security.pam.ldap.server'}/;
		$pamVars{files}{'ldap-auth-config'}{apply}{1}{content} =~ s/<LDAP_BASEDN>/$options{ovf}{current}{'service.security.pam.ldap.basedn'}/;
		$pamVars{files}{'ldap-auth-config'}{apply}{1}{content} =~ s/<LDAP_ROOTBINDPW>/$options{ovf}{current}{'service.security.pam.ldap.rootbindpw'}/;
		$pamVars{files}{'ldap-auth-config'}{apply}{1}{content} =~ s/<LDAP_ROOTBINDDN>/$options{ovf}{current}{'service.security.pam.ldap.rootbinddn'}/;
		$pamVars{files}{'ldap-auth-config'}{apply}{1}{content} =~ s/<LDAP_BINDDN>/$options{ovf}{current}{'service.security.pam.ldap.binddn'}/;
	} else {
		$pamVars{task}{enable}[ 0 ] =~ s/<LDAP_SERVER>/$options{ovf}{current}{'service.security.pam.ldap.server'}/;
		$pamVars{task}{enable}[ 0 ] =~ s/<LDAP_BASEDN>/$options{ovf}{current}{'service.security.pam.ldap.basedn'}/;
	}

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	if ( $pamVars{files} ) {
		OVF::Manage::Files::create( %options, %{ $pamVars{files} } );
	}

	OVF::Manage::Tasks::run( %options, @{ $pamVars{task}{enable} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub disable ( \% ) {

	my ( %options ) = %{ ( shift ) };
	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} );

	my %pamVars = %{ $OVF::Service::Security::PAM::LDAP::Vars::pam{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Tasks::run( %options, @{ $pamVars{task}{disable} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}
1;

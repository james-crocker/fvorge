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

package OVF::Service::Security::Firewall::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Init;
use OVF::Service::Security::Firewall::Vars;
use OVF::State;

sub isRunning ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $fwState;

	if ( $distro eq 'SLES' ) {
		my $fw = qx{rcSuSEfirewall2 status};
		if ( $fw =~ /running\s*$/ ) {
			$fwState = 1;
		} else {
			$fwState = 0;
		}
	} elsif ( $distro eq 'Ubuntu' ) {
		my $fw = qx{/usr/sbin/ufw status};
		if ( $fw =~ /^\s*Status:\s+active\s*$/ ) {
			$fwState = 1;
		} else {
			$fwState = 0;
		}
	} else {
		my $fw4 = qx{/etc/init.d/iptables status};
		my $fw6 = qx{/etc/init.d/ip6tables status};
		if ( $fw4 =~ /is not running/ and $fw6 =~ /is not running/ ) {
			$fwState = 0;
		} else {
			$fwState = 1;
		}
	}

	return $fwState;

}

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $property = 'service.security.firewall.enabled';

	if ( !defined $OVF::Service::Security::Firewall::Vars::firewall{$distro}{$major}{$minor}{$arch} ) {
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

    # Ubuntu server is not enabled in the default installation
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} and $distro ne 'Ubuntu');

	my %firewallVars = %{ $OVF::Service::Security::Firewall::Vars::firewall{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Init::enable( %options, %{ $firewallVars{init} } );

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

    # Ubuntu server is not enabled in the default installation
    ( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SYSTEM AT INITIAL STATE ...} ) and return ) if ( !exists $options{ovf}{previous} and $distro eq 'Ubuntu');

	my %firewallVars = %{ $OVF::Service::Security::Firewall::Vars::firewall{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	OVF::Manage::Init::disable( %options, %{ $firewallVars{init} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

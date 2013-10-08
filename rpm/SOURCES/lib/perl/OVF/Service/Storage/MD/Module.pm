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

package OVF::Service::Storage::MD::Module;

use strict;
use warnings;

use lib '../../../../../perl';
use OVF::Manage::Init;
use	OVF::Manage::Files;
use OVF::Manage::Tasks;
use OVF::Service::Storage::MD::Vars;
use OVF::State;

sub apply ( \% ) {
	
	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};
	
	my $property = 'service.md.enabled';

	if ( !defined $OVF::Service::Storage::MD::Vars::md{$distro}{$major}{$minor}{$arch} ) {
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

	my %mdVars = %{ $OVF::Service::Storage::MD::Vars::md{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ... } );

	$mdVars{files}{'initiatorname.md'}{apply}{1}{content} =~ s/<MD_INITIATOR_NAME>/$options{ovf}{current}{'service.md.initiatorname'}/;
	$mdVars{task}{discover}[ 0 ]                   =~ s/<MD_PORTAL>/$options{ovf}{current}{'service.md.portal'}/;
	$mdVars{task}{login}[ 0 ]                      =~ s/<MD_PORTAL>/$options{ovf}{current}{'service.md.portal'}/;
	$mdVars{task}{login}[ 0 ]                      =~ s/<MD_TARGET_IQN>/$options{ovf}{current}{'service.md.targetiqn'}/;
	$mdVars{task}{autonodes}[ 0 ]                  =~ s/<MD_TARGET_IQN>/$options{ovf}{current}{'service.md.targetiqn'}/;
	
	my $loginExpectVal = '6144';

	OVF::Manage::Files::create( %options, %{ $mdVars{files} } );
	OVF::Manage::Init::enable( %options, %{ $mdVars{init} } );
	OVF::Manage::Tasks::run( %options, @{ $mdVars{task}{logout} } );
	OVF::Manage::Tasks::run( %options, @{ $mdVars{task}{discover} } );
	OVF::Manage::Tasks::runExpect( $loginExpectVal, $mdVars{task}{login}[0], %options );
	OVF::Manage::Tasks::run( %options, @{ $mdVars{task}{autonodes} } );

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

	my %mdVars = %{ $OVF::Service::Storage::MD::Vars::md{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ... } );

	OVF::Manage::Tasks::run( %options, @{ $mdVars{task}{logout} } );
	OVF::Manage::Init::disable( %options, %{ $mdVars{init} } );
	OVF::Manage::Files::destroy( %options, %{ $mdVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

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

package OVF::Service::Locale::Module;

use strict;
use warnings;

use lib '../../../../perl';
use	OVF::Manage::Files;
use OVF::Manage::Tasks;
use OVF::Service::Locale::Vars;
use OVF::State;

sub apply ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};


	my $property = 'host.locale.change';

	if ( !defined $OVF::Service::Locale::Vars::locale{$distro}{$major}{$minor}{$arch} ) {
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
			destroy( \%options );
			create( \%options );
		}
	} 

}

sub create ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};
	my $lang   = $options{ovf}{current}{'host.locale.lang'};

	my %localeVars = %{ $OVF::Service::Locale::Vars::locale{$distro}{$major}{$minor}{$arch} };

	my $required        = [];
	my $requiredEnabled = [ 'host.locale.lang' ];
	return if ( OVF::State::checkRequired( $action, $required, 'host.locale.change', $requiredEnabled, %options ) );

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: DEFAULT $lang} ) and return ) if ( $lang eq $localeVars{'default'} );

	my $LANG     = $localeVars{LANG}{$lang};
	my $yastLang = $localeVars{yastLang}{$lang};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($lang)...} );

	$localeVars{files}{'bash_profile'}{apply}{1}{content} =~ s/<LOCALE_LANG>/$LANG/g;

	if ( $distro eq 'SLES' ) {
		$localeVars{task}{'yast-language'}[ 0 ] =~ s/<LOCALE_YAST_LANG>/$yastLang/;
		OVF::Manage::Tasks::run( %options, @{ $localeVars{task}{'yast-language'} } );
	} else {
		$localeVars{files}{'language'}{apply}{1}{content} =~ s/<LOCALE_LANG>/$LANG/g;
	}

	OVF::Manage::Files::create( %options, %{ $localeVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action       = $thisSubName;
	my $arch         = $options{ovf}{current}{'host.architecture'};
	my $distro       = $options{ovf}{current}{'host.distribution'};
	my $major        = $options{ovf}{current}{'host.major'};
	my $minor        = $options{ovf}{current}{'host.minor'};
	my $lang         = $options{ovf}{current}{'host.locale.lang'};
	my $previousLang = $options{ovf}{previous}{'host.locale.lang'} if ( exists $options{ovf}{previous} );

	my %localeVars = %{ $OVF::Service::Locale::Vars::locale{$distro}{$major}{$minor}{$arch} };

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO previous language setting applied } ) and return ) if ( !$previousLang );

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($previousLang)...} );

	OVF::Manage::Files::destroy( %options, %{ $localeVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

1;

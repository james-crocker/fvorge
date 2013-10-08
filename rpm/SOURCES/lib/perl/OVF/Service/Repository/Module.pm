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

package OVF::Service::Repository::Module;

use strict;
use warnings;

use lib '../../../../perl';
use	OVF::Manage::Directories;
use	OVF::Manage::Files;
use	OVF::Manage::Packages;
use OVF::Manage::Storage;
use OVF::Manage::Tasks;
use OVF::Service::Repository::Vars;
use OVF::State;

sub setup ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch      = $options{ovf}{current}{'host.architecture'};
	my $distro    = $options{ovf}{current}{'host.distribution'};
	my $major     = $options{ovf}{current}{'host.major'};
	my $minor     = $options{ovf}{current}{'host.minor'};
	
	my $updatesProperty = 'host.updates.enabled';
	my $updates   = $options{ovf}{current}{$updatesProperty};
	
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SLES setup not necessary} ) and return ) if ( $distro eq 'SLES' );

	my %packageVars = %{ $OVF::Service::Repository::Vars::packages{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	my $lcDistro = lc( $distro );
	$packageVars{mount}{target}              =~ s/<LC_DISTRO>/$lcDistro/;
	$packageVars{files}{'dvd-repo'}{path}    =~ s/<LC_DISTRO>/$lcDistro/g;
	$packageVars{files}{'dvd-repo'}{apply}{1}{content} =~ s/<LC_DISTRO>/$lcDistro/g;
	$packageVars{files}{'dvd-repo'}{apply}{1}{content} =~ s/<DISTRO>/$distro/g;
	$packageVars{files}{'dvd-repo'}{apply}{1}{content} =~ s/<MAJOR>/$major/g;
	$packageVars{files}{'dvd-repo'}{apply}{1}{content} =~ s/<MINOR>/$minor/g;
	$packageVars{files}{'dvd-repo'}{apply}{1}{content} =~ s/<ARCH>/$arch/g;
	
	if ( $distro eq 'CentOS' ) {
		
		( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $updatesProperty not defined} ) and return ) if ( !defined $updates );
		
		$packageVars{files}{'CentOS-Base.repo'}{apply}{1}{after}{1}{content} =~ s/<ENABLED>/$updates/g;
		
		# Change the after to substitute since if changed and already applied
		if ( exists $options{ovf}{previous} and OVF::State::ovfIsChanged( 'host.updates.enabled', %options ) ) {
			$packageVars{files}{'CentOS-Base.repo'}{apply}{1}{substitute} = Storable::dclone( $packageVars{files}{'CentOS-Base.repo'}{apply}{1}{after} );
			delete $packageVars{files}{'CentOS-Base.repo'}{apply}{1}{after};
		}
		
	}

	if ( %packageVars ) {

		# Create repo directories
		if ( $packageVars{directories} ) {
			OVF::Manage::Directories::create( %options, %{ $packageVars{directories} } );
		}

		# Create repo files and mount the iso
		if ( $packageVars{files} ) {
			OVF::Manage::Files::create( %options, %{ $packageVars{files} } );
		}
		if ( $packageVars{mount} ) {
			OVF::Manage::Storage::umount( %options, %{ $packageVars{mount} } );
			OVF::Manage::Storage::mount( %options, %{ $packageVars{mount} } );
		}
	}

	if ( $distro eq 'SLES' and $major == 10 ) {
		OVF::Manage::Packages::addSuseRepo( %options, %{ $packageVars{files} } );
	}

	OVF::Manage::Packages::clean( %options );
	OVF::Manage::Packages::update( %options );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;
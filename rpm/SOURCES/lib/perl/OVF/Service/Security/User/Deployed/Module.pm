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

package OVF::Service::Security::User::Deployed::Module;

use strict;
use warnings;

use lib '../../../../../../perl';
use OVF::Manage::Users;
use OVF::State;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub changePassword ( \% ) {

	my ( %options ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $deployedAdmin = 'service.security.user.deployed.admin';
	my $adminPassword = 'service.security.user.deployed.admin.password';

	my $admin;
	my $password;

	if ( !defined $options{ovf}{current}{$deployedAdmin} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $deployedAdmin undefined} );
		return;
	} else {
		$admin = $options{ovf}{current}{$deployedAdmin};
	}

	if ( !defined $options{ovf}{current}{$adminPassword} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $adminPassword undefined} );
		return;
	} else {
		$password = $options{ovf}{current}{$adminPassword};
	}

	my %adminCreds;
	$adminCreds{$admin} = { 'passwd' => $password };

	if ( !OVF::State::ovfIsChanged( $deployedAdmin, %options ) and !OVF::State::ovfIsChanged( $adminPassword, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $deployedAdmin same as Previous $deployedAdmin} );
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ...} );
		OVF::Manage::Users::changePassword( %options, %adminCreds );
	}

}

1;

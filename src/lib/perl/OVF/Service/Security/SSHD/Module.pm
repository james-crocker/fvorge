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

package OVF::Service::Security::SSHD::Module;

use strict;
use warnings;
use Storable;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Service::Security::SSHD::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

#
# For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub apply ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $enabled  = $options{ovf}{current}{'service.security.sshd.enabled'};
	my $packages = $options{ovf}{current}{'service.security.sshd.packages'};
	my $root     = $options{ovf}{current}{'service.security.sshd.permit-root'};
	my $pubkey   = $options{ovf}{current}{'service.security.sshd.pubkey-auth'};
	my $gssapi   = $options{ovf}{current}{'service.security.sshd.gssapi-auth'};
	my $rsa      = $options{ovf}{current}{'service.security.sshd.rsa-auth'};
	my $x11      = $options{ovf}{current}{'service.security.sshd.x11forwarding'};
	my $tcp      = $options{ovf}{current}{'service.security.sshd.tcpforwarding'};
	my $passwd   = $options{ovf}{current}{'service.security.sshd.password-auth'};
	my $usepam   = $options{ovf}{current}{'service.security.sshd.usepam'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSHD Vars not available} ) and return ) if ( !defined $OVF::Service::Security::SSHD::Vars::sshd{$distro}{$major}{$minor}{$arch} );

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSHD Packages unavailable or undefined} ) and return ) if ( !defined $packages or !$packages );

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSHD Configuration 'service.security.sshd.enabled' is undefined} ) and return ) if ( !defined $enabled );

	my %sshdVars = %{ $OVF::Service::Security::SSHD::Vars::sshd{$distro}{$major}{$minor}{$arch} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	if ( $enabled ) {

		# Remove settings if not requested
		if ( !defined $root ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{1}{content} =~ s/<SSHD_YORN>/$root/;
		}

		if ( !defined $gssapi ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{2}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{2}{substitute}{1}{content} =~ s/<SSHD_YORN>/$gssapi/;
		}

		if ( !defined $rsa ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{3}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{3}{substitute}{1}{content} =~ s/<SSHD_YORN>/$rsa/;
		}

		if ( !defined $pubkey ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{4}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{4}{substitute}{1}{content} =~ s/<SSHD_YORN>/$pubkey/;
		}

		if ( !defined $x11 ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{5}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{5}{substitute}{1}{content} =~ s/<SSHD_YORN>/$x11/;
		}

		if ( !defined $tcp ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{6}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{6}{substitute}{1}{content} =~ s/<SSHD_YORN>/$tcp/;
		}

		if ( !defined $passwd ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{7}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{7}{substitute}{1}{content} =~ s/<SSHD_YORN>/$passwd/;
		}

		if ( !defined $usepam ) {
			delete( $sshdVars{files}{'sshd_config'}{apply}{8}{substitute}{1} );
		} else {
			$sshdVars{files}{'sshd_config'}{apply}{8}{substitute}{1}{content} =~ s/<SSHD_YORN>/$usepam/;
		}

		if ( $distro eq 'SLES' or $distro eq 'Ubuntu' ) {
			OVF::Manage::Tasks::run( %options, @{ $sshdVars{task}{'open-firewall'} } );
		}

		OVF::Manage::Files::create( %options, %{ $sshdVars{files} } );

	} else {

		if ( $distro eq 'SLES' or $distro eq 'Ubuntu' ) {
			OVF::Manage::Tasks::run( %options, @{ $sshdVars{task}{'close-firewall'} } );
		}
		OVF::Manage::Files::destroy( %options, %{ $sshdVars{files} } );

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

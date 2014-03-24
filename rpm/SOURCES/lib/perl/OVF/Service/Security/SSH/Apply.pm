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

package OVF::Service::Security::SSH::Apply;

use strict;
use warnings;
use Storable;

use lib '../../../../../perl';
use OVF::Manage::Directories;
use OVF::Manage::Files;
use OVF::Service::Security::SSH::Vars;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

#
# For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub createUserConfig ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSH Vars not available } ) and return ) if ( !defined $OVF::Service::Security::SSH::Vars::ssh{$distro}{$major}{$minor}{$arch} );

	my %sshUserConfig = %{ $options{ovf}{current}{'service.security.sshd.userconfig'} };
	foreach my $num ( sort keys %sshUserConfig ) {

		# Get a fresh set
		my %sshVars = %{ Storable::dclone( $OVF::Service::Security::SSH::Vars::ssh{$distro}{$major}{$minor}{$arch} ) };

		my $uid = $sshUserConfig{$num}{uid};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: service.security.sshd.userconfig ($num) 'uid' not defined } ) and next ) if ( !$uid );

		my $gid = $sshUserConfig{$num}{gid};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: service.security.sshd.userconfig ($num) 'gid' not defined } ) and next ) if ( !$gid );

		my $home = $sshUserConfig{$num}{home};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: service.security.sshd.userconfig ($num) 'home' not defined } ) and next ) if ( !$home );

		( Sys::Syslog::syslog( 'err', qq{::SKIP:: service.security.sshd.userconfig ($num) 'genkeypair' not defined } ) and next ) if ( !defined $sshUserConfig{$num}{genkeypair} );
		my $genKeyPair = $sshUserConfig{$num}{genkeypair};

		( Sys::Syslog::syslog( 'err', qq{::SKIP:: service.security.sshd.userconfig ($num) genkeypair=n; 'pubkey' and/or 'privkey' not defined } ) and next ) if ( !$genKeyPair and ( !defined $sshUserConfig{$num}{pubkey} or !defined $sshUserConfig{$num}{privkey} ) );

		Sys::Syslog::syslog( 'info', qq{$action INITIATE (User: $uid) ... } );

		my $sshPath = qq{$home/} . $sshVars{directories}{home}{path};
		$sshVars{directories}{home}{chown} = $uid;
		$sshVars{directories}{home}{chgrp} = $gid;
		$sshVars{directories}{home}{path}  = $sshPath;
		
		foreach my $key ( keys %{ $sshVars{files} } ) {
			$sshVars{files}{$key}{chown} = $uid;
			$sshVars{files}{$key}{chgrp} = $gid;
			$sshVars{files}{$key}{path} =~ s/<SSH_USER>/$uid/;
			$sshVars{files}{$key}{path} = $sshPath . '/' . $sshVars{files}{$key}{path};
		}

		$sshVars{files}{config}{apply}{1}{content} =~ s/<SSH_PRIVATE_KEY>/$sshVars{files}{privkey}{path}/;

		if ( $sshUserConfig{$num}{authorizedkeys} ) {
			my @authKeys = split( /\s*,\s*/, $sshUserConfig{$num}{authorizedkeys} );
			$sshVars{files}{'authorized_keys'}{apply}{1}{content} = join( qq{\n}, @authKeys );
		}

		if ( $genKeyPair ) {
			# Remove pub/priv key files from the later create since asked to generate the keypair
			delete $sshVars{files}{pubkey};
			delete $sshVars{files}{privkey};
			$sshVars{task}{genkeypair}[ 0 ] =~ s/<SSH_BASE_PATH>/$sshPath/;
            $sshVars{task}{genkeypair}[ 0 ] =~ s/<SSH_USER>/$uid/;
		} else {
			$sshVars{files}{pubkey}{apply}{1}{content}  = $sshUserConfig{$num}{pubkey};
			$sshVars{files}{privkey}{apply}{1}{content} = $sshUserConfig{$num}{privkey};
			$sshVars{task}{genkeypair} = [];
		}

		OVF::Manage::Directories::create( %options, %{ $sshVars{directories} } );
		OVF::Manage::Tasks::run( %options, @{ $sshVars{task}{genkeypair} } );
		OVF::Manage::Files::create( %options, %{ $sshVars{files} } );

		# Re-apply SELINUX settings after all the dir/files layed down
		if ( $distro eq 'SLES' ) {
			my $selinuxRestoreCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'selinuxRestoreCmd'};
			Sys::Syslog::syslog( 'info', qq{$action RUNNING: $selinuxRestoreCmd $sshPath ... } );
			system( qq{$selinuxRestoreCmd $sshPath $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't $selinuxRestoreCmd ($sshPath) ($?:$!)} );
		}

		Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
	}

}

sub sshdConfig ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $root   = $options{ovf}{current}{'service.security.sshd.permit-root'};
	my $pubkey = $options{ovf}{current}{'service.security.sshd.pubkey-auth'};
	my $gssapi = $options{ovf}{current}{'service.security.sshd.gssapi-auth'};
	my $rsa    = $options{ovf}{current}{'service.security.sshd.rsa-auth'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSHD Vars not available } ) and return ) if ( !defined $OVF::Service::Security::SSH::Vars::sshd{$distro}{$major}{$minor}{$arch} );

	my %sshdVars = %{ $OVF::Service::Security::SSH::Vars::sshd{$distro}{$major}{$minor}{$arch} };

	# Remove settings if not requested
	if ( !defined $root ) {
		delete( $sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{1} );
	}

	if ( !defined $gssapi ) {
		delete( $sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{2} );
	}
	if ( !defined $rsa ) {
		delete( $sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{3} );
	}

	if ( !defined $pubkey ) {
		delete( $sshdVars{files}{'sshd_config'}{apply}{1}{substitute}{4} );
	}

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	if ( $distro eq 'SLES' ) {
		OVF::Manage::Tasks::run( %options, @{ $sshdVars{task}{'open-firewall'} } );
	}

	OVF::Manage::Files::create( %options, %{ $sshdVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

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
	
	my $ovfProperty = 'service.security.ssh.user.config';

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSH Vars not available } ) and return ) if ( !defined $OVF::Service::Security::SSH::Vars::ssh{$distro}{$major}{$minor}{$arch} );
	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: $ovfProperty not defined } ) and return ) if ( !defined $options{ovf}{current}{$ovfProperty} );

	my %sshUserConfig = %{ $options{ovf}{current}{$ovfProperty} };
	foreach my $num ( sort keys %sshUserConfig ) {

		# Get a fresh set
		my %sshVars = %{ Storable::dclone( $OVF::Service::Security::SSH::Vars::ssh{$distro}{$major}{$minor}{$arch} ) };

		my $uid = $sshUserConfig{$num}{uid};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: $ovfProperty($num) 'uid' not defined } ) and next ) if ( !$uid );

		my $gid = $sshUserConfig{$num}{gid};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: $ovfProperty($num) 'gid' not defined } ) and next ) if ( !$gid );

		my $home = $sshUserConfig{$num}{home};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: $ovfProperty($num) 'home' not defined } ) and next ) if ( !$home );

		( Sys::Syslog::syslog( 'err', qq{::SKIP:: $ovfProperty($num) 'genkeypair' not defined } ) and next ) if ( !defined $sshUserConfig{$num}{genkeypair} );
		my $genKeyPair = $sshUserConfig{$num}{genkeypair};

		( Sys::Syslog::syslog( 'err', qq{::SKIP:: $ovfProperty($num) genkeypair=n; 'pubkey' and/or 'privkey' not defined } ) and next ) if ( !$genKeyPair and ( !defined $sshUserConfig{$num}{pubkey} or !defined $sshUserConfig{$num}{privkey} ) );

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
			$sshVars{files}{privkey}{apply}{1}{content} = formatSshPrivateKey( $sshUserConfig{$num}{privkey} );
			$sshVars{task}{genkeypair}                  = [];
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
	my $x11    = $options{ovf}{current}{'service.security.sshd.x11forwarding'};
	my $tcp    = $options{ovf}{current}{'service.security.sshd.tcpforwarding'};
	my $passwd = $options{ovf}{current}{'service.security.sshd.password-auth'};
	my $usepam = $options{ovf}{current}{'service.security.sshd.usepam'};

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: SSHD Vars not available } ) and return ) if ( !defined $OVF::Service::Security::SSH::Vars::sshd{$distro}{$major}{$minor}{$arch} );

	my %sshdVars = %{ $OVF::Service::Security::SSH::Vars::sshd{$distro}{$major}{$minor}{$arch} };

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

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	if ( $distro eq 'SLES' or $distro eq 'Ubuntu' ) {
		OVF::Manage::Tasks::run( %options, @{ $sshdVars{task}{'open-firewall'} } );
	}

	OVF::Manage::Files::create( %options, %{ $sshdVars{files} } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub formatSshPrivateKey ( $ ) {

	my $sshPrivateKey = shift;

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $base64Regex = q{[A-za-z0-9\+\/]};

	Sys::Syslog::syslog( 'warning', qq{$action WARNING: SSH PrivateKey was not defined or was empty ($?:$!)} ) if ( !defined $sshPrivateKey or $sshPrivateKey eq '' );

	my $keyBeginType;
	my $keyEndType;

	if ( $sshPrivateKey =~ /^-----BEGIN\s(\S+)\sPRIVATE\sKEY-----/ ) {
		$keyBeginType = $1;
	}

	if ( $sshPrivateKey =~ /-----END\s(\S+)\sPRIVATE\sKEY-----$/ ) {
		$keyEndType = $1;
	}

	Sys::Syslog::syslog( 'warning', qq{$action WARNING: SSH PrivateKey did not contain valid BEGIN/END key type ($?:$!)} ) if ( !defined $keyBeginType or !defined $keyEndType );
	Sys::Syslog::syslog( 'warning', qq{$action WARNING: SSH PrivateKey type did not match ($?:$!)} ) if ( $keyBeginType ne $keyEndType );

	my $formatedPrivateKey;

	# Format string to key column format width
	$formatedPrivateKey = qq{-----BEGIN $keyBeginType PRIVATE KEY-----\n};

	my $slurpKey;
	if ( $sshPrivateKey =~ /KEY-----($base64Regex+)-----END/ ) {
		$slurpKey = $1;
	}

	while ( $slurpKey ) {
		if ( $slurpKey =~ /$base64Regex{1,64}/ ) {
			$formatedPrivateKey .= qq{$&\n};
			$slurpKey = $';
		}
	}

	$formatedPrivateKey .= qq{-----END $keyBeginType PRIVATE KEY-----\n};

	return $formatedPrivateKey;

}

1;

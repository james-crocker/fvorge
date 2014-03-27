#!/usr/bin/perl

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

BEGIN { @INC = ( "/opt/fvorge/lib/perl", "../lib/perl", @INC ); }

use strict;
use warnings;

#use Switch;
use Getopt::Long;
use Pod::Usage;
use Sys::Syslog;

use OVF::State;
use OVF::Custom::Module;
use OVF::Network::Module;
use OVF::Network::Packages;
use OVF::Service::App::NFS::Module;
use OVF::Service::App::NFS::Packages;
use OVF::Service::App::Samba::Module;
use OVF::Service::App::Samba::Packages;
use OVF::Service::Database::MySQL::Module;
use OVF::Service::Database::MySQL::Packages;
use OVF::Service::Database::Oracle::Module;
use OVF::Service::Database::PostgreSQL::Module;
use OVF::Service::Database::PostgreSQL::Packages;
use OVF::Service::Database::SAPDB::Module;
use OVF::Service::Database::Sybase::Module;
use OVF::Service::Graphic::XServer::Packages;
use OVF::Service::Locale::Module;
use OVF::Service::Locale::Packages;
use OVF::Service::Report::SNMP::Module;
use OVF::Service::Report::SNMP::Packages;
use OVF::Service::Report::Syslog::Module;
use OVF::Service::Repository::Module;
use OVF::Service::Security::AppArmor::Module;
use OVF::Service::Security::Firewall::Module;
use OVF::Service::Security::PAM::LDAP::Module;
use OVF::Service::Security::PAM::LDAP::Packages;
use OVF::Service::Security::SELINUX::Module;
use OVF::Service::Security::SSH::Apply;
use OVF::Service::Storage::ISCSI::Module;
use OVF::Service::Storage::ISCSI::Packages;
use OVF::Service::Storage::Multipath::Module;
use OVF::Service::Storage::Multipath::Packages;
use OVF::Service::Time::NTP::Module;
use OVF::Service::Time::NTP::Packages;
use OVF::Storage::Filesystems::Module;
use OVF::Storage::LVM::Module;
use OVF::SIOS::Automation::Module;
use OVF::SIOS::Automation::Packages;
use OVF::SIOS::Prerequisites::Packages;
use OVF::SIOS::Product::Module;

use OVF::VApp;

Sys::Syslog::openlog( 'fvorge', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

my @useError;
my %options;
my $help      = 0;
my $verbosity = 1;

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'help|h'        => \$help,
) or pod2usage( 2 );

pod2usage( 1 ) if $help;

#pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;
#pod2usage( @useError ) if @useError;

# Setup needed save/properties directories
OVF::State::envSetup();

# Will set $options{ovf} hash
OVF::State::propertiesGetCurrent( %options );

# IF YOU CHANGE THE ORDER OR ADD SERVICES CHECK OVF::State::propertiesGetGroup FOR CHANGES

# Only run if changes by checking for previously saved 'properties-network|packages...' file
my $group = 'network';
my $customGroup = 'custom.'.$group;
my $action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	OVF::Custom::Module::apply( $customGroup, 'before', %options );
	OVF::Network::Module::apply( %options );
	OVF::Service::Security::SSH::Apply::sshdConfig( %options );
	OVF::Service::Security::SSH::Apply::createUserConfig( %options );
	OVF::Custom::Module::apply( $customGroup, 'after', %options );

	OVF::State::propertiesSave( $group, %options );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

	OVF::VApp::restart( %options );

} else {
	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: PREVIOUSLY APPLIED} );
}

$group = 'packages';
$customGroup = 'custom.'.$group;
$action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	# To setup the 'RHEL' derived repositories with local DVD iso's (Disables updates in CentOS)
	OVF::Service::Repository::Module::setup( %options );

	OVF::Custom::Module::apply( $customGroup, 'before', %options );
	OVF::Service::Locale::Packages::apply( %options );
	#OVF::Service::App::Apache::Packages::apply( %options );
	OVF::Service::App::NFS::Packages::apply( %options );
	#OVF::Service::App::Postfix::Packages::apply( %options );
	OVF::Service::App::Samba::Packages::apply( %options );
	#OVF::Service::Database::DB2::Packages::apply( %options );
	OVF::Service::Database::MySQL::Packages::apply( %options );
	#OVF::Service::Database::Oracle::Packages::apply( %options );
	OVF::Service::Database::PostgreSQL::Packages::apply( %options );
	#OVF::Service::Database::SAPDB::Packages::apply( %options );
	#OVF::Service::Database::Sybase::Packages::apply( %options );
	OVF::Service::Graphic::XServer::Packages::apply( %options );
	OVF::Network::Packages::apply( %options );
	OVF::Service::Report::SNMP::Packages::apply( %options );
	OVF::Service::Security::PAM::LDAP::Packages::apply( %options );
	OVF::Service::Storage::ISCSI::Packages::apply( %options );
	OVF::Service::Storage::Multipath::Packages::apply( %options );
	#OVF::Service::Storage::MD::Packages::apply( %options );
	OVF::Service::Time::NTP::Packages::apply( %options );
	OVF::SIOS::Automation::Packages::apply( %options );
	OVF::SIOS::Prerequisites::Packages::apply( %options );
	OVF::Custom::Module::apply( $customGroup, 'after', %options );

	OVF::State::propertiesSave( $group, %options );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

	OVF::VApp::restart( %options );

} else {
	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: PREVIOUSLY APPLIED} );
}

$group = 'host-services';
$customGroup = 'custom.'.$group;
$action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	OVF::Custom::Module::apply( $customGroup, 'before', %options );
	OVF::Service::Locale::Module::apply( %options );
	OVF::Service::Report::SNMP::Module::apply( %options );
	OVF::Service::Report::Syslog::Module::apply( %options );
	OVF::Service::Security::AppArmor::Module::apply( %options );
	OVF::Service::Security::SELINUX::Module::apply( %options );
	OVF::Service::Security::Firewall::Module::apply( %options );
	OVF::Service::Security::PAM::LDAP::Module::apply( %options );
	OVF::Service::Storage::ISCSI::Module::apply( %options );
	OVF::Service::Storage::Multipath::Module::apply( %options );
	#OVF::Service::Storage::MD::Module::apply( %options );
	OVF::Service::Time::NTP::Module::apply( %options );
	OVF::SIOS::Automation::Module::apply( %options );
	OVF::Custom::Module::apply( $customGroup, 'after', %options );

	OVF::State::propertiesSave( $group, %options);
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

	OVF::VApp::restart( %options );

} else {
	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: PREVIOUSLY APPLIED} );

}

$group = 'storage';
$customGroup = 'custom.'.$group;
$action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	OVF::Custom::Module::apply( $customGroup, 'before', %options );
	OVF::Storage::Filesystems::Module::apply( %options );
	OVF::Storage::LVM::Module::apply( %options );
	#OVF::Storage::MD::Module::apply( %options );
	OVF::Custom::Module::apply( $customGroup, 'after', %options );

	OVF::State::propertiesSave( $group, %options );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

	OVF::VApp::restart( %options );

} else {
	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: PREVIOUSLY APPLIED} );
}

$group = 'app-services';
$customGroup = 'custom.'.$group;
$action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	OVF::Custom::Module::apply( $customGroup, 'before', %options );
	OVF::Service::App::NFS::Module::apply( %options );
	OVF::Service::App::Samba::Module::apply( %options );
	#OVF::Service::App::Apache::Module::apply( %options );
	#OVF::Service::App::MQ::Module::apply( %options );
	#OVF::Service::App::Postfix::Module::apply( %options );
	#OVF::Service::App::SAP::Module::apply( %options );
	#OVF::Service::Database::DB2::Module::apply( %options );
	OVF::Service::Database::Oracle::Module::apply( %options );
	OVF::Service::Database::SAPDB::Module::apply( %options );
	OVF::Service::Database::Sybase::Module::apply( %options );
	OVF::Service::Database::MySQL::Module::apply( %options );
	OVF::Service::Database::PostgreSQL::Module::apply( %options );
	OVF::SIOS::Product::Module::apply( %options );	
	OVF::Custom::Module::apply( $customGroup, 'after', %options );

	OVF::State::propertiesSave( $group, %options );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

} else {
	Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: PREVIOUSLY APPLIED} );
}

1;

__END__

=head1 NAME

FVORGE Apply OVF Properties

=head1 SYNOPSIS

fvorge [--help]

=head1 OPTIONS

=over 8

=item B<--help|-h>

Print help and exit.

=item B<General>
=begin text
-------------------------

SUPPORTING:
        Distributions:
                RHEL|CentOS|ORAL (MAJOR.MINOR) 5.9, 6.0, 6.1, 6.2, 6.3, 6.4
                SLES (MAJOR.MINOR) 10.4, 11.2, 11.2
        Architectures:
                x86_64|i686 (ALL DISTROS)
        
        [ SLES 10.4 support is the weakest as YAST2 is not as complete as in later versions. Not all services will configure automatically without manual effort. e.g. PAM-LDAP ]
        

Settings are order independent. Valid settings are of the general form id=value.
!! Multiple settings are accepted with SPACES 'id=value id2=value2'.
!! Groups are separated with ' ;; ' (see Network examples). 
Any settings value that contain reserved characters must be escaped.

	Reserved Characters that must be escaped:
		space	%20
		=		%3D
		
		eg. id=%some=%()$ #complex"sett ing" SHOULD TRANSFORM id=%some%3D%()$%20#complex"sett%20ing"

        True/False settings are case insensitive and can be of the form:
                opt=y|n|yes|no|true|false|t|f|1|0        


!! NOTE !! When 'reversing/removing' applied settings it is recommended that you perfom the following order:
	First: app-services
		set enabled=n (apply/reboot) then set packages=n (apply/reboot)
		
	Second: storage
		set action=destroy (apply/auotmatic reboot)
	
	Third: host-services
		set enabled=n (apply/automatic reboot) then set packages=n (apply/automatic reboot)
		
	Fourth: packages
		set packages=n (apply/automatic reboot)

The order of ovf processing is:

Network
	OVF::Custom::Module::apply( 'custom.network', 'before' )
	OVF::Network::Module::apply
	OVF::Service::Security::SSH::Apply::sshdConfig
	OVF::Service::Security::SSH::Apply::createUserConfig
	--reboot--
Packages
	OVF::Custom::Module::apply( 'custom.packages', 'before' )
	OVF::Service::Locale::Packages::apply
	#OVF::Service::App::Apache::Packages::apply
	OVF::Service::App::NFS::Packages::apply
	#OVF::Service::App::Postfix::Packages::apply
	OVF::Service::App::Samba::Packages::apply
	#OVF::Service::Database::DB2::Packages::apply
	OVF::Service::Database::MySQL::Packages::apply
	#OVF::Service::Database::Oracle::Packages::apply
	OVF::Service::Database::PostgreSQL::Packages::apply
	#OVF::Service::Database::SAPDB::Packages::apply
	#OVF::Service::Database::Sybase::Packages::apply
	OVF::Service::Graphic::XServer::Packages::apply
	OVF::Network::Packages::apply
	OVF::Service::Report::SNMP::Packages::apply
	OVF::Service::Security::PAM::LDAP::Packages::apply
	OVF::Service::Storage::ISCSI::Packages::apply
	OVF::Service::Storage::Multipath::Packages::apply
	#OVF::Service::Storage::MD::Packages::apply
	OVF::Service::Time::NTP::Packages::apply
	OVF::SIOS::Automation::Packages::apply
	OVF::SIOS::Prerequisites::Packages::apply
	OVF::Custom::Module::apply( 'custom.packages', 'after' )
	--reboot--
Host-Services
	OVF::Custom::Module::apply( 'custom.host-services', 'before' )
	OVF::Service::Locale::Module::apply
	OVF::Service::Report::SNMP::Module::apply
	OVF::Service::Report::Syslog::Module::apply
	OVF::Service::Security::AppArmor::Module::apply
	OVF::Service::Security::SELINUX::Module::apply
	OVF::Service::Security::Firewall::Module::apply
	OVF::Service::Security::PAM::LDAP::Module::apply
	OVF::Service::Storage::ISCSI::Module::apply
	OVF::Service::Storage::Multipath::Module::apply
	#OVF::Service::Storage::MD::Module::apply
	OVF::Service::Time::NTP::Module::apply
	OVF::SIOS::Automation::Module::apply
	OVF::Custom::Module::apply( 'custom.host-services', 'after' )
	--reboot--
Storage
	OVF::Custom::Module::apply( 'custom.storage', 'before' )
	OVF::Storage::Filesystems::Module::apply
	OVF::Storage::LVM::Module::apply
	#OVF::Storage::MD::Module::apply
	OVF::Custom::Module::apply( 'custom.storage', 'after' )
	--reboot--
App-Services
	OVF::Custom::Module::apply( 'custom.app-services', 'before' )
	OVF::Service::App::NFS::Module::apply
	OVF::Service::App::Samba::Module::apply
	#OVF::Service::App::Apache::Module::apply
	#OVF::Service::App::MQ::Module::apply
	#OVF::Service::App::Postfix::Module::apply
	#OVF::Service::App::SAP::Module::apply
	#OVF::Service::Database::DB2::Module::apply
	OVF::Service::Database::Oracle::Module::apply
	OVF::Service::Database::SAPDB::Module::apply
	OVF::Service::Database::Sybase::Module::apply
	OVF::Service::Database::MySQL::Module::apply
	OVF::Service::Database::PostgreSQL::Module::apply
	OVF::SIOS::Product::Module::apply	
	OVF::Custom::Module::apply( 'custom.app-services', 'after' )
	--NO-reboot--

!! NOTE: SPS Product setup with EVAL LICENSE keys will generate and EMERG syslog entry. This appears
to 'close' the OVF Syslog logger. Processing continues for custom.app-services and the properties
are saved, but syslog messaging is terminated. (Attempted to 're-open' after SIOS::Product::Module::apply
but that was unsuccessful). 
 
Declarations prefixed with * are REQUIRED (with exceptions noted)
Declarations prefixed with + are REQUIRED *IF* change|enabled|available|create|destroy are TRUE (with exceptions noted)

=end text
=item B<Host>
=begin text
-------------------------

	SSH Keys, common authorized_keys and config settings will be setup for 'root' user.

	Architecture [host]:
	    *architecture=x86_64|i686
        *distribution=RHEL|CentOS|ORAL|SLES
        *major=#
        *minor=#
        *cluster=#
        *instance=#

		eg. RHEL 6.3 64bit
		architecture=x86_64
		distribution=RHEL
		major=6
		minor=3

		eg. SLES11 SP2 32bit
		architecture=i686
		distribution=SLES
		major=11
		minor=2
       
	Language [host.locale]: (may be empty)
		change=n (DEFAULT is NO)
		+lang=EN|DE|KR|JP (DEFAULT is EN)

		EN english, DE german, KR korean, JP japanese (ALL are *.UTF-8)
                
	Updates [host.updates]: (may be empty)
		enabled=n (DEFAULT is NO, currently only applicable to CentOS and Ubuntu)
        	

=end text
=item B<Networking>
=begin text
-------------------------

	In general any if= declarations should correspond to the VM guest network interfaces in order from top to bottom as listed in the VM guest's 'edit settings'.
	eg. NIC1:E1000:VMnetwork, NIC2:E1000:VMnetwork, NIC3:E1000 corresponds to if=1, if=2, if=3

	Host [network]: (required)
		*hostname=cae-qa-base
		*domain=sc.steeleye.com

	Gateway [network.gateway]: (required)
		*ipv4=172.17.100.254
		ipv6=2001:5C0:110E:3368::254 (optional if not providing IPv6 networking)
		
	Resolv [network.resolv]: (required)
		*search=sc.steeleye.com,sc6.steeleye.com,steeleye.com
		*nameservers=172.17.4.1,172.17.4.60

	'REAL' interfaces [network.if]: (required)
		IPv4 only, IPv6 only or BOTH 		
		*if=1 (the order of 'physical' network interface adapters, generally 'top-down' in the VM guest host hardware properties)
		*label=eth0 (arbitrary)
		onboot=no (OPTIONAL RHEL ONLY, default is 'yes')
        bootproto=static (OPTIONAL, default is 'static')
		ipv4=172.17.105.60 (Default is '')
		ipv4-prefix=22 (Default is '')
		ipv6=2001:5C0:110E:3368::254 (Default is '')
		ipv6-prefix=64 (Default is '')
		
		Interfaces that will be slaves to a BONDED interface:
		*if=3
		*label=eth3
		*master-label=bond0 (label of bond master that this interface will be a slave)
		
		The MAC address will be discovered from the VMware tools. The interface and MAC addresses will be
		added to the persistent hosts file.
		
	ALIAS [network.alias]: (may be empty)
	
		RHEL|CentOS|ORAL Systems:
		IPv4 only, IPv6 only or BOTH
			*if=1 (associated 'REAL' interface)
			*label=eth0:1 (SLES should be label=# e.g. label=2)
			onparent=no (OPTIONAL RHEL ONLY, default is 'yes')
			ipv4=172.17.105.60 (Default is '')
			ipv4-prefix=22 (Default is '')
			ipv6=2001:5C0:110E:3368::254 (Default is '')
			ipv6-prefix=64 (Default is '')
			
			EXAMPLE: if=1 label=eth0:1 ipv4=172.17.105.60 ipv4-prefix=22 ipv6=2001:5C0:110E:3368::254 ipv6-prefix=64 ;; if=2 label=eth1:1 ipv4=172.17.105.61 ipv4-prefix=22 ;; if=3 label=eth2:1 ipv6=2001:5C0:110E:3368::253 ipv6-prefix=64
		
		SLES Systems: (Can only define one set of IPv4|IPv6 aliases, but you can have multiple labels)
			*if=1 (associated 'REAL' interface)
	    	*label=1
			*ipv4=172.17.105.60
			*ipv4-prefix=22
			
			*if=1
			*label=2
			*ipv6=2001:5C0:110E:3368::254
			*ipv6-prefix=64
			
			EXAMPLE: if=1 label=1 ipv4=172.17.105.60 ipv4-prefix=22 ;; if=1 label=2 ipv6=2001:5C0:110E:3368::254 ipv6-prefix=64 ;; if=2 label=1 ipv6=2001:5C0:110E:3368::253 ipv6-prefix=64
			
	BOND [network.bond]: (may be empty)
		IPv4 only, IPv6 only or BOTH
		*label=bond0 (arbitrary but should match master-label of 'REAL' interfaces)
		*if-slaves=3,4 (associated 'REAL' interfaces defined with master-label)
		opts=mode%3Dbalance-rr%20miimon%3D100 (OPTIONAL, default is mode=RoundRobin, miimon 100)
		onboot=yes|no (OPTIONAL RHEL ONLY, default is 'yes')
		ipv4=172.17.105.60 (Default is '')
		ipv4-prefix=22 (Default is 24)
		ipv6=2001:5C0:110E:3368::254 (Default is '')
		ipv6-prefix=64 (Default is 64)

=end text
=item B<Base Services>
=begin text
-------------------------
	AppArmor [service.security.apparmor]: (may be empty) OS default is ENABLED
		enabled=y
        syslog-emerg=y (SLES enable fix of AppArmor syslog EMERG notices to console)

	SELINUX [service.security.selinux]: (may be empty) OS default is ENABLED
		enabled=n

	Firewall [service.security.firewall]: (may be empty) OS default is ENABLED
		enabled=y
		add-sshd=y (SLES specific, allow SSHD if firewall is enabled, default is No)

	NTP [service.time.ntp]: (may be empty) OS default is NO Packages, DISABLED
		packages=y   
		enabled=y
		+servers=ntp1.sc.steeleye.com
		
	PAM-LDAP [service.secuirty.pam.ldap]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		packages-32bit=y (Default is No)
		enabled=n
		+server=ldap.sc.steeleye.com (Ubuntu: ldap://<server>, ldaps://<server>, ldapi://<domainSocketUrlEncoded>)
		+basedn=dc%3Dsteeleye,dc%3Dcom
		rootbindpw=<password>
		rootbinddn=cn%3Dmanager,dc%3Dexample,dc%3Dnet
		binddn=cn%3Dproxyuser,dc%3Dexample,dc%3Dnet		

	SNMP [service.report.snmp]: (may be empty) OS default is NO Packages, DISABLED
		packages=n
		enabled=n
		+community=defCommunity%20sesnmp

	SSHD [service.security.sshd]: (may be empty) OS default is original distro config settings for sshd_config
		permit-root=y
		rsa-auth=y
		gssapi-auth=n
		pubkey-auth=y
		x11forwarding=n
		tcpforwarding=n
		password-auth=y
		userpam=y		
		
	SSHD [service.security.sshd.userconfig]: (may be empty) If defined however; uid, gid, home and genkeypair must be defined
	    *uid=username
	    *gid=groupname
	    *home=user home path
	    *genkeypair=y (if no; privkey and pubkey must be defined)
	    privkey=... (ignored if genkeypair=n)
	    pubkey=... (ignored if genkeypair=n)
        authorizedkeys=authorized_key format seperate multiple with ',' (make sure to use %3D for = and %20 for spaces if either occur in your keys)
        
        EXAMPLE: uid=root gid=root home=/root genkeypair=y authorizedkeys=ssh-rsa%20 A...%3D%20usera@hosta,ssh-rsa%20A...H%20userb@hostb ;; uid=sios gid=sios home=/home/sios genkeypair=y

	SYSLOG [service.report.syslog]: (syslog, rsyslog, syslog-ng) (may be empty) OS default is NO central syslog messaging
		enabled=y
		+server=syslogs.sc.steeleye.com
		port=714 (Default 514)
		protocol=udp (Default TCP)
		faciltiy=local6.* (Default *.*)
		
		EXAMPLE: enabled=y server=syslogs.sc.steeleye.com port=514 protocol=tcp facility=local6.info

	X-server [service.graphic.xserver]: (may be empty) OS default is NO Packages
		packages=y
                
        	(Still 'headless', just the minimum to allow ssh -X sessions)

=end text
=item B<Storage Services>
=begin text
-------------------------

	ISCSI [service.storage.iscsi]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=y
		+portal=iscsi-10.sc.steeleye.com 
		+initiatorname=iqn.2013-01.com.steeleye.qa.init:02-11-02-01-###-##
		+targetiqn=iqn.2013-01.com.steeleye.qa.target:02-11-02-01-###

	Multipath [service.storage.multipath]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=y
          
        	(sets multipath.conf for ISCSI FILEIO)

=end text
=item B<Storage>
=begin text
-------------------------

	NOTE: RHEL 5.x multipath friendly names are of the style mpath0, mpath1, etc. RHEL 6.x and SLES 11.x are of the style mpatha, mpathb, etc.
	NOTE: RHEL x.x partitions are of the style mpath[a-z|#]p1, mpath[a-z|#]p2 etc. SLES x.x are of the style mpatha_part1, mpathb_part2, etc.

	General Filesystem [storage.fs]: (may be empty)
		action=available|create|destroy|skip
		^+device=/dev/sda
		c+partitions=4
		c+label=gpt|msdos
		c+size=60%,10%,10%,10% (Number of values must match the number of partitions. Value in percent)
		mount-path=/srv/fvorge-fsa1,/srv/fvorge-fsa2,/srv/fvorge-fsa3,/srv/fvorge-fs4 (DEFAULT is /srv/fvorge-fs/<device><partition>, eg. /srv/fvorge-fs/sda1)
		mount=y,n,n,n (DEFAULT is YES)
		fs-type=ext2,ext3,ext4,swap (DEFAULT is ext3 if not explicit)
		fstab=y,n,y,y (DEFAULT is NOT to add to fstab)
		fstab-option=[defaults,noatime,noacl,recovery],[...] (DEFAULT is 'defaults')
		
		c+ Required for 'create' and fs-type NOT 'nfs'. If fs-type=nfs these values are ignored.
		^+ Required for 'available', 'create' and 'destroy' (all fs-types)

		EXAMPLE: action=create device=/dev/sdb partitions=2 mount-path=/srv/fvorge-fs1,/srv/fvorge-fs2 fs-type=ext3,ext4 fstab=y,y fstab-options=[noatime],[noacl] ;; ...
		
		=== partitions=0
		Will label and use the full device with no partitioning. e.g. /dev/sda
		
		=== MSDOS
		action=create label=msdos
		partitions=5
		size=20%,20%,20%,20%,20%
		Partition Type order will be primary,primary,primary,extended,logical,logical
		sda1,sda2,sda3,sda5,sda6
		...
		partitions=4
		size=25%,25%,25%,25%
		Partition Type order will be primary,primary,primary,primary
		
		When using existing volumes with 'action=available', any volumes with 'extended' type as 1st, 2nd or 3rd partition WILL NOT WORK!!
		Assure that volumes being used with <= 4 partitions will be primary,primary,primary,primary
		Assure that volumes being used with > 4 partitions will be primary,primary,primary,extended,logical[,logical...]
		
		=== GPT
		action=create label=gpt
		partitions=6
		size=20%,10%,10%,10%,10%,40%
		
		=== fs-type NFS
		When fs-type=nfs encountered all additional settings are one-to-one. There are no 'multiples' as for regular filesystems.
		action=create|available has the same behavior
		mount-path default is [Vars.pm:defaults:mount-path]/hostname/path 
		
		EXAMPLE: action=available fs-type=nfs device=hostname:/path mount=n fstab=y
		

	LVM [storage.lvm]: (may be empty)
		action=available|create|destroy|skip
		^+pv-device=/dev/mapper/mpathb[,/dev/mapper/mpathc,...]
		c+lv-slices=3
		vg-name=sevg1 (DEFAULT vg name is fvorge-vg#)
		lv-name=lva1,lva2,lva3 (DEFAULT lv name is fvorge-lv#)
		c+size=70%,10%,10% (Number of values must match the number of lv-slices. Value in percent)
		mount-path=/srv/fvorge-lva1,/srv/fvorge-lva2,/srv/fvorge-lva3 (DEFAULT mount is /srv/fvorge-lvm/fvorge-lv#)
		mount=y,n,n,n (DEFAULT is YES)
		fs-type=ext3,swap,ext4 (DEFAULT is ext3 if not explicit)
		fstab=n,n,n (DEFAULT is NOT to add to fstab)
		fstab-option=[defaults,noatime,noacl,recovery],[...] (DEFAULT is 'defaults')
		
		c+ Required for 'create'
        ^+ Required for 'create' and 'destroy'
        
		EXAMPLE: action=create pv-device=/dev/sdb,/dev/sdc partitions=2 mount-path=/srv/fvorge-lva1,/srv/fvorge-lva2 fs-type=ext3,ext4 fstab=y,y fstab-options=[noatime],[noacl] ;; ...
		
	LVM [storage.lvm.options]: (may be empty) OS default is NO booton
		booton=y (Primarily for SLES, RHEL appears to have VG available on reboot)
		
=end text
=item B<Services>
=begin text
-------------------------
	In general you can install service packages without enabling the service and it's associated settings. However, in most cases
	you'll want to install packages AND enable a service.

	NFS [service.app.nfs]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=y
		+version=3|4 (Version 2 not supported)
		+storage-device=/dev/sevg1/fvorge-lva1
		+data-directory=/srv/fvorge-lva1
		fs-type= (Default is to get TYPE="" from blkid)
		clear-storage=y (Default is NO)
		+virtualip=
		+virtualip-prefix=
		+virtualip-if=
               

	SAMBA [service.app.samba]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=n
		+role=pdc|bdc|standalone|member (Primarily for use with SLES, but required for both)
		+sharepath=
		+workgroup=
		+netbiosname=
		+sharename=
		+lockpath=
		+logpath=
		+pidpath=
		+confpath=
		+storage-device=
		fs-type= (Default is to get TYPE="" from blkid)
		clear-storage=y (Default is NO)
		+virtualip=
		+virtualip-prefix=
		+virtualip-if=
		
	MySQL [service.database.mysql]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=y
		+database-directory=
		+storage-device=
		+port=
		+socket=/tmp/mysql.sock
		+pid-file=/var/run/mysqld/mysqld.pid
		+log-error=
		fs-type= (Default is to get TYPE="" from blkid)
		initdb=y (Default is NO)
		+virtualip=
		+virtualip-prefix=
		+virtualip-if=

	PostgreSQL [service.database.postgresql]: (may be empty) OS default is NO Packages, DISABLED
		packages=y
		enabled=y
		+database-directory=
		+port=
		+storage-device=
		fs-type= (Default is to get TYPE="" from blkid)
		initdb=y (Default is NO)
		+virtualip=
		+virtualip-prefix=
		+virtualip-if=

	Oracle [service.database.oracle]: (may be empty) OS default is NO Packages, DISABLED
		enabled=y

	SAPDB [prepare.sapdb]: (may be empty) OS default is NO Packages, DISABLED
		enabled=y
		+virtualip=
		+virtualip-prefix=
		+virtualip-if=

	Sybase [service.database.sybase]: (may be empty) OS default is NO Packages, DISABLED
		packages=y (only the required distribution dependent packages, not sybase itself)
		enabled=y
		
=end text
=item B<SIOS Product>
=begin text
-------------------------

	SIOS Product [sios]: (may be empty) OS default is NO Packages, NO Product
		product=sps|vapp|lk|smc
		^prerequisites=y (Default is No)
		^packages-32bit=y (Default is No)
		^setup=n
                
        ^ Require that sios.product be defined and valid 

	Setup-Args [sios.setup-args]: (-no-c already set, --product is set from se.product) *REQUIRED if sios.setup=y
		-u jcrocker -v 8.1.2 --arks dmmp nfs sdr --postedits /opt/fvorge/lib/sps/default/interfacelist

	Erase-Args [sios.erase-args]: (called if se.product.setup is false|no, -no-c already set)
		<empty>        
		
	Automation [sios.automation]: (may be empty) OS default is NO user, tty or packages to support automation
		setup=n

=end text
=item B<Custom>
=begin text
-------------------------

	For executing administrator defined actions in each of the fvorge 'group' actions. 
	The order of execution precedence is from left to right.
	
	[custom.[network|packages|host-services|storage|app-services]]: (may be empty)
	
	+priority=before|after
	+action=<arbitrary command; be sure to escape special characters as defined above> [;; priority=before|after action=<cmd> ...]
	expect=256 ($?, Default is 0 for 'success'. If non-digit 0 assumed)

    Both priority and action must be defined in the groupings.
	
	EXAMPLE: custom.app-service
	priority=before action=somecoolapp expect=1 ;; priority=after action=anothercoolapp expect=0
	
	Execute somecoolapp before any of the app-service modules are called and expect a return value of 1 for successful execution.

=cut


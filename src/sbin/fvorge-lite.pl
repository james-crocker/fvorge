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
use OVF::Service::Time::Zone::Module;

use OVF::VApp;

Sys::Syslog::openlog( 'fvorge-lite', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

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
my $group = 'lite';
#my $customGroup = 'custom.'.$group;
my $action = "FVORGE $group";
if ( !OVF::State::propertiesApplied( $group, %options ) ) {

	Sys::Syslog::syslog( 'info', qq{$action APPLY ...} );

	OVF::Network::Module::apply( %options );
	OVF::Service::Time::Zone::Module::apply( %options );

	OVF::State::propertiesSave( $group, %options );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

	OVF::VApp::restart( %options );

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
                UBUNTU (MAJOR.MINOR) 13.10, 14.04
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

Lite
	OVF::Custom::Module::apply( 'custom.network', 'before' )
	OVF::Network::Module::apply
	OVF::Service::Time::Zone::apply
	OVF::Custom::Module::apply( 'custom.network', 'after' )
	--reboot--
 
Declarations prefixed with * are REQUIRED (with exceptions noted)
Declarations prefixed with + are REQUIRED *IF* change|enabled|available|create|destroy are TRUE (with exceptions noted)

=end text
=item B<Fvorge>
=begin text
-------------------------

	To *disable* the application of properties via fvorge. (OPTIONAL, default is enabled)
	[fvorge.disable]: true|false|t|f|yes|no|y|n|0|1
	
=end text
=item B<Host>
=begin text
-------------------------

	Architecture [host]: (ovf value; but userConfigurable=false)
	    *architecture=x86_64|i686
        *distribution=RHEL|CentOS|ORAL|SLES|Ubuntu
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
       
	Timezone [host.time.zone]: (Default is GMT-0)

=end text
=item B<Networking>
=begin text
-------------------------

	In general any if= declarations should correspond to the VM guest network interfaces in order from top to bottom as listed in the VM guest's 'edit settings'.
	eg. NIC1:E1000:VMnetwork, NIC2:E1000:VMnetwork, NIC3:E1000 corresponds to if=1, if=2, if=3

	Host [network.hostname] (required)
	     [network.domain] (required)

	Gateway [network.gateway.ipv4]: (required)
		
	Resolv [network.resolv.search]: comma delimited (required)
	       [network.resolv.nameservers]: comma delimited (required)

	Network [lite.network.ipv4]: (required)
	        [lite.network.ipv4-prefix]: (required)
	        [lite.network.label]: (required)
	        [lite.network.ipv4-bootproto]: (required)
		
		The MAC address will be discovered from the VMware tools. The interface and MAC addresses will be
		added to the persistent hosts file.
		
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

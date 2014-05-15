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

use LIO::Module;
use LIO::Vars;
use OVF::Automation::Module;
use OVF::Vars::Common;

Sys::Syslog::openlog( 'fvorge-lio', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

my @useError;
my %options;
my $help      = 0;
my $verbosity = 1;
my $action;
my $distribution;
my $major;
my $minor;
my $architecture;
my $group;
my $instance;
my $targetServer;
my $iqnTarget;
my $iqnInitiator;
my $lioObject;
my @portals;
my @portalPorts;
my $fabric;
my @volSizes;
my $tpgtNum;
my $disableChap;
my $vmName;

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'help|h'                => \$help,
	'action|a=s'            => \$action,
	'distribution|distro=s' => \$distribution,
	'major|maj=i'           => \$major,
	'minor|min=i'           => \$minor,
	'architecture|arch=s'   => \$architecture,
	'group|g=i'             => \$group,
	'instance|n=i'          => \$instance,
	'fabric|f=s'            => \$fabric,
	'iqntarget|iqnt=s'      => \$iqnTarget,
	'iqninit|iqni=s'        => \$iqnInitiator,
	'targetserver|ts=s'     => \$targetServer,
	'lioobject|lo=s'        => \$lioObject,
	'portals|p=s{,}'           => \@portals,
	'portalports|pp=s{,}'      => \@portalPorts,
	'volsizes|vs=s{,}'          => \@volSizes,
	'vmname|vm=s'           => \$vmName,
	'disablechap|dc!'       => \$disableChap,
	'tpgt|tn=i'             => \$tpgtNum,
) or pod2usage( 2 );

pod2usage( 1 ) if $help;

#pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $actionRegex   = $LIO::Vars::actionRegex;
my $createRegex   = $LIO::Vars::createRegex;
my $destroyRegex  = $LIO::Vars::destroyRegex;
my $fabircRegex   = $LIO::Vars::fabricRegex;
my $volUnitsRegex = $LIO::Vars::volUnitsRegex;

my $distroRegex      = $OVF::Vars::Common::sysVars{distrosRegex};
my $archRegex        = $OVF::Vars::Common::sysVars{archsRegex};
my $rhelVersionRegex = $OVF::Vars::Common::sysVars{rhelVersionsRegex};
my $slesVersionRegex = $OVF::Vars::Common::sysVars{slesVersionsRegex};

if ( !defined $action or $action !~ /^($actionRegex)$/ ) {
	push( @useError, "--action $actionRegex required\n" );
}

if ( !defined $distribution or $distribution !~ /^($distroRegex)$/ ) {
	push( @useError, "--distribution $distroRegex required\n" );
}

if ( !defined $major or $major !~ /^\d+$/ ) {
	push( @useError, "--major # required\n" );
}

if ( !defined $minor or $minor !~ /^\d+$/ ) {
	push( @useError, "--minor # required\n" );
}

if ( !defined $architecture or $architecture !~ /^($archRegex)$/ ) {
	push( @useError, "--architecture $archRegex required\n" );
}

if ( !defined $group or $group !~ /^\d{1,3}$/ ) {
	push( @useError, "--group ### required\n" );
}

if ( !defined $instance or $instance !~ /^\d{1,2}$/ ) {
	push( @useError, "--instance # required\n" );
}

# Essential items. Error here before continuing checks.
pod2usage( @useError ) if @useError;

my $version = qq{$major.$minor};
if ( $distribution eq 'SLES' and $version !~ /^($slesVersionRegex)$/ ) {
	push( @useError, "SLES accepted versions $slesVersionRegex required\n" );
}

if ( $distribution ne 'SLES' and $version !~ /^($rhelVersionRegex)$/ ) {
	push( @useError, "$distribution accepted versions $rhelVersionRegex required\n" );
}

pod2usage( @useError ) if @useError;

my %ovfKeys = OVF::Automation::Module::convertNames( $distribution, $major, $minor, $architecture, $group, $instance );
if ( !defined $vmName and defined $ovfKeys{'vmname'} ) {
	$vmName = $ovfKeys{'vmname'};
}

my %shortDefaultVars = %{ $LIO::Vars::lio{$distribution}{$major}{$minor}{$architecture}{'defaults'} };

# Set defaults if none provided
if ( !defined $targetServer and defined $shortDefaultVars{'targetserver'} ) {
	$targetServer = $shortDefaultVars{'targetserver'};
}
if ( !defined $fabric and defined $shortDefaultVars{'fabric'} ) {
	$fabric = $shortDefaultVars{'fabric'};
}
if ( !defined $disableChap and defined $shortDefaultVars{'disable-chap'} ) {
	$disableChap = $shortDefaultVars{'disable-chap'};
}
if ( !@portals and defined $shortDefaultVars{'portals'} ) {
	@portals = $shortDefaultVars{'portals'};
}
if ( !@portalPorts and defined $shortDefaultVars{'portal-ports'} ) {
	@portalPorts = $shortDefaultVars{'portal-ports'};
}

if ( defined $action and $action =~ /^($actionRegex)$/ ) {

	if ( $action ne 'saveconfig' ) {

		if ( !defined $vmName ) {
			push( @useError, "--vmname required\n" );
		}

		if ( !defined $lioObject or $lioObject !~ /^($createRegex|$destroyRegex)$/ ) {
			push( @useError, "--lioobject $createRegex|$destroyRegex required\n" );
		}

		if ( $lioObject ne 'fileio' ) {

			if ( !defined $iqnTarget ) {
				if ( !%ovfKeys ) {
					push( @useError, "--iqntarget required\n" );
				} else {
					$iqnTarget = $shortDefaultVars{'iqntarget-prefix'} . $ovfKeys{'distribution'} . '-' . $ovfKeys{'major'} . '-' . $ovfKeys{'minor'} . '-' . $ovfKeys{'architecture'} . '-' . $ovfKeys{'group'};
				}
			}
			if ( !defined $fabric ) {
				push( @useError, "--fabric required\n" );
			}
		}

		if ( $lioObject eq 'fileio' or $lioObject eq 'luns' ) {
			if ( !@volSizes ) {
				push( @useError, "--volsizes required\n" );
			} else {
				foreach my $vol ( @volSizes ) {
					push( @useError, "--volsizes must be in units $volUnitsRegex\n" ) if ( $vol !~ /^\d+$volUnitsRegex$/ );
				}
			}
		}

		if ( $lioObject eq 'acls' or $lioObject eq 'portals' or $lioObject eq 'luns' ) {
			if ( !defined $tpgtNum and !defined $shortDefaultVars{'tpgt'} ) {
				push( @useError, "--tpgt required\n" );
			} else {
				$tpgtNum = $shortDefaultVars{'tpgt'};
			}
		}

		if ( $lioObject eq 'acls' ) {
			if ( !defined $iqnInitiator ) {
				if ( !%ovfKeys ) {
					push( @useError, "--iqninitiator required\n" );
				} else {
					$iqnInitiator = $shortDefaultVars{'iqninit-prefix'} . $ovfKeys{'distribution'} . '-' . $ovfKeys{'major'} . '-' . $ovfKeys{'minor'} . '-' . $ovfKeys{'architecture'} . '-' . $ovfKeys{'group'} . '-' . $ovfKeys{'instance'};
				}
			}
		}

		if ( $lioObject eq 'portals' ) {
			if ( !@portals ) {
				push( @useError, "--portals required\n" );
			}
			if ( !@portalPorts ) {
				push( @useError, "--portalports required\n" );
			}
			if ( scalar( @portals ) != scalar( @portalPorts ) ) {
				push( @useError, "Number of PORTALS [" . @portals . "] does not match the number of PORTAL PORTS [" . @portalPorts . "] \n" );
			}
		}

	}

}

pod2usage( @useError ) if @useError;

$options{'action'}       = $action;
$options{'distribution'} = $distribution;
$options{'distNum'}      = $ovfKeys{'distribution'};
$options{'major'}        = $major;
$options{'majNum'}       = $ovfKeys{'major'};
$options{'minor'}        = $minor;
$options{'minNum'}       = $ovfKeys{'minor'};
$options{'architecture'} = $architecture;
$options{'archNum'}      = $ovfKeys{'architecture'};
$options{'group'}        = $group;
$options{'grpNum'}       = $ovfKeys{'group'};
$options{'instance'}     = $instance;
$options{'instNum'}      = $ovfKeys{'instance'};
$options{'vmname'}       = $vmName;
$options{'targetserver'} = $targetServer;
$options{'fabric'}       = $fabric;
$options{'iqntarget'}    = $iqnTarget;
$options{'iqninit'}      = $iqnInitiator;
$options{'lioobject'}    = $lioObject;
$options{'portals'}      = [ @portals ];
$options{'portalports'}  = [ @portalPorts ];
$options{'volsizes'}     = [ @volSizes ];
$options{'tpgt'}         = $tpgtNum;
$options{'disablechap'}  = $disableChap;

LIO::Module::create( %options )     if ( $action eq 'create' );
LIO::Module::destroy( %options )    if ( $action eq 'destroy' );
LIO::Module::saveconfig( %options ) if ( $action eq 'saveconfig' );

1;

__END__

=head1 NAME

FVORGE Manage LIO

=head1 SYNOPSIS

=item B<fvorge-lio --action=create|destroy|saveconfig [--help]>

=head1 OPTIONS

=over 8

=item B<--help|-h>

Print help and exit.

=item B<--action|-a>

Action to perform of the type 'create|destroy|saveconfig'

=item B<--architecture|-arch>

Architecture of the type 'x86_64|i686'

=item B<--major|-maj>

Major of the type for RHEL varieties '5|6'
Major of the type for SLES '10|11'

=item B<--minor|-min>

Minor of the type for RHEL varieties '9|0|1|2|3|4'
Minor of the type for SLES '4|1|2'

=item B<--distribution|-distro>

Distribution of the type 'RHEL|CentOS|ORAL|SLES'

=cut

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

use OVF::Automation::Module;
use OVF::Automation::Vars;
use OVF::Vars::Common;

Sys::Syslog::openlog( 'fvorge-deploy', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

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

# May 'pull' these values from Module::get* in future
# Also to scan for and score ESX hosts for best target (local/shared storage, max cpu, max disk, max ram)
# Pick high score for deployment Module::pickTarget

my $vcenterServer;
my $vcenterUser;
my $vcenterPassword;
my $dataCenterName;
my $sourceOvf;
my $targetHost;
my $targetDatastore;
my $diskMode;
my $isoDatastore;
my $isoPath;
my $vmName;
my $vmDevice;
my $vmDeviceName;
my $propertiesOverride = 0;
my $propertiesPath;
my $snapshotName;
my $snapshotDescription;
my $quietRunning = 0;

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'help|h'                   => \$help,
	'action|a=s'               => \$action,
	'distribution|distro=s'    => \$distribution,
	'major|maj=i'              => \$major,
	'minor|min=i'              => \$minor,
	'architecture|arch=s'      => \$architecture,
	'group|g=i'                => \$group,
	'instance|n=i'             => \$instance,
	'vmname|vm=s'              => \$vmName,
	'vcenter|vc=s'             => \$vcenterServer,
	'vcenteruser|vcu=s'        => \$vcenterUser,
	'vcenterpassword|vcp=s'    => \$vcenterPassword,
	'datacenter|dc=s'          => \$dataCenterName,
	'sourceovf|sovf=s'         => \$sourceOvf,
	'targethost|thost=s'       => \$targetHost,
	'targetdatastore|tds=s'    => \$targetDatastore,
	'diskmode|dm=s'            => \$diskMode,
	'isodatastore|isod=s'      => \$isoDatastore,
	'isopath|isop=s'           => \$isoPath,
	'vmdevice|vd=s'            => \$vmDevice,
	'vmdevicename|vdn=s'       => \$vmDeviceName,
	'propoverride|po!'         => \$propertiesOverride,
	'proppath|pp=s'            => \$propertiesPath,
	'snapshotname|sn=s'        => \$snapshotName,
	'snapshotdescription|sd=s' => \$snapshotDescription,
	'quiet|q!' => \$quietRunning,
) or pod2usage( 2 );

pod2usage( 1 ) if $help;

#pod2usage( -exitstatus => 0, -verbose => 2 ) if $man;

my $actionRegex   = $OVF::Automation::Vars::actionRegex;
my $vmDeviceRegex = $OVF::Automation::Vars::vmDeviceRegex;

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

my %shortDefaultVars = %{ $OVF::Automation::Vars::automate{$distribution}{$major}{$minor}{$architecture}{'defaults'} };
my %shortVars        = %{ $OVF::Automation::Vars::automate{$distribution}{$major}{$minor}{$architecture} };

# Set defaults if none provided
if ( !defined $diskMode and defined $shortDefaultVars{'diskmode'} ) {
	$diskMode = $shortDefaultVars{'diskmode'};
}
if ( !defined $isoDatastore and defined $shortDefaultVars{'isodatastore'} ) {
	$isoDatastore = $shortDefaultVars{'isodatastore'};
}
if ( !defined $isoPath and defined $shortVars{'iso'} ) {
	$isoPath = $shortVars{'iso'};
}
if ( !defined $vcenterServer and defined $shortDefaultVars{'vcenterserver'} ) {
	$vcenterServer = $shortDefaultVars{'vcenterserver'};
}
if ( !defined $vcenterUser and defined $shortDefaultVars{'vcenteruser'} ) {
	$vcenterUser = $shortDefaultVars{'vcenteruser'};
}
if ( !defined $vcenterPassword and defined $shortDefaultVars{'vcenterpassword'} ) {
	$vcenterPassword = $shortDefaultVars{'vcenterpassword'};
}
if ( !defined $dataCenterName and defined $shortDefaultVars{'datacentername'} ) {
	$dataCenterName = $shortDefaultVars{'datacentername'};
}
if ( !defined $sourceOvf and defined $shortDefaultVars{'sourceovfbaseurl'} ) {
	$sourceOvf = $shortDefaultVars{'sourceovfbaseurl'} . $ovfKeys{'sourceovf'};
}
if ( !defined $targetHost and defined $shortDefaultVars{'targethost'} ) {
	$targetHost = $shortDefaultVars{'targethost'};
}
if ( !defined $targetDatastore and defined $shortDefaultVars{'targetdatastore'} ) {
	$targetDatastore = $shortDefaultVars{'targetdatastore'};
}

if ( defined $action and $action =~ /^($actionRegex)$/ ) {

	if ( !defined $vmName ) {
		push( @useError, "--vmname required\n" );
	}

	if ( !defined $vcenterServer ) {
		push( @useError, "--vcenter required\n" );
	}

	if ( !defined $vcenterUser ) {
		push( @useError, "--vcenteruser required\n" );
	}

	if ( !defined $vcenterPassword ) {
		push( @useError, "--vcenterpassword required\n" );
	}
}

if ( defined $action and ( $action eq 'attach' or $action eq 'detach' ) ) {

	if ( !defined $vmDevice or $vmDevice !~ /^($vmDeviceRegex)$/ ) {
		push( @useError, "--vmdevice $vmDeviceRegex required\n" );
	}

	if ( $action eq 'attach' and defined $vmDevice and $vmDevice eq 'iso' ) {
		if ( !defined $isoDatastore ) {
			push( @useError, "--isodatastore required\n" );
		}
		if ( !defined $isoPath ) {
			push( @useError, "--isopath required\n" );
		}
	}
	
	if ( defined $vmDevice and $vmDevice ne 'iso' ) {
		if ( !defined $vmDeviceName ) {
			push( @useError, "--vmdevicename required\n" );
		}
	}
}

if ( defined $action and $action eq 'deploy' ) {

	if ( !defined $sourceOvf ) {
		push( @useError, "--sourceovf required\n" );
	}

	if ( !defined $targetHost ) {
		push( @useError, "--targethost required\n" );
	}

	if ( !defined $targetDatastore ) {
		push( @useError, "--targetdatastore required\n" );
	}

	if ( !defined $dataCenterName ) {
		push( @useError, "--datacenter required\n" );
	}

}

pod2usage( @useError ) if @useError;

$options{action}              = $action;
$options{distribution}        = $distribution;
$options{distNum}             = $ovfKeys{'distribution'};
$options{major}               = $major;
$options{majNum}              = $ovfKeys{'major'};
$options{minor}               = $minor;
$options{minNum}              = $ovfKeys{'minor'};
$options{architecture}        = $architecture;
$options{archNum}             = $ovfKeys{'architecture'};
$options{group}               = $group;
$options{grpNum}              = $ovfKeys{'group'};
$options{instance}            = $instance;
$options{instNum}             = $ovfKeys{'instance'};
$options{vmname}              = $vmName;
$options{vcenter}             = $vcenterServer;
$options{vcenteruser}         = $vcenterUser;
$options{vcenterpassword}     = $vcenterPassword;
$options{datacenter}          = $dataCenterName;
$options{sourceovf}           = $sourceOvf;
$options{targethost}          = $targetHost;
$options{targetdatastore}     = $targetDatastore;
$options{diskmode}            = $diskMode;
$options{isodatastore}        = $isoDatastore;
$options{isopath}             = $isoPath;
$options{vmdevice}            = $vmDevice;
$options{vmdevicename}        = $vmDeviceName;
$options{propoverride}        = $propertiesOverride;
$options{proppath}            = $propertiesPath;
$options{snapshotname}        = $snapshotName;
$options{snapshotdescription} = $snapshotDescription;
$options{quietrunning} = $quietRunning;

OVF::Automation::Module::deploy( %options )  if ( $action eq 'deploy' );
OVF::Automation::Module::destroy( %options ) if ( $action eq 'destroy' );
OVF::Automation::Module::power( %options ) if ( $action =~ /^(poweron|poweroff|suspend|reset|reboot|shutdown)$/ );
OVF::Automation::Module::device( %options ) if ( $action eq 'attach' or $action eq 'detach' );
OVF::Automation::Module::snapshot( %options ) if ( $action eq 'snapshot' );

1;

__END__

=head1 NAME

FVORGE Deploy and Manage OVF Virtual Appliance

=head1 SYNOPSIS

=item B<fvorge-deploy --action=deploy --distribution --major --minor --architecture --group --instance --vcenter --vcenteruser --vcenterpassword [--vmname] [--help]>

=item B<fvorge-deploy --action=attach|detach --vmname --vmdevice=iso|net|disk --vmdevicename --vcenter --vcenteruser --vcenterpassword --vmname [--help]>

=item B<fvorge-deploy --action=attach --vmname --vmdevice=iso --vmdevicename --isopath --isodatastore --vcenter --vcenteruser --vcenterpassword --vmname [--help]>

=item B<fvorge-deploy --action=destroy|poweron|poweroff --vcenter --vcenteruser --vcenterpassword --vmname [--help]>

=head1 OPTIONS

=over 8

=item B<--help|-h>

Print help and exit.

=item B<--action|-a>

Action to perform of the type 'deploy|destroy|poweron|poweroff|suspend|reset|reboot|shutdown|snapshot|attach|detatch'

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

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

# Make bundled VMware packages LAST for unit tests; but not overriding system libs.
BEGIN { push ( @INC, ( '/opt/fvorge/lib/perl', '../lib/perl' ) );
	# To allow https connections with unverified SSL certs.
	# From VMware: https://communities.vmware.com/message/2444510
	$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use strict;
#use warnings;

#use Switch;
use Getopt::Long;
use Pod::Usage;
use Pod::Text;
use Pod::Text::Termcap;
use Sys::Syslog;

use OVF::Automation::Module;
use OVF::Automation::Vars;
use OVF::Vars::Common;

# All important vCLI
# fvorge-minions.deb includes vCLI and ovftool from VMware
use VMware::VIRuntime;

Sys::Syslog::openlog( 'fvorge-manage', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

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

my $vcenterServer;
my $vcenterUser;
my $vcenterPassword;
my $dataCenter;
my $sourceOvf;
my $targetHost;
my $targetDatastore;
my $diskMode;
my $isoDatastore;
my $isoPath;
my $vmName;
my $vmDevice;
my $vmDeviceName;
my $propertiesOverride;
my $snapshotName;
my $snapshotDescription;
my $snapshotMemory = 0;
my $snapshotQuiesce = 0;
my $vmFolder;
my $cluster;
my $net;
my $overwrite;
my $verbose = 0;

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'help|h'                   => \$help,
	'action|a=s'               => \$action,
	'distribution|distro=s'    => \$distribution,
	'major|maj=s'              => \$major,
	'minor|min=s'              => \$minor,
	'architecture|arch=s'      => \$architecture,
	'group|g=i'                => \$group,
	'instance|i=i'             => \$instance,
	'vmname|vm=s'              => \$vmName,
	'vcenter|vc=s'             => \$vcenterServer,
	'vcenteruser|vcu=s'        => \$vcenterUser,
	'vcenterpassword|vcp=s'    => \$vcenterPassword,
	'datacenter|dc=s'          => \$dataCenter,
	'sourceovf|sovf=s'         => \$sourceOvf,
	'targethost|thost=s'       => \$targetHost,
	'targetdatastore|tds=s'    => \$targetDatastore,
	'diskmode|dm=s'            => \$diskMode,
	'folder|f=s'               => \$vmFolder,
	'cluster|c=s'              => \$cluster,
	'net|n=s'                  => \$net,
	'overwrite|o!'             => \$overwrite,
	'isodatastore|isod=s'      => \$isoDatastore,
	'isopath|isop=s'           => \$isoPath,
	'vmdevice|vd=s'            => \$vmDevice,
	'vmdevicename|vdn=s'       => \$vmDeviceName,
	'propoverride|po=s'        => \$propertiesOverride,
	'snapshotname|sn=s'        => \$snapshotName,
	'snapshotdescription|sd=s' => \$snapshotDescription,
	'snapshotmemory|sm!'       => \$snapshotMemory,
	'snapshotquiesce|sq!'      => \$snapshotQuiesce,
	'verbose|v!'               => \$verbose
) or pod2usage( -verbose => 1, -exitstatus => 2 );

pod2usage( -verbose => 3, -exitstatus => 0 ) if $help;

$options{action}              = $action;
$options{distribution}        = $distribution;
$options{major}               = $major;
$options{minor}               = $minor;
$options{architecture}        = $architecture;
$options{group}               = $group;
$options{instance}            = $instance;
$options{vmname}              = $vmName;
$options{vcenter}             = $vcenterServer;
$options{vcenteruser}         = $vcenterUser;
$options{vcenterpassword}     = $vcenterPassword;
$options{datacenter}          = $dataCenter;
$options{cluster}             = $cluster;
$options{net}                 = $net;
$options{folder}              = $vmFolder;
$options{sourceovf}           = $sourceOvf;
$options{targethost}          = $targetHost;
$options{targetdatastore}     = $targetDatastore;
$options{diskmode}            = $diskMode;
$options{isodatastore}        = $isoDatastore;
$options{isopath}             = $isoPath;
$options{vmdevice}            = $vmDevice;
$options{vmdevicename}        = $vmDeviceName;
$options{propoverride}        = $propertiesOverride;
$options{snapshotname}        = $snapshotName;
$options{snapshotdescription} = $snapshotDescription;
$options{snapshotmemory}      = $snapshotMemory;
$options{snapshotquiesce}     = $snapshotQuiesce;
$options{verbose}             = $verbose;

my $actionRegex   = $OVF::Automation::Vars::actionRegex;
my $powerRegex    = $OVF::Automation::Vars::powerRegex;
my $deviceRegex   = $OVF::Automation::Vars::deviceRegex;
my $snapshotRegex = $OVF::Automation::Vars::snapshotRegex;
my $deployName    = $OVF::Automation::Vars::deployName;
my $destroyName   = $OVF::Automation::Vars::destroyName;

if ( !defined $action or $action !~ /^($actionRegex)$/ ) {
	push( @useError, "--action $actionRegex required\n" );
}

OVF::Automation::Module::handleUseError( @useError );

# If vcenter, vcenteruser, vcenterpassword not set attempt to fetch from
# the envirionment variables.
setVcenterCredentials( \%options );

OVF::Automation::Module::deploy( %options )  if ( $action =~ /^$deployName$/ );
OVF::Automation::Module::destroy( %options ) if ( $action =~ /^$destroyName$/ );
OVF::Automation::Module::power( %options ) if ( $action =~ /^($powerRegex)$/ );
OVF::Automation::Module::device( %options ) if ( $action =~ /^($deviceRegex)$/ );
OVF::Automation::Module::snapshot( %options ) if ( $action =~ /^($snapshotRegex)$/ );

sub setVcenterCredentials( \% ) {

	# Set VMware vCenter details from $ENV environment variables if not provided
	# from the command line options.
	
	my $optionsRef = shift;

	$optionsRef->{'vcenter'} = $ENV{'FVORGE_VCENTER'} if ( !defined $optionsRef->{'vcenter'} and defined $ENV{'FVORGE_VCENTER'} );
	$optionsRef->{'vcenteruser'} = $ENV{'FVORGE_VCENTERUSER'} if ( !defined $optionsRef->{'vcenteruser'} and defined $ENV{'FVORGE_VCENTERUSER'} );
	$optionsRef->{'vcenterpassword'} = $ENV{'FVORGE_VCENTERPASSWORD'} if ( !defined $optionsRef->{'vcenterpassword'} and defined $ENV{'FVORGE_VCENTERPASSWORD'} );

}

1;

__END__

=head1 NAME

FVORGE Manage OVF and Virtual Machines

=head1 SYNOPSIS

FVORGE Manage B<deploys> or B<destroys> VMware OVF/OVA appliances in the VMware environment and manages other lifecyles for the VMware Virtual Guest.

VM lifecycles include B<power> operations, B<snapshot> operations and B<attach> or B<detach> of connectable devices and ISO images.

VMware vCenter details and VM guest name are B<I<required>> for all management operations and actions. See B<I<REQUIRED>> section.

=head2 DEPLOY

=over 4

=item fvorge-manage B<--action|-a>=I<deploy> I<REQUIRED> B<--sourceovf|-sovf>=I<URL> B<--datacenter|-dc>=I<NAME> B<--targethost|-thost>=I<NAME> B<--targetdatastore|-tds>=I<NAME> [--cluster|-c=I<NAME>] [--net|n=I<SOURCE_NAME=TARGET_NAME>[;S=T[;S=T]] [--overwrite|-o] [--propoverride|-po=I<FILE|ovfprop=ovfvalue[;;;ovfprop=ovfvalue]>] [--diskmode|-dm=I<thin>] [--folder|-f=<NAME>]

=back

=head2 DESTROY

=over 4

=item fvorge-manage B<--action|-a>=I<destroy> I<REQUIRED>

=back

=head2 POWER

=over 4

=item fvorge-manage B<--action|-a>=I<poweron|poweroff|suspend|reset|reboot|shutdown> I<REQUIRED>

=back

=head2 SNAPSHOT

=head3 CREATE

=over 4

=item fvorge-manage B<--action|-a>=I<snapshot> I<REQUIRED> [--snapshotname|-sn=I<NAME>] [--snapshotdescription|-sd=I<NAME>] [--snapshotmemory|-sm] [--snapshotquiesce|-sq]

=back

=head3 REVERT

=over 4

=item fvorge-manage B<--action|-a>=I<snapshot-revert> I<REQUIRED> [--snapshotname|-sn=I<NAME>]

If B<--snapshotname> I<not> provided the VM guest will revert to the most B<recent> snapshot.

=back

=head3 DESTROY

=over 4

=item fvorge-manage B<--action|-a>=I<snapshot-destroy> I<REQUIRED> [--snapshotname|-sn=I<NAME>]

If B<--snapshotname> I<not> provided the VM guest will destroy B<all> snapshots. B<Child snapshots will be destroyed>.

=back

=head2 DEVICE

=head3 CONNECTABLE

=head4 ATTACH

=over 4

=item fvorge-manage B<--action|-a>=I<attach> I<REQUIRED> B<--vmdevice|-vd>=I<connectable> B<--vmdevicename|-vdn>=I<NAME>

=back

=head4 DETACH

=over 4

=item fvorge-manage B<--action|-a>=I<detach> I<REQUIRED> B<--vmdevice|-vd>=I<connectable> B<--vmdevicename|-vdn>=I<NAME>

=back

=head4 LIST

=over 4

=item fvorge-manage B<--action|-a>=I<list> I<REQUIRED> B<--vmdevice|-vd>=I<connectable>

=back

=head3 ISO
	
=head4 ATTACH

=over 4

=item fvorge-manage B<--action|-a>=I<attach> I<REQUIRED> B<--vmdevice|-vd>=I<iso> B<--isodatastore|-isod>=I<NAME> B<--isopath|-isop>=I<FILE>

=back

=head4 DETACH

=over 4

=item fvorge-manage B<--action|-a>=I<detach> I<REQUIRED> B<--vmdevice|-vd>=I<iso>

=back

=head4 LIST

=over 4

=item fvorge-manage B<--action|-a>=I<list> I<REQUIRED> B<--vmdevice|-vd>=I<iso>

=back

=head1 REQUIRED

VMware vCenter details and VM guest name are B<I<required>> for all management operations and actions.

=head3 VMware vCenter SERVER and CREDENTIALS

VMware vCenter server and credentials my be provided via command line options I<and/or> environment variables.

=head4 COMMAND LINE

=over 4

=item B<--vcenter|-vc> I<VCENTER_SERVER>

=item B<--vcenteruser|-vcu> I<USERNAME>

=item B<--vcenterpassword|-vcp> I<PASSWORD>

=back

=head4 ENVIRONMENT

=over 4

=item B<$FVORGE_VCENTER>=I<VCENTER_SERVER>

=item B<$FVORGE_VCETERUSER>=I<USERNAME>

=item B<$FVORGE_VCENTERPASSWORD>=I<PASSWORD>

=back

=head3 VM Guest NAME

A VM guest name may be provided via B<--vmname|-vm> I<VM_Guest_Name> I<or> it may be B<derived> from distribution details. See B<OPTIONS:DERIVE VM Guest NAME>

=head1 OPTIONS

=over 4

=item B<--help|-h>

Print help and exit.

=item B<--action|-a> deploy|destroy|poweron|poweroff|suspend|reset|reboot|shutdown|snapshot|snapshot-revert|snapshot-destroy|attach|detatch|list

Action to perform.

=item B<--vcenter|-vc> VCENTER_SERVER

B<REQUIRED> for all operations and actions. The VMware vCenter Server host to connect.

=item B<--vcenteruser|-vcu> USERNAME

B<REQUIRED> for all operations and actions. The VMware vCenter Server username with adequate privileges.

=item B<--vcenterpassword|-vcp> PASSWORD

B<REQUIRED> for all operations and actions. The VMware vCenter Server username password.

=item B<--vmname|-vm> NAME

B<REQUIRED> for all operations and actions. If I<not> provided it will be B<derived> from distribution details. See B<OPTIONS:DERIVE VM Guest NAME>

=item B<--datacenter|-dc> NAME

The VMware Datacenter name.

=item B<--targethost|-thost> NAME

The VMware ESX Host name.

=item B<--targetdatastore|-tds> NAME

The VMWare ESX Host Datastore name.

=item B<--diskmode|-dm> thin

The disk mode to use when deploying an OVF/OVA appliances vmdk disk. If I<not> provided the default is B<thin>.

=item B<--cluster|-c> NAME

The VMware ESX Cluster name in the Datacenter. Only required if B<--targethost> is in a named cluster.

=item B<--net|-n> SOURCE_NAME=TARGET_NAME[;S=T[;S=T]]

The VMware ESX Network to associate each VM guest network interface. Optional if there is only one defined network. If more than one network and I<not> provided the first network is assigned. Example: I<VM Network=VM Network - 1G>

=item B<--folder|-f> NAME

The VMware Datacenter Folder to assign the VM guest. If provided the Folder B<must> exist. It will not be created.

=item B<--overwrite|-o>

Deploying an OVF/OVA will not overwrite an existing guest by the same name. Enable this option to overwrite an existing VM guest of the same name.

=item B<--propoverride|-po> FILE

The file path to override an OVF/OVA's defined properties. All properties enumerated in the file must exist in the OVF/OVA's defined properties. See B<OVF PROPERTIES OVERRIDE>.

=item B<--snapshotname|-sn> NAME

The name to assign a snapshot. If I<not> provided the current date and time will be used.

=item B<--snapshotdescription|-sd> NAME

The description for a snapshot. If I<not> provided the snapshot description will be 'FVORGE AUTOMATION'.

=item B<--snapshotmemory|-sm>

If provided and the state of the VM guest is B<poweredOn> then the memory state will be included with the snapshot.

=item B<--snapshotquiesce|-sq>

If provided and the state of the VM guest is B<poweredOn> then the system will be quiesced for the snapshot.

=item B<--vmdevice|-vd> iso|connectable

The VM guest device to perform an action=list|attach|detach. If I<iso> and the VM guest state is B<poweredOn> then the guest may have a lock on the CD/DVD device and may present a lock warning in the vCenter Server GUI.

=item B<--vmdevicename|-vdn> NAME

The VM guest device to perform attach|detach. Example: "Network adapter 1"

=item B<--isodatastore|-isod> NAME

The VMware ESX Host Datastore name where the ISO image is located.

=item B<--isopath|-isop> FILE

The full path of the ISO image file in the Datastore.

=item B<--verbose|-v>

Will produce more command details during execution.
 
=back

=head2 OVF PROPERTIES OVERRIDE

A file should contain OVF properties B<matching> the properties defined in the OVF/OVA. The overriding properties should be in the following format with each property=value on a newline. Commented lines begin with B<#>.

=head3 FORMAT

=over 4

=item # Comment

=item "OVFPropertyName"="OVFOverrideValue"

=item ...

=back

=head3 EXAMPLE

=over 4

=item "host"="distribution=Ubuntu major=14 minor=04 architecture=x86_64 cluster=900 instance=10"

=item "host.time.zone"="US/Eastern"

=item "lite.network.ipv4"="192.168.10.128"

=item "lite.network.ipv4-bootproto"="static"

=item "lite.network.ipv4-prefix"="255.255.252.0"

=item "lite.network.label"="eth0"

=item "network.domain"="sc.steeleye.com"

=item "network.gateway.ipv4"="192.168.107.254"

=item "network.hostname"="minion10"

=item "network.resolv.nameservers"="192.168.60,192.168.100.75"

=item "network.resolv.search"="steeleye.com,sc.steeleye.com"

=back

=head2 DERIVE VM Guest NAME

=over 4

=item B<--distribution|-distro>

Distribution of the type B<RHEL|CentOS|ORAL|SLES|Ubuntu>

=item B<--major|-maj>

A string value matching the distribution major number. Ubuntu 14.04 x86_64 B<major> value is 14.

=item B<--minor|-min>

A string value matching the distribution minor number. Ubuntu 14.04 x86_64 B<minor> value is 04.

=item B<--architecture|-arch>

Architecture of the type B<x86_64|i686>

=item B<--group|-g>

Arbitrary grouping integer from B<0-999>

=item B<--instance|-i>

Arbitrary instance integer from B<0-99>.

=item Example:

Ubuntu 14.04 x86_64 is -distro Ubuntu -maj 14 -min 04 -arch x86_64 -group 100 -i 1 and the derived B<--vmname> becomes B<Ubuntu-14.04-x86_64-100-1> A derived name is most useful when performing batch operations. See I<fvorge-minions>.


=back

=cut

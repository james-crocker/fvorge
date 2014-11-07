#!/usr/bin/perl
#
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

BEGIN { 
	@INC = ( "/opt/fvorge/lib/perl", "../../../lib/perl", @INC );
	# To allow https connections with unverified SSL certs.
	# From VMware: https://communities.vmware.com/message/2444510
	$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";
	$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use POSIX;
use strict;
#use warnings;
use Config::File;
use File::Basename;

use OVF::Automation::Module;

my $ovfManagePath = '/opt/fvorge/bin/fvorge-manage.pl';

my $powerActions = q{poweroff|poweron|reset|shutdown|reboot};
my $batchActions = qq{deploy|destroy|snapshot|$powerActions};

sub usage() {
	printf STDERR "\nUsage: %s <my_batch.cf> $batchActions bg\n", basename( $0 );
	exit 1;
}

my $config        = defined($ARGV[ 0 ]) ? $ARGV[ 0 ] : undef;
my $ovfAction     = defined($ARGV[ 1 ]) ? $ARGV[ 1 ] : undef;
my $ovfBackground = defined($ARGV[ 2 ]) ? $ARGV[ 2 ] : undef;

if ( ( !defined $config and ! -e $config ) or $ovfAction !~ /($batchActions)/ ) {
	usage();
}

my $vars = Config::File::read_config_file( $config );    # parse the user's batch config

if ( !defined $vars ) {
	print STDERR "\nError: Failed to read settings from config file \"$config\"\n";
	usage();
}

my ( $nameRef, $instanceRef, $targethostRef, $targetdatastoreRef, $vcenterRef, $vcenteruserRef, $vcenterpasswordRef, $proppathRef, $datacenterRef, $sourceovfRef, $diskmodeRef, $folderRef, $clusterRef, $distributionRef, $majorRef, $minorRef, $architectureRef, $groupRef) = ovfCheckArgs();

my @name            = @{ $nameRef };
my @instance        = @{ $instanceRef };
my @targethost      = @{ $targethostRef };
my @targetdatastore = @{ $targetdatastoreRef };
my @vcenter         = @{ $vcenterRef };
my @vcenteruser     = @{ $vcenteruserRef };
my @vcenterpassword = @{ $vcenterpasswordRef };
my @proppath        = @{ $proppathRef };
my @datacenter      = @{ $datacenterRef };
my @sourceovf       = @{ $sourceovfRef };
my @diskmode        = @{ $diskmodeRef };
my @folder          = @{ $folderRef };
my @cluster         = @{ $clusterRef };
my @distribution    = @{ $distributionRef };
my @major           = @{ $majorRef };
my @minor           = @{ $minorRef };
my @architecture    = @{ $architectureRef };
my @group           = @{ $groupRef };
	
if ( $ovfAction eq 'destroy' ) {
	ovfDestroy();
} elsif ( $ovfAction =~ /($powerActions)/ ) {
	ovfPower( $ovfAction );
} elsif ( $ovfAction eq 'deploy' ) {
	ovfDeploy();
} elsif ( $ovfAction eq 'snapshot' ) {
	ovfSnapshot();
}

sub getBulkArguments( $ ) {
	
	my $vmCount = shift;
	
	my $args = qq{ \\\n--distribution="$distribution[ $vmCount ]" \\
--major="$major[ $vmCount ]" \\
--minor="$minor[ $vmCount ]" \\
--architecture="$architecture[ $vmCount ]" \\
--group="$group[ $vmCount ]" \\
--instance="$instance[ $vmCount ]" \\
--vmname="$name[ $vmCount ]" \\
--targethost="$targethost[ $vmCount ]" \\
--targetdatastore="$targetdatastore[ $vmCount ]" \\
--vcenter="$vcenter[ $vmCount ]" \\
--vcenteruser="$vcenteruser[ $vmCount ]" \\
--vcenterpassword="$vcenterpassword[ $vmCount ]" \\
--datacenter="$datacenter[ $vmCount ]" \\
--sourceovf="$sourceovf[ $vmCount ]" \\
--diskmode="$diskmode[ $vmCount ]"};

	if ( defined $cluster[ $vmCount ] and $cluster[ $vmCount ] ne 'null' ) {
		$args .= qq{ \\\n--cluster="$cluster[ $vmCount ]"};
	}

	if ( defined $folder[ $vmCount ] and $folder[ $vmCount ] ne 'null' ) {
		$args .= qq{ \\\n--folder="$folder[ $vmCount ]"};
	}

	if ( defined $proppath[ $vmCount ] and $proppath[ $vmCount ] ne 'null' ) {
		$args .= qq{ \\\n--propoverride \\\n--proppath="$proppath[ $vmCount ]"};
	}
	
	return $args;
	
}

sub getCommand( $$ ) {
	
	my $action = shift;
	my $vmCount = shift;
	
	my $cmd = $ovfManagePath;
	$cmd .= qq{ \\\n--action="$action"};
	if ( $action eq 'snapshot' ) {
		# Default to snapshot with Memory and Quiesce TRUE
		$cmd .= qq{ \\\n--snapshotmemory \\\n--snapshotquiesce}
	}
	$cmd .= getBulkArguments( $vmCount );
	# Caution - must have previously authenticated otherwise loops waiting for input
	$cmd .= q{ &} if ( defined $ovfBackground );
	
	return $cmd;

}

sub ovfDeploy () {
	
	my $vmCount = 0;
	foreach my $name ( @name ) {
		print "Deploying $name ...\n";
		my $cmd = getCommand( 'deploy', $vmCount );
		#print "DEPLOY $cmd\n";
		system( $cmd ) == 0 or ( print STDERR "Could not deploy $name\n" );
		$vmCount++;
	}
	
}

sub ovfDestroy () {

	my $vmCount = 0;
	foreach my $name ( @name ) {
		print "Destroying $name ...\n";
		my $cmd = getCommand( 'destroy', $vmCount );
		#print "DESTROY $cmd\n";
		system( $cmd ) == 0 or ( print STDERR "Could not destroy $name\n" );
		$vmCount++;
	}

}

sub ovfPower ( $ ) {

	my $powerAction = shift;
	my $vmCount = 0;
	foreach my $name ( @name ) {
		print "Power " . uc($powerAction) . " $name ...\n";
		my $cmd = getCommand( $powerAction, $vmCount );
		#print "POWER $powerAction $cmd\n";
		system( $cmd ) == 0 or ( print STDERR "Could not $powerAction $name\n" );
		$vmCount++;
	}
	
}

sub ovfSnapshot () {

	# snapshot will affect vm in any state, eg. powered on|off
	# snapshot will default to quiesce and memory TRUE
	# snapshot will be named and described with defaults
	my $vmCount = 0;
	foreach my $name ( @name ) {
		print "Snapshot $name ...\n";
		my $cmd = getCommand( 'snapshot', $vmCount );
		#print "SNAPSHOT $cmd\n";
		system( $cmd ) == 0 or ( print STDERR "Could not snapshot $name\n" );
		$vmCount++;
	}
	
}

sub ovfCheckArgs () {

	my @useError;
	my $vmName;

	my $distroRegex      = q{RHEL|CentOS|ORAL|SLES|Ubuntu};
	my $archRegex        = q{x86_64|i686};
	my $rhelVersionRegex = q{5\.9|6\.0|6\.1|6\.2|6\.3|6\.4};
	my $slesVersionRegex = q{10\.4|11\.1|11\.2};
	my $ubuntuVersionRegex = q{14\.04|14\.10};

	# Get and check args for OVF deployment
	my @name             = split(/,\s*/, $vars->{'name'} );
	my @distribution     = split(/,\s*/, $vars->{'distribution'} );
	my @major            = split(/,\s*/, $vars->{'major'} );
	my @minor            = split(/,\s*/, $vars->{'minor'} );
	my @architecture     = split(/,\s*/, $vars->{'architecture'} );
	my @group            = split(/,\s*/, $vars->{'group'} );
	my @instance         = split(/,\s*/, $vars->{'instance'} );
	my @targethost       = split(/,\s*/, $vars->{'targethost'} );
	my @targetdatastore  = split(/,\s*/, $vars->{'targetdatastore'} );
	my @vcenter          = split(/,\s*/, $vars->{'vcenter'} );
	my @vcenteruser      = split(/,\s*/, $vars->{'vcenteruser'} );
	my @vcenterpassword  = split(/,\s*/, $vars->{'vcenterpassword'} );
	my @proppath         = split(/,\s*/, $vars->{'proppath'} );
	my @datacenter       = split(/,\s*/, $vars->{'datacenter'} );
	my @sourceovf        = split(/,\s*/, $vars->{'sourceovf'} );
	my @diskmode         = split(/,\s*/, $vars->{'diskmode'} );
	my @cluster          = split(/,\s*/, $vars->{'cluster'} );
	my @folder           = split(/,\s*/, $vars->{'folder'} );

	if ( scalar( @name ) != scalar( @distribution ) ) {
		push( @useError, "Number of distribution doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @major ) ) {
		push( @useError, "Number of major doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @minor ) ) {
		push( @useError, "Number of minor doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @architecture ) ) {
		push( @useError, "Number of architrecture doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @group ) ) {
		push( @useError, "Number of group doesn't match the number of name\n" );
	}	
	
	if ( scalar( @name ) != scalar( @instance ) ) {
		push( @useError, "Number of instance doesn't match the number of name\n" );
	}	

	if ( scalar( @name ) != scalar( @targethost ) ) {
		push( @useError, "Number of targethost doesn't match the number of name\n" );
	}

	if ( scalar( @name ) != scalar( @targetdatastore ) ) {
		push( @useError, "Number of targetdatastore doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @vcenter ) ) {
		push( @useError, "Number of vcenter doesn't match the number of name\n" );
	}

	if ( scalar( @name ) != scalar( @vcenteruser ) ) {
		push( @useError, "Number of vcenteruser doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @vcenterpassword ) ) {
		push( @useError, "Number of vcenterpassword doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @proppath ) ) {
		push( @useError, "Number of proppath doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @datacenter ) ) {
		push( @useError, "Number of datacenter doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @sourceovf ) ) {
		push( @useError, "Number of sourceovf doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @diskmode ) ) {
		push( @useError, "Number of diskmode doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @cluster ) ) {
		push( @useError, "Number of cluster doesn't match the number of name\n" );
	}
	
	if ( scalar( @name ) != scalar( @folder ) ) {
		push( @useError, "Number of folder doesn't match the number of name\n" );
	}
	
	# Create a vmname based on the name and other properties and validate arguments.
	my $i = 0;
	foreach my $name ( @name ) {	
		my @valUseError = OVF::Automation::Module::validateArguments( $distribution[ $i ], $major[ $i ], $minor[ $i ], $architecture[ $i ], $group[ $i ], $instance[ $i ] );
		push( @useError, @valUseError ) if ( @valUseError );
		my %ovfKeys = OVF::Automation::Module::convertNames( $distribution[ $i ], $major[ $i ], $minor[ $i ], $architecture[ $i ], $group[ $i ], $instance[ $i ] );
		if ( defined $ovfKeys{'vmname'} ) {
			$name = $name . '-' . $ovfKeys{'vmname'};
		}
		$i++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	return ( \@name, \@instance, \@targethost, \@targetdatastore, \@vcenter, \@vcenteruser, \@vcenterpassword, \@proppath, \@datacenter, \@sourceovf, \@diskmode, \@folder, \@cluster, \@distribution, \@major, \@minor, \@architecture, \@group);

}

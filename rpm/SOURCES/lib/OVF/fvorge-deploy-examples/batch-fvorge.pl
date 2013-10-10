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

use lib "../libs";
use POSIX;
use strict;
use warnings;

## INSTALL PERL ConfigFile and UNCOMMENT use;
#use ConfigFile;

sub usage() {
	printf STDERR "\nUsage: %s <my_batch.cf> deploy|destroy\n", basename( $0 );
	exit 1;
}

my $config      = $ARGV[ 0 ];
my $ovfDeploy   = 0;
my $ovfDestroy  = 0;

if ( ! -e $config or $ARGV[ 1 ] eq '' ) {
	usage();
}

if ( $ARGV[ 1 ] eq 'destroy' ) {
	$ovfDestroy = 1;
} else {
	$ovfDeploy = 1;
}

my $vars = ConfigFile::Parse( $config );    # parse the user's batch config

if ( !defined $vars ) {
	print STDERR "\nError: Failed to read settings from config file \"$config\"\n";
	usage();
}

my $settings = ConfigFile::Settings( $vars );
my @systems = ConfigFile::Setting( $settings, 'systems' );
my $systems = join '-', @systems;
my $variables_file = ConfigFile::Setting( $settings, 'variables_file' );

ovfDestroy() if ( $ovfDestroy );	
ovfDeploy() if ( $ovfDeploy );

sub ovfDeploy () {

	my ( $systemsRef, $instancesRef, $targethostsRef, $targetdatastoresRef, $distribution, $major, $minor, $architecture, $group, $ovfBaseActionCmd ) = ovfCheckArgs();

	my @systems          = @{$systemsRef};
	my @instances        = @{$instancesRef};
	my @targethosts      = @{$targethostsRef};
	my @targetdatastores = @{$targetdatastoresRef};

	my @useError;

	my $vmCount = 0;
	foreach my $system ( @systems ) {
		print "Deploying OVF Virtual Appliance $system ...\n";
		my $cmd = $ovfBaseActionCmd . ' --action=deploy --propoverride --instance="' . $instances[ $vmCount ] . '" --targethost="' . $targethosts[ $vmCount ] . '" --targetdatastore="' . $targetdatastores[ $vmCount ] . '"';
		print "$cmd\n";
		system( $cmd ) == 0 or ( push( @useError, "Could not deploy OVF Virtual Appliance $system\n" ) );
		$vmCount++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	# Attach ISO
	$vmCount  = 0;
	@useError = ();
	foreach my $system ( @systems ) {
		print "Attaching ISO for OVF Virtual Appliance $system ...\n";
		my $cmd = $ovfBaseActionCmd . ' --action=attach --instance=' . $instances[ $vmCount ] . ' --vmdevice=iso';
		print "$cmd\n";
		system( $cmd ) == 0 or ( push( @useError, "Could not attach ISO to OVF Virtual Appliance $system\n" ) );
		$vmCount++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	# Poweron the VM
	$vmCount  = 0;
	@useError = ();
	foreach my $system ( @systems ) {
		print "Powering on for OVF Virtual Appliance $system ...\n";
		my $cmd = $ovfBaseActionCmd . ' --action=poweron --instance=' . $instances[ $vmCount ];
		print "$cmd\n";
		system( $cmd ) == 0 or ( push( @useError, "Could not poweron OVF Virtual Appliance $system\n" ) );
		$vmCount++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	# ALLOW THE VM TO CONFIGURE ITSELF BEFORE PROCEEDING
	# SHOULD HAVE SOMETHING MORE CLEVER THAN A TIMEOUT
	print "Sleeping 10 min. while the OVF Virtual Appliances configure themselves ...\n";
	sleep 600;

}

sub ovfDestroy () {

	my ( $systemsRef, $instancesRef, $targethostsRef, $targetdatastoresRef, $distribution, $major, $minor, $architecture, $group, $ovfBaseActionCmd ) = ovfCheckArgs();

	my @systems          = @{$systemsRef};
	my @instances        = @{$instancesRef};
	my @targethosts      = @{$targethostsRef};
	my @targetdatastores = @{$targetdatastoresRef};

	my @useError;

	# Since all tests passed - destroy the VM
	# Poweroff the VM
	my $vmCount = 0;
	foreach my $system ( @systems ) {
		print "Powering off for OVF Virtual Appliance $system ...\n";
		my $cmd = $ovfBaseActionCmd . ' --action=poweroff --instance=' . $instances[ $vmCount ];
		print "$cmd\n";
		system( $cmd ) == 0 or ( push( @useError, "Could not poweroff OVF Virtual Appliance $system\n" ) );
		$vmCount++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	$vmCount  = 0;
	@useError = ();
	foreach my $system ( @systems ) {
		print "Destroying OVF Virtual Appliance $system ...\n";
		my $cmd = $ovfBaseActionCmd . ' --action=destroy --instance=' . $instances[ $vmCount ];
		print "$cmd\n";
		system( $cmd ) == 0 or ( push( @useError, "Could not destroy OVF Virtual Appliance $system\n" ) );
		$vmCount++;
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

}

sub ovfCheckArgs () {

	my @useError;

	my $distroRegex      = q{RHEL|CentOS|ORAL|SLES};
	my $archRegex        = q{x86_64|i686};
	my $rhelVersionRegex = q{5\.9|6\.0|6\.1|6\.2|6\.3|6\.4};
	my $slesVersionRegex = q{10\.4|11\.1|11\.2};

	# Get and check args for OVF deployment
	my @systems          = ConfigFile::Setting( $settings, 'systems' );
	my @instances        = ConfigFile::Setting( $settings, 'instances' );
	my @targethosts      = ConfigFile::Setting( $settings, 'targethosts' );
	my @targetdatastores = ConfigFile::Setting( $settings, 'targetdatastores' );

	my $distribution = ConfigFile::Setting( $settings, 'distribution' );
	my $major        = ConfigFile::Setting( $settings, 'major' );
	my $minor        = ConfigFile::Setting( $settings, 'minor' );
	my $architecture = ConfigFile::Setting( $settings, 'architecture' );
	my $group        = ConfigFile::Setting( $settings, 'group' );

	if ( scalar( @systems ) != scalar( @instances ) ) {
		push( @useError, "Number of instances doesn't match the number of systems\n" );
	}

	if ( scalar( @systems ) != scalar( @targethosts ) ) {
		push( @useError, "Number of targethosts doesn't match the number of systems\n" );
	}

	if ( scalar( @systems ) != scalar( @targetdatastores ) ) {
		push( @useError, "Number of targetdatastores doesn't match the number of systems\n" );
	}

	if ( !defined $distribution or $distribution !~ /^($distroRegex)$/ ) {
		push( @useError, "distribution $distroRegex required\n" );
	}

	if ( !defined $major or $major !~ /^\d+$/ ) {
		push( @useError, "major # required\n" );
	}

	if ( !defined $minor or $minor !~ /^\d+$/ ) {
		push( @useError, "minor # required\n" );
	}

	if ( !defined $architecture or $architecture !~ /^($archRegex)$/ ) {
		push( @useError, "architecture $archRegex required\n" );
	}

	my $version = qq{$major.$minor};
	if ( $distribution eq 'SLES' and $version !~ /^($slesVersionRegex)$/ ) {
		push( @useError, "SLES accepted versions $slesVersionRegex required\n" );
	}

	if ( $distribution ne 'SLES' and $version !~ /^($rhelVersionRegex)$/ ) {
		push( @useError, "$distribution accepted versions $rhelVersionRegex required\n" );
	}

	if ( !defined $group or $group !~ /^\d{1,3}$/ ) {
		push( @useError, "group ### required\n" );
	}

	foreach my $instance ( @instances ) {
		if ( !defined $instance or $instance !~ /^\d{1,2}$/ ) {
			push( @useError, "instance # required\n" );
		}
	}

	if ( @useError ) {
		foreach my $err ( @useError ) {
			print STDERR "$err";
		}
		exit 5;
	}

	my $ovfBaseActionCmd = qq{/opt/fvorge/bin/fvorge-deploy --distribution="$distribution" --major="$major" --minor="$minor" --architecture="$architecture" --group="$group"};

	return ( \@systems, \@instances, \@targethosts, \@targetdatastores, $distribution, $major, $minor, $architecture, $group, $ovfBaseActionCmd );

}

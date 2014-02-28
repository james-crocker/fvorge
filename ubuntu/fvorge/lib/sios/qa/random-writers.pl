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

use strict;

#use warnings;

use POSIX;
use Getopt::Long;
use Pod::Usage;
use Sys::Syslog;

Sys::Syslog::openlog( 'random-writers', 'nofatal,ndelay,noeol,nonul,pid', 'local6' );

my @useError;
my %options;
my $help      = 0;
my $verbosity = 1;

my $sizeUnitRegex     = q{b|kB|K|MB|M|GB|G|TB|T};
my $bsLimitBUnitRegex = q{b};
my $bsLimitKUnitRegex = q{kB|K};
my $bsLimitMUnitRegex = q{MB|M};
my $bsLimitGUnitRegex = q{GB|G};
my $bsLimitTUnitRegex = q{TB|T};
my $styleRegex        = q{delete|overwrite};
my $fillRegex         = q{zero|one|urandom};

my $numWriters = 1;
my $path;
my $sizeMin;
my $sizeMax;
my $sleepMin;
my $sleepMax;
my $writeStyle   = 'delete';
my $fill         = 'zero';
my $limit        = 0;
my $quietRunning = 0;
my $bsLimit      = '100MB';

## Getopts ----------------------------------------------
Getopt::Long::GetOptions(
	'help|h'           => \$help,
	'number|n=i'       => \$numWriters,
	'path|p=s'         => \$path,
	'sizemin|smin=s'   => \$sizeMin,
	'sizemax|smax=s'   => \$sizeMax,
	'sleepmin|slmin=i' => \$sleepMin,
	'sleepmax|slmax=i' => \$sleepMax,
	'style|s=s'        => \$writeStyle,
	'limit|l=i'        => \$limit,
	'fill|f=s'         => \$fill,
	'bslimit|bl=i'     => \$bsLimit,
	'quiet|q!'         => \$quietRunning

) or pod2usage( 2 );

pod2usage( 1 ) if $help;

my $sizeMinNum;
my $sizeMaxNum;
my $sizeMinUnit;
my $sizeMaxUnit;

my $ddLimitBs;
my $ddLimitUnit;

if ( !defined $numWriters or $numWriters !~ /^\d+$/ ) {
	push( @useError, "--number One or more digits greater than 0 required\n" );
}

if ( defined $numWriters and $numWriters <= 0 ) {
	push( @useError, "--number One or more digits greater than 0 required\n" );
}

if ( !defined $bsLimit or $bsLimit !~ /^\d+($sizeUnitRegex)$/ ) {
	push( @useError, "--bslimit One or more digits required with units of $sizeUnitRegex\n" );
} elsif ( $bsLimit =~ /^(\d+)($sizeUnitRegex)$/ ) {
	$ddLimitBs   = $1;
	$ddLimitUnit = $2;
	if ( $ddLimitBs <= 0 ) {
		push( @useError, "--bslimit One or more digits greater than 0 required\n" );
	}
}

if ( !defined $sizeMin or $sizeMin !~ /^\d+($sizeUnitRegex)$/ ) {
	push( @useError, "--sizemin One or more digits required with units of $sizeUnitRegex\n" );
} elsif ( $sizeMin =~ /^(\d+)($sizeUnitRegex)$/ ) {
	$sizeMinNum  = $1;
	$sizeMinUnit = $2;
	if ( $sizeMinNum <= 0 ) {
		push( @useError, "--sizemin One or more digits greater than 0 required\n" );
	}
}

if ( !defined $sizeMax or $sizeMax !~ /^\d+($sizeUnitRegex)$/ ) {
	push( @useError, "--sizemax One or more digits required with units of $sizeUnitRegex\n" );
} elsif ( $sizeMax =~ /^(\d+)($sizeUnitRegex)$/ ) {
	$sizeMaxNum  = $1;
	$sizeMaxUnit = $2;
	if ( $sizeMaxNum <= 0 ) {
		push( @useError, "--sizemax One or more digits greater than 0 required\n" );
	}
}

if ( ( defined $sizeMinNum and defined $sizeMaxNum ) and ( $sizeMinNum >= $sizeMaxNum ) ) {
	push( @useError, "--sizemin must be less than --sizemax\n" );
}

if ( ( defined $sizeMinUnit and defined $sizeMaxUnit ) and ( $sizeMinUnit ne $sizeMaxUnit ) ) {
	push( @useError, "--sizemin and --sizemax must have the same units; one of $sizeUnitRegex\n" );
}

if ( !defined $sleepMin or $sleepMin !~ /^\d+$/ or $sleepMin <= 0 ) {
	push( @useError, "--sleepmin One or more digits greater than 0 required\n" );
}

if ( !defined $sleepMax or $sleepMax !~ /^\d+$/ or $sleepMax <= 0 ) {
	push( @useError, "--sleepmax One or more digits greater than 0 required\n" );
}

if ( !defined $limit or $limit !~ /^\d+$/ or $limit < 0 ) {
	push( @useError, "--limit One or more digits >= 0 required\n" );
}

if ( $sleepMin >= $sleepMax ) {
	push( @useError, "--sleepmin must be less than --sleepmax\n" );
}

if ( !defined $writeStyle or $writeStyle !~ /^($styleRegex)$/ ) {
	push( @useError, "--style $styleRegex required\n" );
}

if ( !defined $fill or $fill !~ /^($fillRegex)$/ ) {
	push( @useError, "--fill $fillRegex required\n" );
}

if ( !defined $path ) {
	push( @useError, "--path required\n" );
} elsif ( !-d $path ) {
	push( @useError, "--path $path is not a directory or does not exist\n" );
}

pod2usage( @useError ) if @useError;

my @randWriters;

for ( my $i = 1; $i < ( $numWriters + 1 ); $i++ ) {
	push( @randWriters, "random-writer-$i" );
}

foreach my $writer ( @randWriters ) {
	my $pid;
	next if $pid = fork;    # Parent goes to next server.
	die "fork failed: $!" unless defined $pid;

	Sys::Syslog::openlog( $writer, 'nofatal,ndelay,noeol,nonul,pid', 'user' );

	my $msg = qq{$writer of ($numWriters writers) spawned :: Limit $limit :: Path $path :: SleepMin $sleepMin :: SleepMax $sleepMax :: SizeMin $sizeMin :: SizeMax $sizeMax :: Style $writeStyle};
	print "$msg\n";
	Sys::Syslog::syslog( 'info', $msg );

	my $limitCount = $limit;
	my $loopCount  = 1;
	my $syncLoop   = 1;
	my $ddSleep    = 3;

	while ( $limitCount or $limit == 0 ) {

		$limitCount--;
		$loopCount++;

		# From here on, we're in the child.  Do whatever the
		# child has to do...  The server we want to deal
		# with is in $server.

		my $randSleep = getRandomSleep();
		my $randSize  = getRandomSize();

		my ( $managedSize, $managedUnit, $managedCount ) = getMemManaged( $randSize, $sizeMaxUnit );

		my $randFile = qq{$path/$writer};
		my $rmCmd    = qq{rm -f $randFile};
		my $writeCmd = qq{dd conv=fdatasync if=/dev/$fill of=$randFile bs=$managedSize$managedUnit count=$managedCount};
		my $syncCmd  = qq{sync};

		if ( $writeStyle eq 'delete' and -f $randFile ) {
			unless ( system( $rmCmd ) == 0 ) {
				$msg = qq{$writer couldn't delete $randFile};
				print "$msg\n";
				Sys::Syslog::syslog( 'err', $msg );
				die;
			}
		}

		unless ( system( qq{$writeCmd > /dev/null 2>&1} ) == 0 ) {
			$msg = qq{$writer couldn't $writeCmd};
			print "$msg\n";
			Sys::Syslog::syslog( 'err', $msg );
			$msg = qq{$writer deleting $randFile};
			print "$msg\n";
			Sys::Syslog::syslog( 'info', $msg );
			unless ( system( $rmCmd ) == 0 ) {
				$msg = qq{$writer couldn't delete $randFile};
				print "$msg\n";
				Sys::Syslog::syslog( 'err', $msg );
				die;
			}
		}

		$msg = qq{$writer syncing filesystems ($syncLoop times)};
		print "$msg\n";
		Sys::Syslog::syslog( 'info', $msg );
		for ( my $i = 0; $i < $syncLoop; $i++ ) {
			unless ( system( qq{$syncCmd > /dev/null 2>&1} ) == 0 ) {
				$msg = qq{$writer couldn't $syncCmd};
				print "$msg\n";
				Sys::Syslog::syslog( 'err', $msg );
				die;
			}
		}

		$msg = "$writer (write $loopCount) successful $writeCmd with (sync $syncLoop times)";
		print "$msg\n";
		Sys::Syslog::syslog( 'info', $msg );

		$msg = "$writer sleeping for $randSleep seconds before $writeStyle and re-write";
		print "$msg\n";
		Sys::Syslog::syslog( 'info', $msg );

		sleep $randSleep;
	}

	exit;    # Ends the child process.
}

# The following waits until all child processes have
# finished, before allowing the parent to die.

1 while ( wait() != -1 );

print "All done!\n";

exit;

sub getRandomSleep() {
	my $randSleepMax = 0;

	while ( $randSleepMax == 0 or $randSleepMax < $sleepMin ) {
		$randSleepMax = int( rand( $sleepMax ) );
	}

	return $randSleepMax;
}

sub getRandomSize() {
	my $randSizeMax = 0;

	while ( $randSizeMax == 0 or $randSizeMax < $sizeMinNum ) {
		$randSizeMax = int( rand( $sizeMaxNum ) );
	}

	return $randSizeMax;
}

sub getMemManaged($$) {
	my $askedBs   = shift;
	my $askedUnit = shift;

	my $bsBytes;
	my $bsCount;
	my $bsByteLimit;

	if ( $askedUnit =~ /^$bsLimitBUnitRegex$/ ) {
		$bsBytes = $askedBs;
	} elsif ( $askedUnit =~ /^$bsLimitKUnitRegex$/ ) {
		$bsBytes = $askedBs * 1024;
	} elsif ( $askedUnit =~ /^$bsLimitMUnitRegex$/ ) {
		$bsBytes = $askedBs * 1024 * 1024;
	} elsif ( $askedUnit =~ /^$bsLimitGUnitRegex$/ ) {
		$bsBytes = $askedBs * 1024 * 1024 * 1024;
	} elsif ( $askedUnit =~ /^$bsLimitTUnitRegex$/ ) {
		$bsBytes = $askedBs * 1024 * 1024 * 1024 * 1024;
	}

	if ( $ddLimitUnit =~ /^$bsLimitBUnitRegex$/ ) {
		$bsByteLimit = $ddLimitBs;
	} elsif ( $ddLimitUnit =~ /^$bsLimitKUnitRegex$/ ) {
		$bsByteLimit = $ddLimitBs * 1024;
	} elsif ( $ddLimitUnit =~ /^$bsLimitMUnitRegex$/ ) {
		$bsByteLimit = $ddLimitBs * 1024 * 1024;
	} elsif ( $ddLimitUnit =~ /^$bsLimitGUnitRegex$/ ) {
		$bsByteLimit = $ddLimitBs * 1024 * 1024 * 1024;
	} elsif ( $ddLimitUnit =~ /^$bsLimitTUnitRegex$/ ) {
		$bsByteLimit = $ddLimitBs * 1024 * 1024 * 1024 * 1024;
	}

	if ( $bsBytes <= $bsByteLimit ) {
		return ( $askedBs, $askedUnit, 1 );
	} else {
		$bsCount = floor( $bsBytes / $bsByteLimit );
		return ( $ddLimitBs, $ddLimitUnit, $bsCount );
	}

}

1;

__END__

=head1 NAME

FVORGE Random Writers

=head1 SYNOPSIS

=item B<random-writers --sizemin --sizemax --sleepmin --sleepmax --path [--fill] [--limit] [--number] [--help] [--style]>

=head1 OPTIONS

=over 8

=item B<--help|-h>

Print help and exit

=item B<--sizemin|-smin 10M>

Minimum SIZE greater than 0 for random output file size [ b, kB, K, MB, M, GB, G, TB, T ]

=item B<--sizemax|-smax 100M>

Maximum SIZE greater than 0 and MIN for random output file size [ b, kB, K, MB, M, GB, G, TB, T ]

=item B<--sleepmin|-slmin 5>

Minimum SLEEP time greater than 0 (in seconds) before next random write

=item B<--sleepmax|-slmax 60>

Maximum SLEEP time greater than 0 and MAX (in seconds) before next random write

=item B<--path|-p /some/path/randomFilesDirectory>

Path directory where the random files will be managed

=item B<--number|-n>

Number of writers, greater than 0, to spawn. Default is 1

=item B<--style|-s delete|overwrite>

Whether the random files are overwritten or deleted on writes. Default is 'delete'

=item B<--limit|-l #>

Limit the number of writing iterations per writer. Default is 0 which is non-terminating.

=item B<--fill|-f #>

Fill type. zero|one|urandom Default is zero

=cut

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

package SIOS::Logger;

use strict;
use warnings;

use lib '../../perl';

use SIOS::BuildVars;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## HELPERS -------------------------------------------------------------

sub logIt {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my ( $verbosity, $parentCaller, $subLevel, $type, $message ) = @_;

	return unless ( $verbosity >= 1 or $type =~ /^(die|warn)$/ios );

	my $indent = "\t" x $subLevel;

	my $formatedMessage;

	# Return die and warn regardless of verbosity
	if ( $type =~ /^(die|warn|result)$/ios ) {
		if ( $verbosity <= 1 ) {
			$formatedMessage = qq{$message} if ( $message );
		} elsif ( $verbosity > 1 ) {
			$formatedMessage .= qq{\n$parentCaller} if ( $parentCaller );
			$formatedMessage .= qq{$indent}         if ( $indent );
			$formatedMessage .= qq{$message}        if ( $message );
		}
	} else {
		$formatedMessage .= qq{$parentCaller} if ( $parentCaller );
		$formatedMessage .= qq{$indent}       if ( $indent );
		$formatedMessage .= qq{$message}      if ( $message );
	}

	if ( $type =~ /^die$/ios ) {
		die $formatedMessage;
	} elsif ( $type =~ /^warn$/ios ) {
		warn $formatedMessage;
	} else {
		print $formatedMessage;
	}

}

1;

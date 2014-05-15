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

package OVF::Custom::Module;

use strict;
use warnings;

use Digest::MD5;
use POSIX;

use lib '../../../perl';
use OVF::Manage::Tasks;
use OVF::State;

sub apply ( $$\% ) {

	my $property = shift;
	my $priority = shift;
	my %options  = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $priorityExpect = 'before|after';

	( Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: property Not defined} )                                and return ) if ( !defined $property );
	( Sys::Syslog::syslog( 'info', qq{$action $property ::SKIP:: priority Not defined} )                      and return ) if ( !defined $priority );
	( Sys::Syslog::syslog( 'info', qq{$action $property ($priority) ::SKIP:: ... OVF $property NOT DEFINED} ) and return ) if ( !defined $options{ovf}{current}{$property} );

	if ( !OVF::State::ovfIsChanged( $property, %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current $property same as Previous property} );
		return;
	}

	foreach my $num ( sort keys %{ $options{ovf}{current}{$property} } ) {

		my $customPriority = lc( $options{ovf}{current}{$property}{$num}{priority} );
		my $customAction   = $options{ovf}{current}{$property}{$num}{'action'};
		my $expect         = $options{ovf}{current}{$property}{$num}{'expect'};

		( Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority ::SKIP:: OVF priority NOT DEFINED} )         and next ) if ( !defined $customPriority );
		( Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority ::SKIP:: OVF priority NOT $priorityExpect} ) and next ) if ( $customPriority !~ /^($priorityExpect)$/ );
		( Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority ::SKIP:: OVF action NOT DEFINED} )           and next ) if ( !defined $customAction );

		if ( $customPriority eq $priority ) {

			if ( !exists $options{ovf}{previous} ) {
				Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority :: $customAction ...} );
				OVF::Manage::Tasks::runExpect( $expect, $customAction, %options );
			} elsif ( exists $options{ovf}{previous}{$property}{$num} ) {

				my @previous = OVF::State::printOvfProperties( '', %{ $options{ovf}{previous}{$property}{$num} } );
				my @current  = OVF::State::printOvfProperties( '', %{ $options{ovf}{current}{$property}{$num} } );
				if ( Digest::MD5::md5_hex( @previous ) eq Digest::MD5::md5_hex( @current ) ) {
					Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority :: $customAction (expect:$expect) ::SKIP:: Current properties same as Previous} );
					next;
				} else {
					Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority :: $customAction ...} );
					OVF::Manage::Tasks::runExpect( $expect, $customAction, %options );
				}

			} else {
				Sys::Syslog::syslog( 'info', qq{$action $property ($num) $priority :: $customAction ...} );
				OVF::Manage::Tasks::runExpect( $expect, $customAction, %options );
			}

		}

	}

}

1;

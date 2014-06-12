# Copyright (c) 2014 SIOS Technology Corp.  All rights reserved.

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

package OVF::Service::Time::Zone::Module;

use strict;
use warnings;
use POSIX;
use Storable;

use lib '../../../../../perl';
use OVF::Manage::Files;
use OVF::Service::Time::Zone::Vars;
use OVF::State;
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub apply (\%) {
	my %options = %{(shift)};

	my $thisSubName = (caller(0))[3];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	# Check if any config before processing
	if ( !defined $OVF::Service::Time::Zone::Vars::time{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( OVF::State::ovfIsChanged( 'time.*', %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ...} );
		destroy( \%options );
		create( \%options );
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current time.* same as Previous properties} );
		return;
	}
}

sub create (\%) {
	my %options = %{(shift)};

	my $thisSubName = (caller(0))[3];

	my $action = $thisSubName;

	my %currentOvf = %{ $options{ovf}{current} };
	my $arch       = $currentOvf{'host.architecture'};
	my $distro     = $currentOvf{'host.distribution'};
	my $major      = $currentOvf{'host.major'};
	my $minor      = $currentOvf{'host.minor'};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	my %timeVars = %{ $OVF::Service::Time::Zone::Vars::time{$distro}{$major}{$minor}{$arch} };

	my %generatedFiles;    # Collect created files for later creation

	my %timezoneTemplate = %{Storable::dclone($timeVars{files}{timezone})};
	my %localtimeDef = %{Storable::dclone($timeVars{localtime})};
	my %taskDef = %{Storable::dclone($timeVars{task})};
	my $required = [ 'host.time.zone' ];
	my $requiredEnabled = [];
	return if ( OVF::State::checkRequired( $action, $required, '', $requiredEnabled, %options ) );
	my $timezone = $currentOvf{'host.time.zone'};

	$timezoneTemplate{'apply'}{'1'}{'content'} =~ s/<TIMEZONE>/$timezone/g;
	$localtimeDef{'source'} =~ s/<TIMEZONE>/$timezone/g;
	$generatedFiles{'timezone'} = \%timezoneTemplate;
	
	$taskDef{'copysource'} =~ s/<TIMEZONE_SOURCE>/$localtimeDef{'source'}/;
	$taskDef{'copysource'} =~ s/<TIMEZONE_PATH>/$localtimeDef{'path'}/;
	OVF::Manage::Tasks::run( %options, @{ $taskDef{'copysource'} } );

	OVF::Manage::Files::create( %options, %generatedFiles );
	# now that files are in place, update debconf db, just to be tidy
	OVF::Manage::Tasks::run( %options, @{ $taskDef{'dpkgreconfig'} } );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub destroy (\%) {

	my %options = %{(shift)};

	my $thisSubName = (caller(0))[3];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	# my $rmCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	# my %timeVars = %{$OVF::Service::Time::Zone::Vars::time{$distro}{$major}{$minor}{$arch}};

	Sys::Syslog::syslog('info', qq{$action INITIATE ...});
	# ...nothing for now...
	Sys::Syslog::syslog('info', qq{$action COMPLETE});
}

1;

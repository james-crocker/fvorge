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

package OVF::Manage::Directories;

use strict;
use warnings;

use File::Path;

use lib '../../../perl';
use OVF::Vars::Common;
use SIOS::CommonVars;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub create ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $destroyCmd    = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{destroyCmd};
	my $tarCreateCmd  = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tarCreateCmd};
	my $tarExtractCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tarExtractCmd};
	my $chmodCmd      = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chmodCmd};
	my $chownCmd      = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chownCmd};
	my $chgrpCmd      = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chgrpCmd};
	my $tarExtension  = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{extension};
	my $tarPath       = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{path};

	# There is no 'default' for safely add/replace. Encumbent on files declarations with 'save' and 'concat'

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $dirName ( keys %ovfObject ) {
		
		Sys::Syslog::syslog( 'info', qq{$action START: ($dirName) ...} );

		my $path = $ovfObject{$dirName}{path};

		# save the item if provided BEFORE doing any filehandle work
		if ( -d $path and $ovfObject{$dirName}{save} ) {

			my $pathOriginal = $tarPath . '/' . $dirName . $tarExtension;

			if ( !-e $pathOriginal ) {

				# if the original doesn't exist save it
				Sys::Syslog::syslog( 'info', qq{$action SAVING: $path to $pathOriginal} );
				system( qq{$tarCreateCmd $pathOriginal $path $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't save ($pathOriginal) ($?:$!)} );
			} else {

				# restore the file to 're-edit' if needed.
				Sys::Syslog::syslog( 'info', qq{$action RECOVERING: $path from $pathOriginal FOR RE-EDIT} );
				system( qq{$tarExtractCmd $pathOriginal $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't recreate ($path) ($?:$!)} );
			}

		} elsif ( -d $path and $ovfObject{$dirName}{destroy} ) {
			Sys::Syslog::syslog( 'info', qq{$action DESTROYING: $path ...} );
			system( qq{$destroyCmd $path $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $path) ($?:$!)} );
		} elsif ( -d $path ) {
			Sys::Syslog::syslog( 'info', qq{$action EXISTS: ($path) already exists} );
		}

		if ( !-d $path ) {
			Sys::Syslog::syslog( 'info', qq{$action CREATING: $path ...} );
			mkpath( $path ) or ( Sys::Syslog::syslog( 'err', qq{$action Couldn't create [ $path ] ($?:$!)} ) and next );
		}

		if ( defined $ovfObject{$dirName}{chmod} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHMOD: (} . $ovfObject{$dirName}{chmod} . qq{) for $path} );
			system( $chmodCmd . ' ' . $ovfObject{$dirName}{chmod} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chmod $dirName) ($?:$!)} );
		}

		if ( defined $ovfObject{$dirName}{chown} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHOWN: (} . $ovfObject{$dirName}{chown} . qq{) for $path} );
			system( $chownCmd . ' ' . $ovfObject{$dirName}{chown} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chown $dirName) ($?:$!)} );
		}

		if ( defined $ovfObject{$dirName}{chgrp} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHGRP: (} . $ovfObject{$dirName}{chgrp} . qq{) for $path} );
			system( $chgrpCmd . ' ' . $ovfObject{$dirName}{chgrp} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chgrp $dirName) ($?:$!)} );
		}

		Sys::Syslog::syslog( 'info', qq{$action FINISH: ($dirName)} );
		
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \%\% ) {

	my ( %options )   = %{ ( shift ) };
	my ( %ovfObject ) = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my $destroyCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{destroyCmd};

	my $tarExtractCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{tarExtractCmd};
	my $tarExtension  = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{extension};
	my $tarPath       = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{path};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $dirName ( keys %ovfObject ) {
		
		Sys::Syslog::syslog( 'info', qq{$action START: ($dirName) ...} );

		my $dirPath = $ovfObject{$dirName}{path};

		Sys::Syslog::syslog( 'info', qq{REMOVING: $dirPath ...} );

		if ( $ovfObject{$dirName}{save} ) {

			my $pathOriginal = $tarPath . '/' . $dirName . $tarExtension;

			Sys::Syslog::syslog( 'info', qq{$action INITIATING: RECOVER of $dirName :: $dirPath from $pathOriginal ...} );

			# recover original if possible
			if ( -e $pathOriginal ) {

				# Restore the directory
				system( qq{$destroyCmd $dirPath $quietCmd} ) == 0         or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $dirPath) ($?:$!)} );
				system( qq{$tarExtractCmd $pathOriginal $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't recreate ($pathOriginal) ($?:$!)} );
				Sys::Syslog::syslog( 'info', qq{$action RECOVERED: $dirPath from $pathOriginal} );
			} else {
				Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: Backup doesn't exist ($pathOriginal) for $dirName :: $dirPath} );
			}

		} else {

			system( qq{$destroyCmd $dirPath $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $dirPath) ($?:$!)} );

		}
		
		Sys::Syslog::syslog( 'info', qq{$action FINISH: ($dirName)} );

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

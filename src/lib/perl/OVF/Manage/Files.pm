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

package OVF::Manage::Files;

use strict;
use warnings;

use File::Path;
use POSIX;
use Tie::File;

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

	foreach my $fileName ( keys %ovfObject ) {

		Sys::Syslog::syslog( 'info', qq{$action START: ($fileName) ...} );

		my $path = $ovfObject{$fileName}{path};
		my $writeMode;

		# save the item if provided BEFORE doing any filehandle work
		if ( -e $path and $ovfObject{$fileName}{save} ) {

			my $pathOriginal = $tarPath . '/' . $fileName . $tarExtension;

			if ( -e $pathOriginal and $ovfObject{$fileName}{save} ne 'once' ) {

				# restore the file to 're-edit' if needed
				Sys::Syslog::syslog( 'info', qq{$action RECOVERING: $path from $pathOriginal FOR RE-EDIT} );
				system( qq{$tarExtractCmd $pathOriginal $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't recreate ($path) ($?:$!)} );
			}

			if ( !-e $pathOriginal ) {

				# if the original doesn't exist save it
				Sys::Syslog::syslog( 'info', qq{$action SAVING: $path to $pathOriginal} );
				system( qq{$tarCreateCmd $pathOriginal $path $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't save ($pathOriginal) ($?:$!)} );
			}

		}

		if ( -e $path and $ovfObject{$fileName}{destroy} ) {
			Sys::Syslog::syslog( 'info', qq{$action DESTROYING: $path ...} );
			system( qq{$destroyCmd $path $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $path) ($?:$!)} );
		}

		my @content;
		tie @content, 'Tie::File', $path, autochomp => 0 or ( Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: Couldn't open ($path) Were the parent directories defined? ($?:$!)} ) and next );

		foreach my $applyNum ( sort keys %{ $ovfObject{$fileName}{apply} } ) {

			# REPLACE ENTIRE file with content
			if ( defined $ovfObject{$fileName}{apply}{$applyNum}{replace} ) {
				my $content = $ovfObject{$fileName}{apply}{$applyNum}{content};
				if ( defined $content ) {
					splice @content, 0, @content, $content;
					Sys::Syslog::syslog( 'info', qq{$action SUCCEED: REPLACING ENTIRE CONTENT of $path} );
				} else {
					Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: REPLACE ENTIRE CONTENT. CONTENT NOT DEFINED} );
				}

			} else {

				# REPLACE a specific line
				if ( defined $ovfObject{$fileName}{apply}{$applyNum}{line} ) {

					foreach my $key ( sort keys %{ $ovfObject{$fileName}{apply}{$applyNum}{line} } ) {

						my $lineNum = $ovfObject{$fileName}{apply}{$applyNum}{line}{$key}{number};
						my $content = $ovfObject{$fileName}{apply}{$applyNum}{line}{$key}{content};

						if ( isdigit( $lineNum ) and defined $content ) {
							$content[ $lineNum ] = $content;
							Sys::Syslog::syslog( 'info', qq{$action SUCCEED: REPLACE LINE ($lineNum) in $path} );
						} else {
							Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: REPLACE LINE NUMBER AND/OR CONTENT NOT DEFINED} );
						}
					}
				}

				# DELETE ALL occurances
				if ( defined $ovfObject{$fileName}{apply}{$applyNum}{delete} ) {

					foreach my $key ( sort keys %{ $ovfObject{$fileName}{apply}{$applyNum}{delete} } ) {

						my $regex = $ovfObject{$fileName}{apply}{$applyNum}{delete}{$key}{regex};

						if ( defined $regex ) {
							Sys::Syslog::syslog( 'info', qq{$action INITIATING: DELETE REGEX ($regex) in $path ...} );

							my $success       = 0;
							my $done          = 0;
							my $lastMatchLine = 0;

							do {

								my $currentLine = -1;
								for ( @content ) {
									$currentLine++;
									if ( $lastMatchLine and $currentLine < $lastMatchLine ) {
										next;
									} elsif ( /$regex/ ) {
										splice @content, $currentLine, 1;
										$lastMatchLine = $currentLine;
										Sys::Syslog::syslog( 'info', qq{$action SUCCEED: DELETE MATCHING REGEX at LINE ($currentLine)} );
										last;
									}
								}

								$done = 1 if ( $currentLine == $#content );

							} while ( !$done );

							Sys::Syslog::syslog( 'warning', qq{$action WARNING: NO LINES MATCHED} ) if ( !$success );
							Sys::Syslog::syslog( 'info', qq{$action COMPLETED: DELETE REGEX} );
						} else {
							Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: DELETE REGEX NOT DEFINED} );
						}
					}

				}

				# Substitute ALL occurances with content
				if ( defined $ovfObject{$fileName}{apply}{$applyNum}{substitute} ) {

					foreach my $key ( sort keys %{ $ovfObject{$fileName}{apply}{$applyNum}{substitute} } ) {

						my $regex   = $ovfObject{$fileName}{apply}{$applyNum}{substitute}{$key}{regex};
						my $content = $ovfObject{$fileName}{apply}{$applyNum}{substitute}{$key}{content};
						my $unique  = $ovfObject{$fileName}{apply}{$applyNum}{substitute}{$key}{unique};
						my $nomatch = $ovfObject{$fileName}{apply}{$applyNum}{substitute}{$key}{nomatch};

						my $isUnique;
						if ( $unique ) {
							$isUnique = 'Yes';
						} else {
							$isUnique = 'No';
						}

						# Only head or tail, skip otherwise
						if ( defined $nomatch and $nomatch !~ /^(head|tail)$/ ) {
							undef $nomatch;
						}

						# Replaces all occurances and deletes other entries if is $isUnique
						if ( defined $regex and defined $content ) {
							Sys::Syslog::syslog( 'info', qq{$action INITIATING: SUBSTITUTE REGEX ($regex) UNIQUE ($isUnique) in $path ...} );

							my $success       = 0;
							my $done          = 0;
							my $lastMatchLine = 0;

							do {

								my $currentLine = -1;
								for ( @content ) {

									$currentLine++;
									if ( $lastMatchLine and $currentLine < $lastMatchLine ) {
										next;
									} elsif ( /$regex/ ) {
										if ( $success and $unique ) {
											splice @content, $currentLine, 1;
											$lastMatchLine = $currentLine;
											Sys::Syslog::syslog( 'info', qq{$action NON-UNIQUE: DELETED MATCHING REGEX at LINE ($currentLine)} );
											last;
										} else {
											$content[ $currentLine ] = $content;
											$lastMatchLine = $content =~ tr/\n//;
											$lastMatchLine += $currentLine - 1;
											$success = 1;
											Sys::Syslog::syslog( 'info', qq{$action SUCCEED: SUBSTITUTE MATCHING REGEX at LINE ($currentLine)} );
										}
									}
								}

								$done = 1 if ( $currentLine == $#content );

							} while ( !$done );

							Sys::Syslog::syslog( 'warning', qq{$action WARNING: NO LINES MATCHED} ) if ( !$success );

							# If a nomatch directive defined then re-run the loop to tail or head the content.
							if ( !$success and $nomatch ) {
								Sys::Syslog::syslog( 'info', qq{$action REDO: $nomatch REQUESTED SINCE NO LINES MATCHED} );
								$ovfObject{$fileName}{apply}{$applyNum}{$nomatch} = 1;
								$ovfObject{$fileName}{apply}{$applyNum}{content} = $ovfObject{$fileName}{apply}{$applyNum}{substitute}{$key}{content};
								delete $ovfObject{$fileName}{apply}{$applyNum}{substitute};
								redo;
							}

							Sys::Syslog::syslog( 'info', qq{$action COMPLETED: SUBSTITUTE REGEX} );

						} else {

							Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: SUBSTITUTE REGEX AND/OR CONTENT NOT DEFINED} );

						}

					}

				}

				# Put content before a matched line of ALL occurances with content
				if ( defined $ovfObject{$fileName}{apply}{$applyNum}{before} ) {
					foreach my $key ( sort keys %{ $ovfObject{$fileName}{apply}{$applyNum}{before} } ) {

						my $regex   = $ovfObject{$fileName}{apply}{$applyNum}{before}{$key}{regex};
						my $content = $ovfObject{$fileName}{apply}{$applyNum}{before}{$key}{content};

						if ( defined $regex and defined $content ) {
							Sys::Syslog::syslog( 'info', qq{$action INITIATING: BEFORE REGEX ($regex) in $path ...} );
							my $success       = 0;
							my $done          = 0;
							my $lastMatchLine = 0;

							do {
								my $currentLine = -1;
								for ( @content ) {
									$currentLine++;
									if ( $lastMatchLine and $currentLine < $lastMatchLine ) {
										next;
									} elsif ( /$regex/ ) {
										splice @content, $currentLine, 0, $content;
										$lastMatchLine = $content =~ tr/\n//;
										$lastMatchLine = 1 if ( !$lastMatchLine );
										$lastMatchLine += $currentLine + 1;
										$success = 1;
										Sys::Syslog::syslog( 'info', qq{$action SUCCEED: BEFORE REGEX at LINE ($currentLine)} );
									}
								}
								$done = 1 if ( $currentLine == $#content );
							} while ( !$done );
							Sys::Syslog::syslog( 'warning', qq{$action WARNING: NO LINES MATCHED} ) if ( !$success );
							Sys::Syslog::syslog( 'info', qq{$action COMPLETED: BEFORE REGEX} );
						} else {
							Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: BEFORE REGEX AND/OR CONTENT NOT DEFINED} );
						}
					}

				}

				# Put content after a matched line of ALL occurances with content
				if ( $ovfObject{$fileName}{apply}{$applyNum}{after} ) {

					foreach my $key ( keys %{ $ovfObject{$fileName}{apply}{$applyNum}{after} } ) {

						my $regex   = $ovfObject{$fileName}{apply}{$applyNum}{after}{$key}{regex};
						my $content = $ovfObject{$fileName}{apply}{$applyNum}{after}{$key}{content};

						if ( defined $regex and defined $content ) {
							Sys::Syslog::syslog( 'info', qq{$action INITIATING: AFTER REGEX ($regex) in $path ...} );

							my $success       = 0;
							my $done          = 0;
							my $lastMatchLine = 0;
							do {
								my $currentLine = -1;
								for ( @content ) {
									$currentLine++;
									if ( $lastMatchLine and $currentLine < $lastMatchLine ) {
										next;
									} elsif ( /$regex/ ) {
										splice @content, ( $currentLine + 1 ), 0, $content;
										$lastMatchLine = $content =~ tr/\n//;
										$lastMatchLine = 1 if ( !$lastMatchLine );
										$lastMatchLine += $currentLine + 1;
										$success = 1;
										Sys::Syslog::syslog( 'info', qq{$action SUCCEED: AFTER REGEX at LINE ($currentLine)} );

									}
								}
								$done = 1 if ( $currentLine == $#content );
							} while ( !$done );
							Sys::Syslog::syslog( 'warning', qq{$action WARNING: NO LINES MATCHED} ) if ( !$success );
							Sys::Syslog::syslog( 'info', qq{$action COMPLETED: AFTER REGEX} );
						} else {
							Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: AFTER REGEX AND/OR CONTENT NOT DEFINED} );
						}
					}
				}

				# Put content at the head of the file
				if ( $ovfObject{$fileName}{apply}{$applyNum}{head} ) {
					unshift @content, $ovfObject{$fileName}{apply}{$applyNum}{content};
					Sys::Syslog::syslog( 'info', qq{$action SUCCEED: CONTENT at HEAD in $path} );
				}

				# Put content at the tail end of the file
				if ( $ovfObject{$fileName}{apply}{$applyNum}{tail} ) {
					push @content, $ovfObject{$fileName}{apply}{$applyNum}{content};
					Sys::Syslog::syslog( 'info', qq{$action SUCCEED: CONTENT at TAIL $path} );
				}

			}

		}

		untie @content;

		if ( defined $ovfObject{$fileName}{chmod} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHMOD: (} . $ovfObject{$fileName}{chmod} . qq{) for $path} );
			system( $chmodCmd . ' ' . $ovfObject{$fileName}{chmod} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chmod $fileName) ($?:$!)} );
		}

		if ( defined $ovfObject{$fileName}{chown} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHOWN: (} . $ovfObject{$fileName}{chown} . qq{) for $path} );
			system( $chownCmd . ' ' . $ovfObject{$fileName}{chown} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chown $fileName) ($?:$!)} );
		}

		if ( defined $ovfObject{$fileName}{chgrp} ) {
			Sys::Syslog::syslog( 'info', qq{$action CHGRP: (} . $ovfObject{$fileName}{chgrp} . qq{) for $path} );
			system( $chgrpCmd . ' ' . $ovfObject{$fileName}{chgrp} . qq{ "$path" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't (chgrp $fileName) ($?:$!)} );
		}

		Sys::Syslog::syslog( 'info', qq{$action FINISH: ($fileName)} );

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

	foreach my $fileName ( keys %ovfObject ) {

		my $path = $ovfObject{$fileName}{path};

		Sys::Syslog::syslog( 'info', qq{$action REMOVING: $path ...} );

		if ( $ovfObject{$fileName}{save} ) {

			my $pathOriginal = $tarPath . '/' . $fileName . $tarExtension;

			Sys::Syslog::syslog( 'info', qq{$action INITIATING: RECOVER of $fileName :: $path from $pathOriginal ...} );

			# recover original if possible, otherwise leave in-place file as 'create' may never have been initially called.
			if ( -e $pathOriginal ) {
				system( qq{$destroyCmd $path $quietCmd} ) == 0            or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $path) ($?:$!)} );
				system( qq{$tarExtractCmd $pathOriginal $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't recreate ($path) from ($pathOriginal) ($?:$!)} );
				Sys::Syslog::syslog( 'info', qq{$action RECOVERED: $path from $pathOriginal ...} );
			} else {
				Sys::Syslog::syslog( 'warning', qq{$action ::SKIP:: Backup doesn't exist ($pathOriginal) for $fileName :: $path} );
			}

		} else {

			system( qq{$destroyCmd $path $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{$action Couldn't ($destroyCmd $path) ($?:$!)} );

		}

	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

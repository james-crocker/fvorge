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

package OVF::Automation::Vars;

use strict;
use warnings;
use Storable;

our %automate;
my %common;

our $powerOnName             = 'poweron';
our $powerOffName            = 'poweroff';
our $suspendName             = 'suspend';
our $resetName               = 'reset';
our $rebootName              = 'reboot';
our $poweredOffName          = 'poweredoff';
our $poweredOnName           = 'poweredon';
our $suspendedName           = 'suspended';
our $shutdownName            = 'shutdown';
our $deployName              = 'deploy';
our $destroyName             = 'destroy';
our $deviceAttachName        = 'attach';
our $deviceDetachName        = 'detach';
our $deviceListName          = 'list';
our $snapshotCreateName      = 'snapshot';
our $snapshotRevertName      = 'snapshot-revert';
our $snapshotDestroyName     = 'snapshot-destroy';
our $vmDeviceIsoName         = 'iso';
our $vmDeviceConnectableName = 'connectable';
our $exportName              = 'export';
our $discoverName            = 'discover';
our $powerRegex              = qq{$powerOnName|$powerOffName|$suspendName};
$powerRegex                  .= qq{|$resetName|$rebootName|$shutdownName};
$powerRegex                  .= qq{|$poweredOnName|$poweredOffName|$suspendedName};
our $deviceRegex             = qq{$deviceAttachName|$deviceDetachName|$deviceListName};
our $snapshotRegex           = qq{$snapshotCreateName|$snapshotRevertName|$snapshotDestroyName};
our $vmDeviceRegex           = qq{$vmDeviceIsoName|$vmDeviceConnectableName};
our $actionRegex             = qq{$deployName|$destroyName|$exportName};
$actionRegex                 .= qq{|$discoverName|$powerRegex|$deviceRegex|$snapshotRegex};

our $defaultOvftoolPath         = '/usr/bin/ovftool';
our $defaultSnapshotDescription = 'FVORGE AUTOMATION';

our $ovftoolNoSslVerify         = '--noSSLVerify';

our $propOverrideSplitter       = q{\s*;;;\s*};

$common{'RHEL'} = {
    'bin' => {
        'ovftool'          => { 'path' => $defaultOvftoolPath },
    }
};

$automate{'RHEL'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'RHEL'}{6}{0}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'RHEL'}{6}{1}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'RHEL'}{6}{2}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'RHEL'}{6}{3}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'RHEL'}{6}{4}{'x86_64'} = Storable::dclone( $common{'RHEL'} );

$automate{'CentOS'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'CentOS'}{6}{0}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'CentOS'}{6}{1}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'CentOS'}{6}{2}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'CentOS'}{6}{3}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'CentOS'}{6}{4}{'x86_64'} = Storable::dclone( $common{'RHEL'} );

$automate{'ORAL'}{6}{3}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'ORAL'}{6}{4}{'x86_64'} = Storable::dclone( $common{'RHEL'} );

$automate{'SLES'}{10}{4}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'SLES'}{11}{1}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'SLES'}{11}{2}{'x86_64'} = Storable::dclone( $common{'RHEL'} );

$automate{'Ubuntu'}{14}{04}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$automate{'Ubuntu'}{14}{10}{'x86_64'} = Storable::dclone( $common{'RHEL'} );

1;

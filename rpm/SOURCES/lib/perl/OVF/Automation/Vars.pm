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

my $cdImagesPath = 'Linux';

our $actionRegex     = 'deploy|destroy|poweron|poweroff|suspend|reset|reboot|shutdown|attach|detach|snapshot';
our $vmDeviceRegex   = 'iso|net|floppy';
our $sourceOvfSuffix = '-OVF';

$common{'RHEL'} = {
	'defaults' => {
		'vcenterserver'    => 'vc1.sc.sios.com',
		'vcenteruser'      => 'Administrator',
		'vcenterpassword'  => '<YOUR_VC_PASSWORD>',
		'datacentername'   => 'SIOS QA Datacenter',
		'diskmode'         => 'thin',
		'isodatastore'     => 'hancock-cdimages',
		'sourceovfbaseurl' => 'http://fvorge.sc.sios.com/~fvorge/ovf/',
		'targethost'       => 'c10.sc.sios.com',
		'targetdatastore'  => 'c10-local2'
	},
	'bin' => {
		'removabledevices' => { 'path' => '/opt/fvorge/lib/VMware/sdk/removabledevices.pl' },
		'ovftool'          => { 'path' => '/usr/bin/ovftool' },
		'isomanage'        => { 'path' => '/opt/fvorge/lib/VMware/contrib/vmISOManagement.pl' },
		'removevm'         => { 'path' => '/opt/fvorge/lib/VMware/contrib/remove_vm.pl' },
		'powerops'         => { 'path' => '/opt/fvorge/lib/VMware/sdk/powerops.pl' },
		'snapshot'         => { 'path' => '/opt/fvorge/lib/VMware/sdk/snapshot.pl' }
	},
	'ovf-properties-root' => { 'path' => '/opt/fvorge/lib/OVF/clusters' }
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

$automate{'RHEL'}{5}{9}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL5.9/rhel-server-5.9-x86_64-dvd.iso';
$automate{'RHEL'}{6}{0}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL6.0/rhel-server-6.0-x86_64-dvd.iso';
$automate{'RHEL'}{6}{1}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL6.1/rhel-server-6.1-x86_64-dvd.iso';
$automate{'RHEL'}{6}{2}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL6.2/rhel-server-6.2-x86_64-dvd.iso';
$automate{'RHEL'}{6}{3}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL6.3/rhel-server-6.3-x86_64-dvd.iso';
$automate{'RHEL'}{6}{4}{'x86_64'}{'iso'} = $cdImagesPath . '/RHEL6.4/rhel-server-6.4-x86_64-dvd.iso';

$automate{'CentOS'}{5}{9}{'x86_64'}{'iso'} = $cdImagesPath . '/CentOS5.9/CentOS-5.9-x86_64-bin-DVD-1of2.iso';
#$automate{'CentOS'}{6}{0}{'x86_64'}{'iso'} = $cdImagesPath.'/CentOS6.0/rhel-server-6.0-x86_64-dvd.iso';
$automate{'CentOS'}{6}{1}{'x86_64'}{'iso'} = $cdImagesPath . '/CentOS6.1/CentOS-6.1-x86_64-bin-DVD1.iso';
$automate{'CentOS'}{6}{2}{'x86_64'}{'iso'} = $cdImagesPath . '/CentOS6.2/CentOS-6.2-x86_64-bin-DVD1.iso';
$automate{'CentOS'}{6}{3}{'x86_64'}{'iso'} = $cdImagesPath . '/CentOS6.3/CentOS-6.3-x86_64-bin-DVD1.iso';
$automate{'CentOS'}{6}{4}{'x86_64'}{'iso'} = $cdImagesPath . '/CentOS6.4/CentOS-6.4-x86_64-bin-DVD1.iso';

$automate{'ORAL'}{6}{3}{'x86_64'}{'iso'} = $cdImagesPath . '/OEL6.3/OracleLinux-R6-U3-Server-x86_64-dvd.iso';
$automate{'ORAL'}{6}{4}{'x86_64'}{'iso'} = $cdImagesPath . '/OEL6.4/OracleLinux-R6-U4-Server-x86_64-dvd.iso';

$automate{'SLES'}{10}{4}{'x86_64'}{'iso'} = $cdImagesPath . '/sles10-sp4/SLES-10-SP4-DVD-x86_64-GM-DVD1.iso';
$automate{'SLES'}{11}{1}{'x86_64'}{'iso'} = $cdImagesPath . '/sles11-SP1-GMC/SLES-11-SP1-DVD-x86_64-GM-DVD1.iso';
$automate{'SLES'}{11}{2}{'x86_64'}{'iso'} = $cdImagesPath . '/sles11-SP2-GMC/SLES-11-SP2-DVD-x86_64-GMC-DVD1.iso';

1;

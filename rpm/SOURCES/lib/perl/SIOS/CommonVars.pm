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

package SIOS::CommonVars;

use lib '../../perl';

use strict;
use warnings;

use SIOS::SysInfo;
use Switch 'fallthrough';

## Base Product Details ------------------------------
our $productVersionRegexPattern = '(\d+\.\d+\.\d+)';
our $productVersionLatest       = 'latest';

our %product = (
	lk => {
		name     => 'LifeKeeper',
		versions => [ $productVersionLatest, '7.5.0' ],
		gaKits   => [ '7.5.0' ]
	},

	'lk-cn' => {
		name     => 'LifeKeeper-Chinese',
		versions => [ $productVersionLatest, '8.1.0', '8.0.0' ]
	},

	lkssp => {
		name     => 'LifeKeeper SSP',
		versions => [ $productVersionLatest, '8.2.0' ],
	},

	ora => {
		name     => 'LifeKeeper-Oracle',
		versions => [ $productVersionLatest, '8.1.0', '8.0.0' ]
	},

	vapp => {
		name     => 'vAppKeeper',
		versions => [ $productVersionLatest, '7.5.0' ],
		gaKits   => [ '7.5.0' ]
	},

	sap => {
		name     => 'LifeKeeper-SAP',
		versions => [ $productVersionLatest, '8.1.0', '8.0.0', '7.5.1' ]
	},

	smc => {
		name     => 'SteelEye Management Console',
		versions => [ $productVersionLatest, '7.5.0' ]
	},

	sps => {
		name     => 'SteelEye Protection Suite',
		versions => [ $productVersionLatest, '8.2.0', '8.1.3', '8.1.2', '8.1.1', '8.1.0', '8.0.0' ],
		gaKits   => [ '8.0.0' ]
	  }

);

## DEFAULTS ----------------------------------------
our %productDefault = ( product => 'sps', version => $product{sps}{versions}[ 0 ] );

## Construct 'HELP' material ------------------------
our $productHelp = join( '|', keys %product );
our $productRegex = '^(' . join( '|', keys %product ) . ')$';

## Sys Specifics -------------------------------------
our $sysDistro  = $SIOS::SysInfo::distro;
our $sysVersion = $SIOS::SysInfo::version;
our $sysArch    = $SIOS::SysInfo::arch;

## Per System/sub Command Sets -----------------------------------------------------------
our %sysCmds;

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd} = ' > /dev/null 2>&1';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::copyLicenses'}{cpCmd} = 'cp';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::copyLicenses'}{rmCmd} = 'rm -f';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::fetchLicenses'}{scpCmd} = 'scp -r';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::fetchBuildProduct'}{scpCmd} = 'scp -r';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::fetchGaKits'}{scpCmd}       = 'scp -r';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::getRpmList'}{rpmCmd} = 'rpm -qa';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::killProcesses'}{grepCmd} = 'grep';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::killProcesses'}{killCmd} = 'kill -s SIGKILL';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::killProcesses'}{psCmd}   = 'ps -e -o pid,cmd';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::makeSetupTarget'}{rmCmd} = 'rm -rf';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::mountProduct'}{dfCmd}     = 'df -m';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::mountProduct'}{mountCmd}  = 'mount -o loop';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::mountProduct'}{umountCmd} = 'umount';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeFiles'}{rmCmd} = 'rm -f';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeLinks'}{rmCmd} = 'rm -f';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removePaths'}{rmCmd} = 'rm -rf';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeRelatedRpms'}{rpmRmCmd} = 'rpm -e --nodeps';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeGroups'}{groupDelCmd} = 'groupdel';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeGroups'}{getentCmd}   = 'getent group';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeGroups'}{awkCmd}      = 'awk \'{FS=":";print $1}\'';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeUsers'}{userDelCmd} = 'userdel';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeUsers'}{getentCmd}  = 'getent passwd';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeUsers'}{awkCmd}     = 'awk \'{FS=":";print $1}\'';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeRpms'}{grepCmd}     = 'grep';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeRpms'}{rpmFetchCmd} = 'rpm -qa';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeRpms'}{rpmRmCmd}    = 'rpm -e --nodeps';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::removeRpms'}{sortCmd}     = 'sort';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildNumber'}{lsCmd}   = 'ls -tr';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildNumber'}{sshCmd}  = 'ssh';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildNumber'}{tailCmd} = 'tail -1';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildVersion'}{lsCmd}   = 'ls -tr';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildVersion'}{sshCmd}  = 'ssh';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setBuildVersion'}{tailCmd} = 'tail -1';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setGaVersion'}{lsCmd}   = 'ls -tr';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setGaVersion'}{sshCmd}  = 'ssh';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setGaVersion'}{tailCmd} = 'tail -1';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'SIOS::Product::setupKits'}{rpmCmd} = 'rpm --install';

## Per Product Variables -----------------------------
# Product composed of:
# productKey:
#    lk, smc, vapp, etc..
# productVersion:
#    Loops through productVersions.
#    Can set unique version details. eg. $product{$productKey}{'7.4.1'}{$sysDistro}{$sysVersion}{'path'}{'var'} = '...'
# sysDistro:
#    From 'Distribution.pm'
# sysVersion:
#    From 'Distribution.pm'
# 'path' collection:
#    Directories particular to the product for erasure and other management.
# 'file' collection:
#    Files particular to the product for erasure and other management.
# 'cmd' collection:
#    Commands particular to the product for erasure and other management. eg. 'stop' = lkstop, 'start' = lkstart, etc.
#    'start': Command to start service
#    'stop':  Command to stop service
# 'iso' collection:
#    'image': ISO install/setup image
#    'mount': mount point
#

foreach my $productKey ( keys %product ) {
	foreach my $productVersion ( @{ $product{$productKey}{versions} } ) {

		# Generate commonly used regex patterns
		$product{$productKey}{versionsHelp} = join( '|', @{ $product{$productKey}{versions} } );
		$product{$productKey}{versionsRegexPattern} = '^(' . join( '|', @{ $product{$productKey}{versions} } ) . ')$';

		# Tweak for prodcutVersion, sysDistro, sysVersion peculiarities.
		# eg. if ( $sysDistro = 'redhat' ) { $product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{'path'}{'var'} = '/usr/var/LifeKeeper'; } ...

		switch ( $productKey ) {
			case 'lk' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}        = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}           = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}       = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}       = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}         = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}           = [ '/opt/LifeKeeper/bin/lkstop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}          = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}   = 'lk.img';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}           = 'de.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh} = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}  = 'jre-1.6.0_18';
			}

			case 'lk-cn' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}        = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}           = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}       = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}       = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}         = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}           = [ '/opt/LifeKeeper/bin/lkstop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}          = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}   = 'lk-cn.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh} = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}  = 'jre-1.6.0_18';
			}

			case 'lkssp' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}          = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}             = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}         = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{acresso}         = '/usr/local/share/acresso';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{macrovision}     = '/usr/local/share/macrovision';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{javaEtc}         = '/etc/.java';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes16}      = '/usr/share/icons/hicolor/16x16/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes48}      = '/usr/share/icons/hicolor/48x48/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{appregistry}     = '/usr/share/application-registry';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}         = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{defaultOld}      = '/etc/default/LifeKeeper.old';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkguiserverinit} = '/etc/init.d/lkgui-server.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{jexecinit}       = '/etc/init.d/jexec';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{log}             = '/var/log/lifekeeper.log';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{logrotate}       = '/etc/logrotate.d/lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mailcap}         = '/etc/mailcap';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mimetypes}       = '/etc/mime.types';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkrcd}           = '/etc/init.d/*/*lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeHanfs}   = '/etc/modprobe.d/lifekeeper-hanfs.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeNbd}     = '/etc/modprobe.d/lifekeeper-nbd.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{nbdKo}           = '/lib/modules/*/extra/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{perldb}          = '/root/.perldb';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{link}{nbdKo}           = '/lib/modules/*/weak-updates/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{raid1Ko}         = '/lib/modules/*/extra/raid1.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{link}{raid1Ko}         = '/lib/modules/*/weak-updates/raid1.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}           = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}          = [ '/etc/init.d/lifekeeper stop', '/etc/init.d/steeleye-runit stop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}         = '/etc/init.d/lifekeeper start';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}  = 'lkssp.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6} = 'jre-1.6.0_45';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{post}          = [ 'depmod -a' ];
			}

			case 'ora' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}        = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}           = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}       = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}       = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}         = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}           = [ '/opt/LifeKeeper/bin/lkstop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}          = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}   = 'ora.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh} = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}  = 'jre-1.6.0_18';
			}

			case 'sap' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}        = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}           = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}       = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}       = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}         = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}           = [ '/opt/LifeKeeper/bin/lkstop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}          = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}   = 'saphost.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh} = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}  = 'jre-1.6.0_18';
			}

			case 'smc' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern} = 'steeleye-smc-' . $productVersionRegexPattern;

				#$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}            = '/var/LifeKeeper';
				#$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}        = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{httpLog}                 = '/var/log/steeleye-lighttpd';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}                 = '/etc/default/LifeKeeper.pl';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}                   = "tar cvfzp /tmp/smc-$^T.tar.gz /opt/LifeKeeper /etc/default/LifeKeeper.pl /var/log/steeleye-lighttpd";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}                     = [ '/etc/init.d/steeleye-lighttpd stop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}                    = '/etc/init.d/steeleye-lighttpd start';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}             = 'smc.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{vmwareSdk}{unInstall} = '/etc/vmware-vcli/installer.sh uninstall';
			}

			case 'sps' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}          = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}             = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}         = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{acresso}         = '/usr/local/share/acresso';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{macrovision}     = '/usr/local/share/macrovision';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{javaEtc}         = '/etc/.java';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes16}      = '/usr/share/icons/hicolor/16x16/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes48}      = '/usr/share/icons/hicolor/48x48/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{appregistry}     = '/usr/share/application-registry';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}         = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{defaultOld}      = '/etc/default/LifeKeeper.old';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkguiserverinit} = '/etc/init.d/lkgui-server.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{jexecinit}       = '/etc/init.d/jexec';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{log}             = '/var/log/lifekeeper.log';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{logrotate}       = '/etc/logrotate.d/lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mailcap}         = '/etc/mailcap';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mimetypes}       = '/etc/mime.types';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkrcd}           = '/etc/init.d/*/*lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeHanfs}   = '/etc/modprobe.d/lifekeeper-hanfs.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeNbd}     = '/etc/modprobe.d/lifekeeper-nbd.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{nbdKo}           = '/lib/modules/*/extra/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{perldb}          = '/root/.perldb';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{file}{nbdKo}                   = '/lib/modules/*/kernel/drivers/block/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{link}{nbdKo}           = '/lib/modules/*/weak-updates/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{raid1Ko}         = '/lib/modules/*/extra/raid1.ko';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{file}{raid1Ko}                 = '/lib/modules/*/kernel/drivers/block/raid1.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{link}{raid1Ko}         = '/lib/modules/*/weak-updates/raid1.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}           = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop} = [ '/etc/init.d/lifekeeper stop', '/etc/init.d/steeleye-runit stop' ];
				$product{$productKey}{'8.0.0'}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}         = [ '/opt/LifeKeeper/bin/lkstop',  '/etc/init.d/steeleye-runit stop' ];
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}         = [ '/opt/LifeKeeper/bin/lkstop',  '/etc/init.d/steeleye-runit stop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}         = '/etc/init.d/lifekeeper start';
				$product{$productKey}{'8.0.0'}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}                 = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}                 = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}  = 'sps.img';
				$product{$productKey}{'8.0.0'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh}        = 'pdksh-5.2.14';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh}        = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6} = 'jre-1.6.0_45';
				$product{$productKey}{'8.1.3'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}         = 'jre-1.6.0_33';
				$product{$productKey}{'8.1.2'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}         = 'jre-1.6.0_33';
				$product{$productKey}{'8.1.0'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}         = 'jre-1.6.0_18';
				$product{$productKey}{'8.0.0'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}         = 'jre-1.6.0_18';
				$product{$productKey}{'7.5.0'}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}         = 'jre-1.6.0_18';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{post}          = [ 'depmod -a' ];
			}

			case 'vapp' {
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{regexPattern}          = 'steeleye-lk-' . $productVersionRegexPattern;
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{var}             = '/var/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{license}         = '/var/LifeKeeper/license';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{acresso}         = '/usr/local/share/acresso';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{macrovision}     = '/usr/local/share/macrovision';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{javaEtc}         = '/etc/.java';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes16}      = '/usr/share/icons/hicolor/16x16/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{mimtypes48}      = '/usr/share/icons/hicolor/48x48/mimetypes';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{appregistry}     = '/usr/share/application-registry';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{default}         = '/etc/default/LifeKeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{defaultOld}      = '/etc/default/LifeKeeper.old';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkguiserverinit} = '/etc/init.d/lkgui-server.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{jexecinit}       = '/etc/init.d/jexec';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{log}             = '/var/log/lifekeeper.log';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{logrotate}       = '/etc/logrotate.d/lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mailcap}         = '/etc/mailcap';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{mimetypes}       = '/etc/mime.types';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{lkrcd}           = '/etc/init.d/*/*lifekeeper';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeHanfs}   = '/etc/modprobe.d/lifekeeper-hanfs.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{modprobeNbd}     = '/etc/modprobe.d/lifekeeper-nbd.conf';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{nbdKo}           = '/lib/modules/*/extra/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{perldb}          = '/root/.perldb';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{nbdKo}           = '/lib/modules/*/kernel/drivers/block/nbd.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{raid1Ko}         = '/lib/modules/*/kernel/drivers/block/raid1.ko';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{backup}           = "/opt/LifeKeeper/bin/lkbackup -c -f /tmp/archive.$productKey-$productVersion-$^T.tar.gz";
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{stop}           = [ '/opt/LifeKeeper/bin/lkstop', '/etc/init.d/steeleye-runit stop' ];
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{start}          = '/opt/LifeKeeper/bin/lkstart';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{iso}{image}   = 'vapp.img';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{pdksh} = 'pdksh-5.2.14';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{related}{rpm}{jre6}  = 'jre-1.6.0_18';
				$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{cmd}{post}           = [ 'depmod -a' ];
			}

			# 'Shared' values across all products ...
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{path}{base}       = '/opt/LifeKeeper';
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{file}{installLog} = '/var/log/LK_install.log';
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{rpm}{globs}       = [ 'steeleye-', 'HADR-' ];
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{rpm}{exclude}     = [ 'steeleye-tet3-', 'steeleye-lk-testsuite-', 'fvorge-' ];
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{processName}      = 'LifeKeeper';
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{setup}{script}    = 'setup';
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{lkgroups} = [ 'lkadmin', 'lkoper', 'lkguest', 'steeleye-lighttpd' ];
			$product{$productKey}{$productVersion}{$sysDistro}{$sysVersion}{$sysArch}{lkusers} = [ 'steeleye-lighttpd' ];

		}

	}
}

1;

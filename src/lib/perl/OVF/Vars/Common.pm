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

package OVF::Vars::Common;

use strict;
use warnings;

use lib '../../../perl';
use SIOS::SysInfo;

## Common OVF Variables -----------------------------

# VMware tool to fetch OVF properties (from VMwareTOOLS being installed NOT an iso mount)
our $getOvfPropertiesCmd = q{vmtoolsd --cmd "info-get guestinfo.ovfenv"};
our $setOvfPropertiesCmd = q{vmware-rpctool};
our $setOvfPropertiesArg = 'info-set guestinfo.ovfEnv';

## Sys Specifics -------------------------------------
our $sysDistro  = $SIOS::SysInfo::distro;
our $sysVersion = $SIOS::SysInfo::version;
our $sysArch    = $SIOS::SysInfo::arch;

## Per System/sub Command Sets -----------------------------------------------------------
our %sysCmds;
our %sysVars;

$sysVars{distrosRegex}        = q{RHEL|CentOS|ORAL|SLES|Ubuntu};
$sysVars{archsRegex}          = q{x86_64|i686};
$sysVars{rhelVersionsRegex}   = q{5\.9|6\.0|6\.1|6\.2|6\.3|6\.4};
$sysVars{slesVersionsRegex}   = q{10\.4|11\.1|11\.2};
$sysVars{ubuntuVersionsRegex} = q{13\.10|14\.04|14\.10};

$sysVars{'fvorge'}{home}           = '/opt/fvorge';
$sysVars{'fvorge'}{bin}            = $sysVars{'fvorge'}{home} . '/bin';
$sysVars{'fvorge'}{'ovf-defaults'} = $sysVars{'fvorge'}{home} . '/lib/OVF/ovf-defaults.xml';

$sysVars{'retry'}{'availale'}{'max'}   = 6;
$sysVars{'retry'}{'availale'}{'sleep'} = 10;

$sysCmds{'fvorge'}{'sp-setup'} = $sysVars{'fvorge'}{bin} . '/sp-setup';
$sysCmds{'fvorge'}{'sp-erase'} = $sysVars{'fvorge'}{bin} . '/sp-erase';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{inplace} = '.fvorge-bak';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{path}      = '/root/fvorge-originals';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{originals}{extension} = '.fvorge.tar.gz';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{path} = '/root/fvorge-properties';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{file} = 'ovf';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{ovfEnv} = 'env';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{save}{properties}{vcenter} = 'vcenter';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{vmtool}{updated}{path} = '/tmp/vmtool-updated';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd}       = ' > /dev/null 2>&1';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietErrCmd}    = ' 2> /dev/null';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{redirStdErrCmd} = '2>&1';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{rebootCmd} = 'telinit 6';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{syncCmd}   = 'sync';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chmodCmd} = 'chmod';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chownCmd} = 'chown';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{chgrpCmd} = 'chgrp';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'selinuxRestoreCmd'} = 'restorecon -R -v';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{runlevelCmd} = 'runlevel | awk \'{print $2}\'';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Network::Module::destroy'}{rmCmd}             = 'rm -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Network::Module::restartNetwork'}{restartCmds} = [q(/etc/init.d/network restart)];
$sysCmds{'ubuntu'}{$sysVersion}{$sysArch}{'OVF::Network::Module::restartNetwork'}{restartCmds}   = [q(ifdown -a), q(ifup -a)];
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Network::Module::resetHostname'}{resetCmd}    = 'hostname --file /etc/hostname';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Service::Database::Oracle::Module::create'}{sysctlCmd} = 'sysctl -p';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Service::Database::Sybase::Module::create'}{sysctlCmd} = 'sysctl -p';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::label'}{partedCmd} = 'parted --script';
if ( $sysDistro eq 'centos' or $sysDistro eq 'redhat' or $sysDistro eq 'oracle enterprise linux' ) {
	if ( $sysVersion =~ /^5\./ ) {
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Service::Storage::Multipath::Module::enable'}{getuidCallout} = q("/sbin/scsi_id -g -u -s /block/%n");
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::partition'}{partedCmd}                      = 'parted --script';
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::getPartedInfo'}{partedCmd}                  = 'parted --script';
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::udevSettle'}{udevsettleCmd}                 = 'udevsettle --timeout=30';
	} else {
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Service::Storage::Multipath::Module::enable'}{getuidCallout} = q("/lib/udev/scsi_id --whitelisted --device=/dev/%n");
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::partition'}{partedCmd}                      = 'parted --script --align=opt';
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::getPartedInfo'}{partedCmd}                  = 'parted --script --machine';
		$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::udevSettle'}{udevsettleCmd}                 = 'udevadm settle --timeout=30';
	}
} else {
	$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Service::Storage::Multipath::Module::enable'}{getuidCallout} = q("/lib/udev/scsi_id --whitelisted --device=/dev/%n");
	$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::partition'}{partedCmd}                      = 'parted --script --align=opt';
	$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::getPartedInfo'}{partedCmd}                  = 'parted --script --machine';
	$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::udevSettle'}{udevsettleCmd}                 = 'udevadm settle --timeout=30';
}

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::isLvmPv'}{pvdisplayCmd}  = 'pvdisplay';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::devInUse'}{fuserCmd}     = 'fuser -s -m';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::devInUse'}{fuserReadCmd} = 'fuser -v -m';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::devInUse'}{mntListCmd}   = 'mount -l';

#$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::devInUse'}{dmListCmd}       = 'dmsetup ls --tree';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::devInUse'}{swapListCmd}     = 'swapon -s';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::makeFilesystem'}{mkfsCmd}   = 'mkfs -t';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::makeFilesystem'}{mkSwapCmd} = 'mkswap';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::getVgInfo'}{vgdisplayCmd}   = 'vgdispaly --colon';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::getLvInfo'}{lvdisplayCmd}   = 'lvdispaly --colon';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::label'}{partprobeCmd}          = 'partprobe';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::partition'}{partprobeCmd}      = 'partprobe';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::makeFilesystem'}{partprobeCmd} = 'partprobe';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::mount'}{mountCmd}     = 'mount -t';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::mount'}{mountBindCmd} = 'mount --bind';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::mount'}{mountLoopCmd} = 'mount -o loop';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::mount'}{swapOnCmd}    = 'swapon';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::umount'}{umountCmd}   = 'umount';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Storage::umount'}{swapOffCmd}  = 'swapoff';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Users::create'}{addCmd}  = 'adduser --home <HOME_DIR> --shell <SHELL> --gid <GID> --uid <UID> --password <PASSWD> --comment <COMMENT>';
$sysCmds{'suse'}{$sysVersion}{$sysArch}{'OVF::Manage::Users::create'}{addCmd}      = 'useradd --home <HOME_DIR> --shell <SHELL> --gid <GID> --uid <UID> --password <PASSWD> --comment <COMMENT>';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Groups::create'}{addCmd} = 'groupadd --gid <GID>';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Users::changePassword'}{passwdCmd}     = q{echo '<USER>:<PASSWD>' | chpasswd};
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Users::changePassword'}{crackCheckCmd} = '/usr/sbin/cracklib-check';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Users::destroy'}{destroyCmd}  = 'userdel -f -r';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Groups::destroy'}{destroyCmd} = 'groupdel';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Network::addIp'}{addCmd}          = 'ip addr add';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Network::deleteIp'}{deleteCmd}    = 'ip addr del';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Network::getIp'}{hostCmd}         = 'host';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Network::pingHost'}{pingHostCmd}  = 'ping';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Network::pingHost'}{ping6HostCmd} = 'ping6';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::install'}{pkgInstallCmd}      = 'yum -y install';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::groupInstall'}{pkgInstallCmd} = 'yum -y groupinstall';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::remove'}{pkgRemoveCmd}        = 'yum -y remove';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::groupRemove'}{pkgRemoveCmd}   = 'yum -y groupremove';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::update'}{pkgUpdateCmd}        = 'yum -y update';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::groupUpdate'}{pkgUpdateCmd}   = 'yum -y groupupdate';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::clean'}{pkgCleanCmd}          = 'yum -y clean all';
$sysCmds{'ubuntu'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::install'}{pkgInstallCmd}        = 'DEBIAN_FRONTEND="noninteractive" apt-get -y install';
$sysCmds{'ubuntu'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::remove'}{pkgRemoveCmd}          = 'DEBIAN_FRONTEND="noninteractive" apt-get -y remove';
$sysCmds{'ubuntu'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::update'}{pkgUpdateCmd}          = 'DEBIAN_FRONTEND="noninteractive" apt-get -y update';
$sysCmds{'ubuntu'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::clean'}{pkgCleanCmd}            = 'DEBIAN_FRONTEND="noninteractive" apt-get -y clean';
$sysCmds{'suse'}{'10'}{$sysArch}{'OVF::Manage::Packages::addSuseRepo'}{pkgAddSuseRepoCmd}         = 'zypper sa --t YUM --repo';
$sysCmds{'suse'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::install'}{pkgInstallCmd}          = 'zypper --non-interactive --no-gpg-checks install';
$sysCmds{'suse'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::remove'}{pkgRemoveCmd}            = 'zypper --non-interactive --no-gpg-checks remove';
$sysCmds{'suse'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::update'}{pkgUpdateCmd}            = 'zypper --non-interactive --no-gpg-checks update';
$sysCmds{'suse'}{$sysVersion}{$sysArch}{'OVF::Manage::Packages::clean'}{pkgCleanCmd}              = 'zypper --non-interactive --no-gpg-checks refresh';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Files::create'}{tarCreateCmd}        = 'tar -c -z -p -P -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Files::create'}{tarExtractCmd}       = 'tar -x -z -p -P -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Directories::create'}{tarCreateCmd}  = 'tar -c -z -p -P -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Directories::create'}{tarExtractCmd} = 'tar -x -z -p -P -f';

$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Files::create'}{destroyCmd}           = 'rm -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Files::destroy'}{destroyCmd}          = 'rm -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Directories::create'}{destroyCmd}     = 'rm -rf';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Directories::destroy'}{destroyCmd}    = 'rm -rf';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Files::destroy'}{tarExtractCmd}       = 'tar -x -z -p -P -f';
$sysCmds{$sysDistro}{$sysVersion}{$sysArch}{'OVF::Manage::Directories::destroy'}{tarExtractCmd} = 'tar -x -z -p -P -f';

1;

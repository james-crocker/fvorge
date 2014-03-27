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

package OVF::Service::Repository::Vars;

use strict;
use warnings;
use Storable;

our %packages;
my %common;

$common{'RHEL'} = {
	'mount' => {
		'source' => '/dev/sr0',
		'target' => '/media/<LC_DISTRO>',
		'fstype' => 'loop'
	},
	'files' => {
		'dvd-repo' => {
			path  => '/etc/yum.repos.d/<LC_DISTRO>-dvd.repo',
			save  => 0,
			chmod => 644,
			apply => {
				1 => {
					replace => 1,
					content => q{[dvd]
name=<DISTRO> <MAJOR>.<MINOR> <ARCH> DVD
baseurl=file:///media/<LC_DISTRO>/Server
enabled=1
gpgcheck=0}
				}
			}
		}
	}
};

$common{'RHEL'}{5}{mount} = {
	'source' => '/dev/cdrom',
	'target' => '/media/<LC_DISTRO>',
	'fstype' => 'loop'
};

$common{'CentOS'} = Storable::dclone( $common{'RHEL'} );

$common{'CentOS'}{files} = {
	'dvd-repo' => {
		path  => '/etc/yum.repos.d/<LC_DISTRO>-dvd.repo',
		save  => 0,
		chmod => 644,
		apply => {
			1 => {
				replace => 1,
				content => q{[dvd]
name=<DISTRO> <MAJOR>.<MINOR> <ARCH> DVD
baseurl=file:///media/<LC_DISTRO>/
enabled=1
gpgcheck=0}
			}
		}
	},
	'CentOS-Base.repo' => {
		path  => '/etc/yum.repos.d/CentOS-Base.repo',
		save  => 1,
		chmod => 644,
		apply => {
			1 => {
				after => {
					1 => {
						regex   => 'name\s*=\s*CentOS.+\-\s+(Updates|Extras)\s*$',
						content => q{enabled=<ENABLED>}
					}
				}
			}
		}
	}
};

$common{'Ubuntu'} = {

	# Ubuntu 14.04 Server has unattended-upgrades already installed
	#'packages' => [ 'unattended-upgrades']
	'files' => {
		'10periodic' => {
			path  => '/etc/apt/apt.conf.d/10periodic',
			save  => 0,
			chmod => 644,
			apply => {
				1 => {
					substitute => {
						1 => {
							regex   => '^\s*APT::Periodic::Download-Upgradeable-Packages\s+"0";',
							content => q{APT::Periodic::Download-Upgradeable-Packages "1";}
						},
						2 => {
                            regex   => '^\s*APT::Periodic::AutocleanInterval\s+"0";',
                            content => q{APT::Periodic::AutocleanInterval "7";}
                        }
					}
				},
				2 => {
					tail    => 1,
					content => q{APT::Periodic::Unattended-Upgrade "1";}
				}
			}
		}
	},
	'init' => {
		'unattended-upgrades' => {
			path  => '/etc/init.d/unattended-upgrades',
			stop  => '/etc/init.d/unattended-upgrades stop',
			start => '/etc/init.d/unattended-upgrades start',
			off   => 'update-rc.d unattended-upgrades disable',
			on    => 'update-rc.d unattended-upgrades enable',
		}
	}
};

$packages{'RHEL'}{5}{9}{'x86_64'} = Storable::dclone( $common{'RHEL'} );
$packages{'RHEL'}{5}{9}{'x86_64'}{mount} = $common{'RHEL'}{5}{mount};

$packages{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$packages{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$packages{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$packages{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$packages{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$packages{'CentOS'}{5}{9}{'x86_64'} = Storable::dclone( $common{'CentOS'} );
$packages{'CentOS'}{5}{9}{'x86_64'}{mount} = $common{'CentOS'}{5}{mount};

$packages{'CentOS'}{6}{0}{'x86_64'} = $common{'CentOS'};
$packages{'CentOS'}{6}{1}{'x86_64'} = $common{'CentOS'};
$packages{'CentOS'}{6}{2}{'x86_64'} = $common{'CentOS'};
$packages{'CentOS'}{6}{3}{'x86_64'} = $common{'CentOS'};
$packages{'CentOS'}{6}{4}{'x86_64'} = $common{'CentOS'};

$packages{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$packages{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$packages{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$packages{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

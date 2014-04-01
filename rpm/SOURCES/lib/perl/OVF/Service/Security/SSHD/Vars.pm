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

package OVF::Service::Security::SSHD::Vars;

use strict;
use warnings;

use Storable;

our %sshd;
my %common;

# SSHD config settings
$common{'RHEL'} = {
	'packages' => [ 'openssh-server' ],
	'files'    => {
		'sshd_config' => {
			path  => '/etc/ssh/sshd_config',
			save  => 'once',
			apply => {
				1 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*PermitRootLogin},
							content => q{PermitRootLogin <SSHD_YORN>}
						}
					}
				},
				2 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*GSSAPIAuthentication},
							content => q{GSSAPIAuthentication <SSHD_YORN>}
						}
					}
				},
				3 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*RSAAuthentication},
							content => q{RSAAuthentication <SSHD_YORN>}
						}
					}
				},
				4 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*PubkeyAuthentication},
							content => q{PubkeyAuthentication <SSHD_YORN>}
						}
					}
				},
				5 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*X11Forwarding},
							content => q{X11Forwarding <SSHD_YORN>}
						}
					}
				},
				6 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*AllowTcpForwarding},
							content => q{AllowTcpForwarding <SSHD_YORN>}
						}
					}
				},
				7 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*PasswordAuthentication},
							content => q{PasswordAuthentication <SSHD_YORN>}
						}
					}
				},
				8 => {
					substitute => {
						1 => {
							nomatch => 'tail',
							unique  => 1,
							regex   => q{^\s*\#*\s*UsePAM},
							content => q{UsePAM <SSHD_YORN>}
						}
					}
				}
			}
		}
	}
};

$common{'SLES'}   = Storable::dclone( $common{'RHEL'} );
$common{'Ubuntu'} = Storable::dclone( $common{'RHEL'} );

$common{'SLES'}{task} = {
	'open-firewall'  => [ 'yast2 --ncurses firewall services add service=service:sshd zone=EXT' ],
	'close-firewall' => [ 'yast2 --ncurses firewall services remove service=service:sshd zone=EXT' ]
};

$common{'Ubuntu'}{task} = {
	'open-firewall'  => [ '/usr/sbin/ufw allow OpenSSH' ],
	'close-firewall' => [ '/usr/sbin/ufw deny OpenSSH' ]
};

# SSHD
$sshd{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$sshd{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sshd{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sshd{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sshd{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sshd{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sshd{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$sshd{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sshd{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sshd{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sshd{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sshd{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sshd{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sshd{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sshd{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$sshd{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$sshd{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$sshd{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$sshd{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

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

package OVF::Service::Security::SSH::Vars;

use strict;
use warnings;

use Storable;

our %ssh;
our %sshd;
my %common;
my %commonSshd;

$common{'RHEL'} = {
	'directories' => {
		'home' => {
			path  => '.ssh',
			save  => 0,
			chmod => 700,
			chown => 0,
			chgrp => 0
		}
	},
	'files' => {
		'config' => {
			path  => 'config',
			save  => 0,
			chmod => 600,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  IdentityFile <SSH_BASE_PATH>/.ssh/cae-qa-anyhost-id_rsa
  ForwardX11 yes}
				}
			}
		},
		'known_hosts' => {
			path  => 'known_hosts',
			save  => 0,
			chmod => 644,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'authorized_keys' => {
			path  => 'authorized_keys',
			save  => 0,
			chmod => 600,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{#REPLACE WITH YOUR AUTHORIZED KEYS}
				}
			}
		},
		'cae-qa-anyhost-id_rsa.pub' => {
			path  => 'cae-qa-anyhost-id_rsa.pub',
			save  => 0,
			chmod => 644,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{#ssh-rsa REPLACE WITH YOUR PUBLIC KEY}
				}
			}
		},
		'cae-qa-anyhost-id_rsa' => {
			path  => 'cae-qa-anyhost-id_rsa',
			save  => 0,
			chmod => 600,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{-----BEGIN RSA PRIVATE KEY-----
REPLACE WITH YOUR PRIVATE KEY
-----END RSA PRIVATE KEY-----}
				}
			}
		}
	}
};

$common{'SLES'} = Storable::dclone( $common{'RHEL'} );

$commonSshd{'RHEL'} = {
	'files' => {
		'sshd_config' => {
			path  => '/etc/ssh/sshd_config',
			save  => 'once',
			apply => {
				1 => {
					substitute => {
						1 => {
							unique  => 1,
							regex   => q{^\#*PermitRootLogin},
							content => q{PermitRootLogin yes}
						},
						2 => {
							unique  => 1,
							regex   => q{^\#*GSSAPIAuthentication},
							content => q{GSSAPIAuthentication no}
						},
						3 => {
							unique  => 1,
							regex   => q{^\#*RSAAuthentication},
							content => q{RSAAuthentication yes}
						},
						4 => {
							unique  => 1,
							regex   => q{^\#*PubkeyAuthentication},
							content => q{PubkeyAuthentication yes}
						},
						5 => {
							unique  => 0,
							regex   => q{^\#*X11Forwarding},
							content => q{#X11Forwarding}
						  }
					}
				},
				2 => {
					tail => 1,
					content => q{X11Forwarding yes}
				}
			}
		}
	}
};

$commonSshd{'SLES'} = Storable::dclone( $commonSshd{'RHEL'} );

$commonSshd{'SLES'}{task} = {
	'open-firewall'  => [ 'yast2 --ncurses firewall services add service=service:sshd zone=EXT' ],
	'close-firewall' => [ 'yast2 --ncurses firewall services remove service=service:sshd zone=EXT' ]
};

$ssh{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$ssh{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$ssh{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$ssh{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$ssh{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ssh{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ssh{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$ssh{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$ssh{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$ssh{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$ssh{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ssh{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ssh{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$ssh{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$ssh{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$ssh{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$ssh{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$sshd{'RHEL'}{5}{9}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'RHEL'}{6}{0}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'RHEL'}{6}{1}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'RHEL'}{6}{2}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'RHEL'}{6}{3}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'RHEL'}{6}{4}{'x86_64'} = $commonSshd{'RHEL'};

$sshd{'CentOS'}{5}{9}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'CentOS'}{6}{0}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'CentOS'}{6}{1}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'CentOS'}{6}{2}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'CentOS'}{6}{3}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'CentOS'}{6}{4}{'x86_64'} = $commonSshd{'RHEL'};

$sshd{'ORAL'}{6}{3}{'x86_64'} = $commonSshd{'RHEL'};
$sshd{'ORAL'}{6}{4}{'x86_64'} = $commonSshd{'RHEL'};

$sshd{'SLES'}{10}{4}{'x86_64'} = $commonSshd{'SLES'};
$sshd{'SLES'}{11}{1}{'x86_64'} = $commonSshd{'SLES'};
$sshd{'SLES'}{11}{2}{'x86_64'} = $commonSshd{'SLES'};

1;

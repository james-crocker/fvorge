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

my $sshKeyName = 'id_rsa';

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
  IdentityFile <SSH_PRIVATE_KEY>
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
					content => q{}
				}
			}
		},
		'pubkey' => {
			path  => qq{<SSH_USER>-$sshKeyName.pub},
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
		'privkey' => {
			path  => qq{<SSH_USER>-$sshKeyName},
			save  => 0,
			chmod => 600,
			chown => 0,
			chgrp => 0,
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		}
	}
};

$common{'RHEL'}{task} = { 'genkeypair' => [ qq{ssh-keygen -t rsa -b 2048 -N '' -f <SSH_BASE_PATH>/<SSH_USER>-$sshKeyName} ] };

# SSHD config settings
$commonSshd{'RHEL'} = {
	'files' => {
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

$commonSshd{'SLES'}   = Storable::dclone( $commonSshd{'RHEL'} );
$commonSshd{'Ubuntu'} = Storable::dclone( $commonSshd{'RHEL'} );

$commonSshd{'SLES'}{task} = {
	'open-firewall'  => [ 'yast2 --ncurses firewall services add service=service:sshd zone=EXT' ],
	'close-firewall' => [ 'yast2 --ncurses firewall services remove service=service:sshd zone=EXT' ]
};

$commonSshd{'Ubuntu'}{task} = {
	'open-firewall'  => [ '/usr/sbin/ufw allow OpenSSH' ],
	'close-firewall' => [ '/usr/sbin/ufw deny OpenSSH' ]
};

# SSH
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

$ssh{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$ssh{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$ssh{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

$ssh{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'RHEL'};
$ssh{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'RHEL'};

# SSHD
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

$sshd{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $commonSshd{'Ubuntu'};
$sshd{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $commonSshd{'Ubuntu'};

1;

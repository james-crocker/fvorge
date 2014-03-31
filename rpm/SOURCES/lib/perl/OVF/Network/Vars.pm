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

package OVF::Network::Vars;

use strict;
use warnings;

our %network;
my %common;

# RHEL / CentOS Networks
$common{'RHEL'} = {
	'remove' => {
		'prefix' => 'ifcfg-',
		'path'   => '/etc/sysconfig/network-scripts'
	},
	'defaults' => {
		'bond-options' => 'mode=1 miimon=100',
		'ipv4'         => '',
		'ipv4-prefix'  => '',
		'ipv6'         => '',
		'ipv6-prefix'  => '',
		'onboot'       => 'yes',
		'onparent'     => 'yes',
		'bootproto'    => 'static'
	},
	'files' => {
		'if' => {
			path  => '/etc/sysconfig/network-scripts/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{DEVICE=<IF_LABEL>
BOOTPROTO=<IF_BOOTPROTO>
HWADDR=<IF_MAC>
NM_CONTROLLED=no
ONBOOT=<IF_ONBOOT>
TYPE=Ethernet
IPADDR=<IF_IPV4>
PREFIX=<IF_IPV4_PREFIX>
GATEWAY=<IF_IPV4_GATEWAY>
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
IPV6ADDR=<IF_IPV6>
IPV6_DEFAULTGW=<IF_IPV6_GATEWAY>
USERCTL=no
NAME="FVORGE <IF_LABEL>"}
				}
			}
		},
		'ifAlias' => {
			path  => '/etc/sysconfig/network-scripts/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{DEVICE=<IF_LABEL>
NM_CONTROLLED=no
ONPARENT=<IF_ONPARENT>
TYPE=Ethernet
BOOTPROTO=none
IPADDR=<IF_IPV4>
PREFIX=<IF_IPV4_PREFIX>
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_FAILURE_FATAL=no
IPV6ADDR=<IF_IPV6>
IPV6_DEFAULTGW=<IF_IPV6_GATEWAY>
USERCTL=no
NAME="FVORGE ALIAS <IF_LABEL>"}
				}
			}
		},
		'ifBond' => {
			path  => '/etc/sysconfig/network-scripts/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{DEVICE=<IF_LABEL>
BONDING_OPTS="<IF_BOND_OPTIONS>"
BOOTPROTO=none
NM_CONTROLLED=no
ONBOOT=<IF_ONBOOT>
TYPE=Ethernet
IPADDR=<IF_IPV4>
PREFIX=<IF_IPV4_PREFIX>
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_FAILURE_FATAL=no
IPV6ADDR=<IF_IPV6>
IPV6_DEFAULTGW=<IF_IPV6_GATEWAY>
USERCTL=no
NAME="FVORGE BOND <IF_LABEL>"}
				}
			}
		},
		'ifSlave' => {
			path  => '/etc/sysconfig/network-scripts/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{DEVICE=<IF_LABEL>
HWADDR=<IF_MAC>
NM_CONTROLLED=no
ONBOOT=<IF_ONBOOT>
MASTER=<IF_MASTER_LABEL>
SLAVE=yes
USERCTL=no}
				}
			}
		},
		'persistent' => {
			path  => '/etc/udev/rules.d/70-persistent-net.rules',
			apply => {
				1 => {
					replace => 1,
					content => q{SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="<IF_MAC>", ATTR{type}=="1", KERNEL=="eth*", NAME="<IF_LABEL>"}
				}
			}
		},
		'hostname' => {
			path  => '/etc/sysconfig/network',
			apply => {
				1 => {
					replace => 1,
					content => q{NETWORKING=yes
HOSTNAME=<HOSTNAME>.<DOMAIN>}
				}
			}
		},
		'resolv' => {
			path  => '/etc/resolv.conf',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		}
	}
};

# SLES Networks
$common{'SLES'} = {
	'remove' => {
		'prefix' => 'ifcfg-',
		'path'   => '/etc/sysconfig/network'
	},
	'defaults' => {
		'bond-options' => 'mode=balance-rr miimon=100',
		'ipv4'         => '',
		'ipv4-prefix'  => '',
		'ipv6'         => '',
		'ipv6-prefix'  => '',
		'onboot'       => 'yes',
		'onparent'     => 'yes',
		'bootproto'    => 'static'
	},
	'templates' => {
		'ifAlias' => {
			content => q{
IPADDR_<IF_LABEL>='<IF_IP>/<IF_IP_PREFIX>'
LABEL_<IF_LABEL>='<IF_LABEL>'}
		}
	},
	'files' => {
		'if' => {
			path  => '/etc/sysconfig/network/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{BOOTPROTO='<IF_BOOTPROTO>'
IPADDR='<IF_IPV4>/<IF_IPV4_PREFIX>'
NAME='E1000 Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'
LABEL_0='0'
IPADDR_0='<IF_IPV6>'
NETMASK_0='<IF_IPV6_PREFIX>'}
				}
			}
		},
		'ifBond' => {
			path  => '/etc/sysconfig/network/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{BONDING_MASTER='yes'
BONDING_MODULE_OPTS='<IF_BOND_OPTIONS>'
<BONDING_SLAVES>
BOOTPROTO='static'
ETHTOOL_OPTIONS='mode=1 miimon=100'
IPADDR='<IF_IPV4>/<IF_IPV4_PREFIX>'
NAME='<IF_LABEL>'
STARTMODE='auto'
USERCONTROL='no'
LABEL_0='0'
IPADDR_0='<IF_IPV6>'
NETMASK_0='<IF_IPV6_PREFIX>'}
				}
			}
		},
		'ifSlave' => {
			path  => '/etc/sysconfig/network/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{BOOTPROTO='none'
NAME='E1000 Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'}
				}
			}
		},
		'persistent' => {
			path  => '/etc/udev/rules.d/70-persistent-net.rules',
			apply => {
				1 => {
					replace => 1,
					content => q{SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="<IF_MAC>", ATTR{type}=="1", KERNEL=="eth*", NAME="<IF_LABEL>"}
				}
			}
		},
		'hostname' => {
			path  => '/etc/HOSTNAME',
			apply => {
				1 => {
					replace => 1,
					content => q{<HOSTNAME>.<DOMAIN>}
				}
			}
		},
		'resolv' => {
			path  => '/etc/resolv.conf',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'routes' => {
			path  => '/etc/sysconfig/network/routes',
			apply => {
				1 => {
					replace => 1,
					content => q{default <IF_IPV4_GATEWAY> - -
default <IF_IPV6_GATEWAY> - -}
				}
			}
		}
	}
};

$common{'SLES'}{10} = {
	'remove' => {
		'prefix' => 'ifcfg-',
		'path'   => '/etc/sysconfig/network'
	},
	'defaults' => {
		'bond-options' => 'mode=balance-rr miimon=100',
		'ipv4'         => '',
		'ipv4-prefix'  => '',
		'ipv6'         => '',
		'ipv6-prefix'  => '',
		'onboot'       => 'yes',
		'onparent'     => 'yes',
		'bootproto'    => 'static'
	},
	'templates' => {
		'ifAlias' => {
			content => q{
IPADDR_<IF_LABEL>='<IF_IP>'
LABEL_<IF_LABEL>='<IF_LABEL>'
NETMASK_<IF_LABEL>='<IF_IP_PREFIX>'}
		}
	},
	'files' => {
		'if' => {
			path  => '/etc/sysconfig/network/ifcfg-eth-id-<IF_MAC>',
			apply => {
				1 => {
					replace => 1,
					content => q{BOOTPROTO='<IF_BOOTPROTO>'
IPADDR='<IF_IPV4>/<IF_IPV4_PREFIX>'
NAME='E1000 Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'
_nm_name='<IF_LABEL>'
PREFIXLEN='<IF_IPV4_PREFIX>'
LABEL_0='0'
IPADDR_0='<IF_IPV6>'
NETMASK_0='<IF_IPV6_PREFIX>'}
				}
			}
		},
		'ifBond' => {
			path  => '/etc/sysconfig/network/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{BONDING_MASTER='yes'
BONDING_MODULE_OPTS='<IF_BOND_OPTIONS>'
<BONDING_SLAVES>
BOOTPROTO='<IF_BOOTPROTO>'
IPADDR='<IF_IPV4>/<IF_IPV4_PREFIX>'
STARTMODE='auto'
USERCONTROL='no'
PREFIXLEN='<IF_IPV4_PREFIX>'
LABEL_0='0'
IPADDR_0='<IF_IPV6>'
NETMASK_0='<IF_IPV6_PREFIX>'}
				}
			}
		},
		'ifSlave' => {
			path  => '/etc/sysconfig/network/ifcfg-eth-id-<IF_MAC>',
			apply => {
				1 => {
					replace => 1,
					content => q{BOOTPROTO='none'
NAME='E1000 Ethernet Controller'
STARTMODE='auto'
USERCONTROL='no'
_nm_name='<IF_LABEL>'}
				}
			}
		},
		'persistent' => {
			path  => '/etc/udev/rules.d/30-net_persistent_names.rules',
			apply => {
				1 => {
					replace => 1,
					content => q{SUBSYSTEM=="net", ACTION=="add", SYSFS{address}=="<IF_MAC>", IMPORT="/lib/udev/rename_netiface %k <IF_LABEL>"}
				}
			}
		},
		'hostname' => {
			path  => '/etc/HOSTNAME',
			apply => {
				1 => {
					replace => 1,
					content => q{<HOSTNAME>.<DOMAIN>}
				}
			}
		},
		'resolv' => {
			path  => '/etc/resolv.conf',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'routes' => {
			path  => '/etc/sysconfig/routes',
			apply => {
				1 => {
					replace => 1,
					content => q{default <IF_IPV4_GATEWAY> - -
default <IF_IPV6_GATEWAY> - -}
				}
			}
		}
	}
};

# Ubuntu Networks
$common{'Ubuntu'} = {
	'packages-bond' => [ 'ifenslave' ],
	'remove' => {
		'prefix' => 'ifcfg-',
		'path'   => '/etc/network/interfaces.d'
	},
	'defaults' => {
		'bond-options' => 'mode=1 miimon=100',
		'ipv4'         => '',
		'ipv4-prefix'  => '',
		'ipv6'         => '',
		'ipv6-prefix'  => '',
		'onboot'       => 'yes',
		'onparent'     => 'yes',
		'bootproto'    => 'static'
	},
	'files' => {
		'interfaces' => {
			path  => '/etc/network/interfaces',
			save  => 1,
			apply => {
				1 => {
					'delete' => {
						1 => { regex => '^\s*auto\s+eth\d+' },
						2 => { regex => '^\s*iface\s+eth\d+' }
					}
				},
				2 => {
					tail    => 1,
					content => 'source /etc/network/interfaces.d/ifcfg-*'
				}
			}
		},
		'if' => {
			path  => '/etc/network/interfaces.d/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'ifSlave' => {
			path  => '/etc/network/interfaces.d/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'ifAlias' => {
			path  => '/etc/network/interfaces.d/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'ifBond' => {
			path  => '/etc/network/interfaces.d/ifcfg-<IF_LABEL>',
			apply => {
				1 => {
					replace => 1,
					content => q{}
				}
			}
		},
		'hostname' => {
			path  => '/etc/hostname',
			save  => 1,
			apply => {
				1 => {
					replace => 1,
					content => q{<HOSTNAME>.<DOMAIN>}
				}
			}
		},
		'persistent' => {
			path  => '/etc/udev/rules.d/70-persistent-net.rules',
			apply => {
				1 => {
					replace => 1,
					content => q{SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="<IF_MAC>", ATTR{type}=="1", KERNEL=="eth*", NAME="<IF_LABEL>"}
				}
			}
		},
		'gai-precedence' => {
			path => '/etc/gai.conf',
			apply => {
				1 => {
					'substitute' => {
                        1 => {
                        	unique  => 1,
                            regex   => q{^(#|)\s*precedence\s+::ffff:0:0/96\s+100},
                            content => q{precedence ::ffff:0:0/96  100}
                        }
                    }
                }
			}
		}
	}
};

# SLES 11 is using the newer syntax matching RHEL 6.x but the path is still different
# Repeat for multiple aliases

$network{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
delete( $network{'RHEL'}{5}{9}{'x86_64'}{files}{persistent} );
$network{'RHEL'}{5}{9}{'x86_64'}{files}{hostname}{apply}{1}{content} .= qq{\nNETWORKING_IPV6=yes};

$network{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$network{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$network{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$network{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$network{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$network{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
delete( $network{'CentOS'}{5}{9}{'x86_64'}{files}{persistent} );
$network{'CentOS'}{5}{9}{'x86_64'}{files}{hostname}{apply}{1}{content} .= qq{\nNETWORKING_IPV6=yes};

$network{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$network{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$network{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$network{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$network{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$network{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$network{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$network{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'}{10};
$network{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$network{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$network{'Ubuntu'}{'13'}{'10'}{'x86_64'} = $common{'Ubuntu'};
$network{'Ubuntu'}{'14'}{'04'}{'x86_64'} = $common{'Ubuntu'};

1;

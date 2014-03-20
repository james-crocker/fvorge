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

package OVF::Service::Report::Syslog::Vars;

use strict;
use warnings;

our %syslog;
my %common;

$common{'RHEL'}{files} = {
	'syslogconf' => {
		path  => '/etc/rsyslog.conf',
		save  => 'once',
		chmod => 644,
		apply => {
			1 => {
				'tail'  => 1,
				content => q{local6.*                                                @<SYSLOG_SERVER>}
			}
		}
	}
};
$common{'RHEL'}{task} = { 'restart' => [ q{/etc/init.d/rsyslog restart} ] };

$common{'RHEL'}{5}{files} = {
	'syslogconf' => {
		path  => '/etc/syslog.conf',
		save  => 'once',
		chmod => 644,
		apply => {
			1 => {
				'tail'  => 1,
				content => q{local6.*                                                @<SYSLOG_SERVER>}
			}
		}
	}
};
$common{'RHEL'}{5}{task} = { 'restart' => [ q{/etc/init.d/syslog restart} ] };

$common{'SLES'}{files} = {
	'syslogconf' => {
		path  => '/etc/syslog-ng/syslog-ng.conf',
		save  => 'once',
		chmod => 644,
		apply => {
			1 => {
				after => {
					1 => {
						regex   => '^\s*filter\s+f_alert\s+\{\s*level\s*\(\s*alert\s*\)\s*;\s*\}\s*;\s*$',
						content => q(
destination logserver { udp\("<SYSLOG_SERVER>" port\(514\)\); };
log { source\(src\); destination\(logserver\); };
)
					}
				}
			}
		}
	}
};
$common{'SLES'}{task} = { 'restart' => [ q{service syslog restart} ] };

$common{'Ubuntu'}{files} = {
	'syslogconf' => {
		path    => '/etc/rsyslog.d/6-sios-server.conf',
		destroy => 1,
		chmod   => 644,
		apply   => {
			1 => {
				replace => 1,
				content => q{local6.*                                                @<SYSLOG_SERVER>}
			}
		}
	}
};
$common{'Ubuntu'}{task} = { 'restart' => [ q{/etc/init.d/rsyslog restart} ] };

$syslog{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$syslog{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$syslog{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$syslog{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$syslog{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$syslog{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$syslog{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'}{5};
$syslog{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$syslog{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$syslog{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$syslog{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$syslog{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$syslog{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$syslog{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$syslog{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$syslog{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$syslog{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$syslog{'Ubuntu'}{13}{10}{'x86_64'} = $common{'Ubuntu'};
$syslog{'Ubuntu'}{14}{04}{'x86_64'}  = $common{'Ubuntu'};

1;

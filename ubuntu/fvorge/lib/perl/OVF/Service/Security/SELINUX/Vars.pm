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

package OVF::Service::Security::SELINUX::Vars;

use strict;
use warnings;

our %selinux;
my %common;

$common{enabled} = {
	'config' => {
		path  => '/etc/selinux/config',
		chmod => 644,
		apply => {
			1 => {
				replace => 1,
				content => q{SELINUX=enabled
SELINUXTYPE=targeted}
			}
		}
	}
};

$common{disabled} = {
	'config' => {
		path    => '/etc/selinux/config',
		save    => 1,
		replace => 1,
		chmod   => 644,
		apply   => {
			1 => {
				replace => 1,
				content => q{SELINUX=disabled
SELINUXTYPE=targeted}
			}
		  }
	}
};

$selinux{'RHEL'}{5}{9}{'x86_64'} = \%common;
$selinux{'RHEL'}{6}{0}{'x86_64'} = \%common;
$selinux{'RHEL'}{6}{1}{'x86_64'} = \%common;
$selinux{'RHEL'}{6}{2}{'x86_64'} = \%common;
$selinux{'RHEL'}{6}{3}{'x86_64'} = \%common;
$selinux{'RHEL'}{6}{4}{'x86_64'} = \%common;

$selinux{'CentOS'}{5}{9}{'x86_64'} = \%common;
$selinux{'CentOS'}{6}{0}{'x86_64'} = \%common;
$selinux{'CentOS'}{6}{1}{'x86_64'} = \%common;
$selinux{'CentOS'}{6}{2}{'x86_64'} = \%common;
$selinux{'CentOS'}{6}{3}{'x86_64'} = \%common;
$selinux{'CentOS'}{6}{4}{'x86_64'} = \%common;

$selinux{'ORAL'}{6}{3}{'x86_64'} = \%common;
$selinux{'ORAL'}{6}{4}{'x86_64'} = \%common;

1;

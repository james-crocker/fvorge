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

package OVF::Service::Graphic::XServer::Vars;

use strict;
use warnings;

# Minimal set to enable X

our %xserver;
my %common;

$common{'RHEL'}{packages}   = [ 'xorg-x11-server-Xorg', 'xorg-x11-xauth' ];
$common{'SLES'}{packages}   = [ 'xorg-x11-server' ];
$common{'Ubuntu'}{packages} = [ 'xorg' ];

$xserver{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$xserver{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$xserver{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$xserver{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$xserver{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$xserver{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$xserver{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$xserver{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$xserver{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$xserver{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$xserver{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$xserver{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$xserver{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$xserver{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$xserver{'SLES'}{10}{4}{'x86_64'} = $common{'SLES'};
$xserver{'SLES'}{11}{1}{'x86_64'} = $common{'SLES'};
$xserver{'SLES'}{11}{2}{'x86_64'} = $common{'SLES'};

$xserver{'Ubuntu'}{13}{10}{'x86_64'} = $common{'Ubuntu'};
$xserver{'Ubuntu'}{14}{04}{'x86_64'} = $common{'Ubuntu'};

1;

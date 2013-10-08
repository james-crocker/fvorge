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

package OVF::Service::Database::Sybase::Vars;

# Suport for ASE 15.7 Linux x86_64

use strict;
use warnings;

our %sybase;
my %common;

$common{'RHEL'} = {
	'packages' => [ 'glibc.i686', 'libXtst.i686' ],
	'groups' => { 'sp-sybase' => { gid => 6005 } },
	'users'  => {
		'sp-sybase' => {
			uid     => 6005,
			gid     => 6005,
			homeDir => '/home/sp-sybase',
			passwd  => 'mysybasepass',
			shell   => '/bin/bash',
			comment => 'SIOS OVF User Sybase'
		}
	},
	'directories' => {
		'sybaseDir' => {
			path  => '/srv/sp-sybase',
			save  => 0,
			chmod => 755,
			chgrp => 'sp-sybase',
			chown => 'sp-sybase',
		},
	},
	'virtualip' => {
		'ip'     => q(<SAPDB_VIRTUAL_IP>),
		'prefix' => q(<SAPDB_VIRTUAL_IP_PREFIX>),
		'dev'    => q(<SAPDB_VIRTUAL_IP_DEV>)
	},
	'task' => {
		'getmedia'    => [ q{cd /home/sp-sybase; scp jcrocker@hancock:/filepile/software/Sybase/ase157_linuxx86-64.tgz . } ],
		'untar'       => [ q{mkdir -p /home/sp-sybase/ase157_linuxx86-64;cd /home/sp-sybase/ase157_linuxx86-64; tar xvfzp ../ase157_linuxx86-64.tgz} ],
		'chown'       => [ q{chown -R sp-sybase.sp-sybase /home/sp-sybase/ase157_linuxx86-64} ],
		'install'     => [ q{su - sp-sybase -c "/home/sp-sybase/ase157_linuxx86-64/setup.bin -f /home/sp-sybase/ase157_linux86-64-silent-install -i silent -DAGREE_TO_SYBASE_LICENSE=true -DRUN_SILENT=true"} ],
		'updateshell' => [ q{cat /srv/sp-sybase/SYBASE.sh >> /home/sp-sybase/.bash_profile} ]
	}
};

$common{'RHEL'}{'files'} = {
	'silent-install' => {
		path  => $common{'RHEL'}{users}{'sp-sybase'}{homeDir} . q{/ase157_linux86-64-silent-install},
		save  => 0,
		chmod => 444,
		chgrp => 'sp-sybase',
		chown => 'sp-sybase',
		apply => {
			1 => {
				replace => 1,
				content => q{
# Thu Mar 14 11:18:19 EDT 2013
# Replay feature output
# ---------------------
# This file was built by the Replay feature of InstallAnywhere.
# It contains variables that were set by Panels, Consoles or Custom Code.



#Validate Response File
#----------------------
RUN_SILENT=true

#Choose Install Folder
#---------------------
USER_INSTALL_DIR=/srv/sp-sybase

#Choose Update Install Option
#----------------------------
DO_UPDATE_INSTALL=false

#Choose Install Set
#------------------
CHOSEN_FEATURE_LIST=fase_srv,fopen_client,fdblib,fjconnect70,fdbisql,fqptune,fsysam_util,fase_agent,fodbcl,fconn_python,fconn_perl,fconn_php,fscc_server
CHOSEN_INSTALL_FEATURE_LIST=fase_srv,fopen_client,fdblib,fjconnect70,fdbisql,fqptune,fsysam_util,fase_agent,fodbcl,fconn_python,fconn_perl,fconn_php,fscc_server
CHOSEN_INSTALL_SET=Typical

#Choose Product License Type
#---------------------------
SYBASE_PRODUCT_LICENSE_TYPE=developer

#Install
#-------
-fileOverwrite_/srv/sp-sybase/sybuninstall/ASESuite/uninstall.lax=Yes

#Configure New Servers
#---------------------
SY_CONFIG_ASE_SERVER=true
SY_CONFIG_BS_SERVER=true
SY_CONFIG_XP_SERVER=true
SY_CONFIG_JS_SERVER=true
SY_CONFIG_SM_SERVER=true
SY_CONFIG_WS_SERVER=false
SY_CONFIG_SCC_SERVER=true
SY_CONFIG_TXT_SERVER=false

#Configure New Adaptive Server
#-----------------------------
SY_CFG_ASE_SERVER_NAME=SEQASYB
SY_CFG_ASE_PORT_NUMBER=5000
SY_CFG_ASE_APPL_TYPE=MIXED
SY_CFG_ASE_PAGESIZE=4k
SY_CFG_ASE_PASSWORD=<YOUR_SYBASE_PASSWORD>
SY_CFG_ASE_MASTER_DEV_NAME=/srv/sp-sybase/data/master.dat
SY_CFG_ASE_MASTER_DEV_SIZE=73
SY_CFG_ASE_MASTER_DB_SIZE=26
SY_CFG_ASE_SYBPROC_DEV_NAME=/srv/sp-sybase/data/sysprocs.dat
SY_CFG_ASE_SYBPROC_DEV_SIZE=172
SY_CFG_ASE_SYBPROC_DB_SIZE=172
SY_CFG_ASE_SYBTEMP_DEV_NAME=/srv/sp-sybase/data/sybsysdb.dat
SY_CFG_ASE_SYBTEMP_DEV_SIZE=6
SY_CFG_ASE_SYBTEMP_DB_SIZE=6
SY_CFG_ASE_ERROR_LOG=/srv/sp-sybase/ASE-15_0/install/SEQASYB.log
SY_CFG_ASE_PCI_ENABLE=true
SY_CFG_ASE_PCI_DEV_NAME=/srv/sp-sybase/data/sybpcidbdev_data.dat
SY_CFG_ASE_PCI_DEV_SIZE=48
SY_CFG_ASE_PCI_DB_SIZE=48
SY_CFG_ASE_TEMP_DEV_NAME=/srv/sp-sybase/data/tempdbdev.dat
SY_CFG_ASE_TEMP_DEV_SIZE=100
SY_CFG_ASE_TEMP_DB_SIZE=100
SY_CFG_ASE_OPT_ENABLE=false
SY_CFG_ASE_CPU_NUMBER=$NULL$
SY_CFG_ASE_MEMORY=$NULL$
SY_CFG_ASE_LANG=us_english
SY_CFG_ASE_CHARSET=utf8
SY_CFG_ASE_SORTORDER=dict
SY_CFG_ASE_SAMPLE_DB=true

#Configure New Backup Server
#---------------------------
SY_CFG_BS_SERVER_NAME=SEQASYB_BS
SY_CFG_BS_PORT_NUMBER=5001
SY_CFG_BS_ERROR_LOG=/srv/sp-sybase/ASE-15_0/install/SEQASYB_BS.log

#Configure New XP Server
#-----------------------
SY_CFG_XP_SERVER_NAME=SEQASYB_XP
SY_CFG_XP_PORT_NUMBER=5002
SY_CFG_XP_ERROR_LOG=/srv/sp-sybase/ASE-15_0/install/SEQASYB_XP.log

#Configure New Job Scheduler
#---------------------------
SY_CFG_JS_SERVER_NAME=SEQASYB_JSAGENT
SY_CFG_JS_PORT_NUMBER=4900
SY_CFG_JS_MANAG_DEV_NAME=/srv/sp-sybase/data/sybmgmtdb.dat
SY_CFG_JS_MANAG_DEV_SIZE=75
SY_CFG_JS_MANAG_DB_SIZE=75

#Configure Self Management
#-------------------------
SY_CFG_SM_USER_NAME=sa
SY_CFG_SM_PASSWORD=

#Sybase Control Center - Configure Self Discovery Service Adaptor
#----------------------------------------------------------------
SCC_SELFDISCOVERY_CONFIG_UDP_ADAPTOR=false
SCC_SELFDISCOVERY_CONFIG_JINI_ADAPTOR=true
SCC_SELFDISCOVERY_JINI_HOST_NAME=localhost
SCC_SELFDISCOVERY_JINI_PORT_NUMBER=4160
SCC_SELFDISCOVERY_JINI_HEART_BEAT_PERIOD=900

#Sybase Control Center - Configure RMI Port
#------------------------------------------
SCC_RMI_PORT_NUMBER=9999

#Sybase Control Center - Security Login Modules
#----------------------------------------------
CONFIG_SCC_CSI_SCCADMIN_PWD=st33l3y3
CONFIG_SCC_CSI_UAFADMIN_PWD=st33l3y3
      }
			}
		  }
	}
};

$sybase{'RHEL'}{5}{9}{'x86_64'} = $common{'RHEL'};
$sybase{'RHEL'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sybase{'RHEL'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sybase{'RHEL'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sybase{'RHEL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sybase{'RHEL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sybase{'CentOS'}{5}{9}{'x86_64'} = $common{'RHEL'};
$sybase{'CentOS'}{6}{0}{'x86_64'} = $common{'RHEL'};
$sybase{'CentOS'}{6}{1}{'x86_64'} = $common{'RHEL'};
$sybase{'CentOS'}{6}{2}{'x86_64'} = $common{'RHEL'};
$sybase{'CentOS'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sybase{'CentOS'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sybase{'ORAL'}{6}{3}{'x86_64'} = $common{'RHEL'};
$sybase{'ORAL'}{6}{4}{'x86_64'} = $common{'RHEL'};

$sybase{'SLES'}{10}{4}{'x86_64'} = $common{'RHEL'};
$sybase{'SLES'}{11}{1}{'x86_64'} = $common{'RHEL'};
$sybase{'SLES'}{11}{2}{'x86_64'} = $common{'RHEL'};

1;

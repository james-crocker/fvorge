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

package SIOS::LicenseVars;

use lib '../../perl';

use strict;
use warnings;

use Switch 'fallthrough';
use SIOS::CommonVars;

our %type;

## Per product/version sets ------------------------------------------------
foreach my $productKey ( keys %{SIOS::CommonVars::product} ) {
	foreach my $productVersion ( @{ $SIOS::CommonVars::product{$productKey}{versions} } ) {

		switch ( $productKey ) {
			case 'lk' {
				$type{$productKey}{$productVersion}{core} = 'LKLinux-Core_';
				$type{$productKey}{$productVersion}{kits} = {
					apache      => 'apache_',
					db2         => 'DB2_',
					dmmp        => 'dmmp_',
					hdlm        => 'hdlm_',
					informix    => 'informix_',
					lvm         => 'lvm_',
					md          => 'md_',
					mqseries    => 'mqseries_',
					mysql       => 'mysql_',
					nas         => 'nas_',
					nfs         => 'nfs_',
					oracle      => 'oracle_',
					postgres    => 'postgressql_',
					ppath       => 'ppath_',
					replication => 'replication_',
					samba       => 'samba_',
					sap         => 'sap_',
					sapdb       => 'sapdb_',
					sdd         => 'sdd_',
					sdrs        => 'sdrs_',
					sendmail    => 'sendmail_',
					sps         => 'sps_',
					sybase      => 'sybase_',
					xpclx       => 'xpclx_'
				};
			}

			case 'lk-cn' {
				$type{$productKey}{$productVersion}{core} = 'LKLinux-Core_';
				$type{$productKey}{$productVersion}{kits} = {
					apache      => 'apache_',
					db2         => 'DB2_',
					dmmp        => 'dmmp_',
					hdlm        => 'hdlm_',
					informix    => 'informix_',
					lvm         => 'lvm_',
					md          => 'md_',
					mqseries    => 'mqseries_',
					mysql       => 'mysql_',
					nas         => 'nas_',
					nfs         => 'nfs_',
					oracle      => 'oracle_',
					postgres    => 'postgressql_',
					ppath       => 'ppath_',
					replication => 'replication_',
					samba       => 'samba_',
					sap         => 'sap_',
					sapdb       => 'sapdb_',
					sdd         => 'sdd_',
					sdrs        => 'sdrs_',
					sendmail    => 'sendmail_',
					sps         => 'sps_',
					sybase      => 'sybase_',
					xpclx       => 'xpclx_'
				};
			}
			
			case 'lkssp' {
				$type{$productKey}{$productVersion}{core} = 'lkssp_';
				$type{$productKey}{$productVersion}{kits} = { bundle => 'lkssp-bundle_' };
			}

			case 'ora' {
				$type{$productKey}{$productVersion}{core} = 'LKLinux-Core_';
				$type{$productKey}{$productVersion}{kits} = {
					apache      => 'apache_',
					db2         => 'DB2_',
					dmmp        => 'dmmp_',
					hdlm        => 'hdlm_',
					informix    => 'informix_',
					lvm         => 'lvm_',
					md          => 'md_',
					mqseries    => 'mqseries_',
					mysql       => 'mysql_',
					nas         => 'nas_',
					nfs         => 'nfs_',
					oracle      => 'oracle_',
					postgres    => 'postgressql_',
					ppath       => 'ppath_',
					replication => 'replication_',
					samba       => 'samba_',
					sap         => 'sap_',
					sapdb       => 'sapdb_',
					sdd         => 'sdd_',
					sdrs        => 'sdrs_',
					sendmail    => 'sendmail_',
					sps         => 'sps_',
					sybase      => 'sybase_',
					xpclx       => 'xpclx_'
				};
			}

			case 'sap' {
				$type{$productKey}{$productVersion}{core} = 'LKLinux-Core_';
				$type{$productKey}{$productVersion}{kits} = {
					apache      => 'apache_',
					db2         => 'DB2_',
					dmmp        => 'dmmp_',
					hdlm        => 'hdlm_',
					informix    => 'informix_',
					lvm         => 'lvm_',
					md          => 'md_',
					mqseries    => 'mqseries_',
					mysql       => 'mysql_',
					nas         => 'nas_',
					nfs         => 'nfs_',
					oracle      => 'oracle_',
					postgres    => 'postgressql_',
					ppath       => 'ppath_',
					replication => 'replication_',
					samba       => 'samba_',
					sap         => 'sap_',
					sapdb       => 'sapdb_',
					sdd         => 'sdd_',
					sdrs        => 'sdrs_',
					sendmail    => 'sendmail_',
					sps         => 'sps_',
					sybase      => 'sybase_',
					xpclx       => 'xpclx_'
				};
			}

			case 'smc' {
				$type{$productKey}{$productVersion}{core} = undef;
				$type{$productKey}{$productVersion}{kits} = undef;
			}

			case 'sps' {
				$type{$productKey}{$productVersion}{core} = 'LKLinux-Core_';
				$type{$productKey}{$productVersion}{kits} = {
					apache      => 'apache_',
					db2         => 'DB2_',
					dmmp        => 'dmmp_',
					hdlm        => 'hdlm_',
					informix    => 'informix_',
					lvm         => 'lvm_',
					md          => 'md_',
					mqseries    => 'mqseries_',
					mysql       => 'mysql_',
					nas         => 'nas_',
					nfs         => 'nfs_',
					oracle      => 'oracle_',
					postgres    => 'postgressql_',
					ppath       => 'ppath_',
					replication => 'replication_',
					samba       => 'samba_',
					sap         => 'sap_',
					sapdb       => 'sapdb_',
					sdd         => 'sdd_',
					sdrs        => 'sdrs_',
					sendmail    => 'sendmail_',
					sps         => 'sps_',
					sybase      => 'sybase_',
					xpclx       => 'xpclx_'
				};
			}

			case 'vapp' {
				$type{$productKey}{$productVersion}{core} = 'vAppKeeper_';
				$type{$productKey}{$productVersion}{kits} = { bundle => 'vAppKeeper-bundle_' };
			}

		}

	}
}

# BUILD KIT LIC LISTS ----------------------------------
our %kitLicsList;

foreach my $productKey ( keys %type ) {
	foreach my $version ( keys %{ $type{$productKey} } ) {

		# Add 'all' and 'none' as kit lic options at all times
		$kitLicsList{$productKey}{$version} = [ 'all', 'none', ( keys %{ $type{$productKey}{$version}{kits} } ) ];

		#print "KL: $productKey:$version: ".join(' ', @{$kitLicsList{$productKey}{$version}})."\n";
	}
}

1;


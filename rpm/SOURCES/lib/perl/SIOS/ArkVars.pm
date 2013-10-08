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

package SIOS::ArkVars;

use lib '../../perl';

use strict;
use warnings;
use Storable;

use Switch 'fallthrough';
use SIOS::CommonVars;

our %type;

## Per product/version sets ------------------------------------------------
foreach my $productKey ( keys %{SIOS::CommonVars::product} ) {
	foreach my $productVersion ( @{ $SIOS::CommonVars::product{$productKey}{versions} } ) {

		switch ( $productKey ) {
			case 'lk' {
				$type{$productKey}{$productVersion}{kits} = {
					apache       => 'lkAPA',
					  clearcase  => 'lkCLEARCASE',
					  db2        => 'lkDB2',
					  dmmp       => 'lkDMMP',
					  dr         => 'lkDR',
					  gui        => 'lkGUI',
					  hdlm       => 'lkHDLM',
					  informix   => 'lkINF',
					  ip         => 'lkIP',
					  lvm        => 'lkLVM',
					  mailcenter => 'lkMAILCENTER',
					  man        => 'lkMAN',
					  md         => 'lkMD',
					  mqseries   => 'lkMQS',
					  mysql      => 'lkSQL',
					  nas        => 'lkNAS',
					  nfs        => 'lkNFS',
					  oracle     => 'lkORA',
					  postgres   => 'lkPGSQL',
					  postfix    => 'lkPOSTFIX',
					  ppath      => 'lkPPATH',
					  qwk        => 'lkQWK',
					  raw        => 'lkRAW',
					  sap        => 'lkSAP',
					  sapdb      => 'lkSAPDB',
					  sdd        => 'lkSDD',
					  sendmail   => 'lkSEN',
					  samba      => 'lkSMB',
					  sps        => 'lkSPS',
					  staging    => 'lkSTK',
					  sybase     => 'lkSYBASE',
					  vmware     => 'lkVMWARE',
					  xpclx      => 'lkXPCLX'
				};
			}

			case 'lk-cn' {
				$type{$productKey}{$productVersion}{kits} = {
					apache       => 'lkAPA',
					  clearcase  => 'lkCLEARCASE',
					  db2        => 'lkDB2',
					  dmmp       => 'lkDMMP',
					  dr         => 'lkDR',
					  gui        => 'lkGUI',
					  hdlm       => 'lkHDLM',
					  informix   => 'lkINF',
					  ip         => 'lkIP',
					  lvm        => 'lkLVM',
					  mailcenter => 'lkMAILCENTER',
					  man        => 'lkMAN',
					  md         => 'lkMD',
					  mqseries   => 'lkMQS',
					  mysql      => 'lkSQL',
					  nas        => 'lkNAS',
					  nfs        => 'lkNFS',
					  oracle     => 'lkORA',
					  postgres   => 'lkPGSQL',
					  postfix    => 'lkPOSTFIX',
					  ppath      => 'lkPPATH',
					  qwk        => 'lkQWK',
					  raw        => 'lkRAW',
					  sap        => 'lkSAP',
					  sapdb      => 'lkSAPDB',
					  sdd        => 'lkSDD',
					  sendmail   => 'lkSEN',
					  samba      => 'lkSMB',
					  sps        => 'lkSPS',
					  staging    => 'lkSTK',
					  sybase     => 'lkSYBASE',
					  vmware     => 'lkVMWARE',
					  xpclx      => 'lkXPCLX'
				};
			}

			case 'lkssp' {

				# Latest kits
				$type{$productKey}{'latest'}{setupKits} = {
					apache      => 'APA',
					  db2       => 'DB2',
					  mqseries  => 'MQS',
					  mysql     => 'SQL',
					  nas       => 'NAS',
					  nfs       => 'NFS',
					  oracle    => 'ORA',
					  postgres  => 'PGSQL',
					  postfix   => 'POSTFIX',
					  sap       => 'SAP',
					  sapdb     => 'SAPDB',
					  samba     => 'SMB',
					  sybase    => 'SYBASE'
				};

				$type{$productKey}{'latest'}{kits} = {
					apache    => 'lkAPA',
					db2       => 'lkDB2',
					mqseries  => 'lkMQS',
					mysql     => 'lkSQL',
					nas       => 'lkNAS',
					nfs       => 'lkNFS',
					oracle    => 'lkORA',
					postgres  => 'lkPGSQL',
					postfix   => 'lkPOSTFIX',
					sap       => 'lkSAP',
					sapdb     => 'lkSAPDB',
					samba     => 'lkSMB',
					sybase    => 'lkSYBASE'
				};

			}

			case 'ora' {
				$type{$productKey}{$productVersion}{kits} = {
					apache       => 'lkAPA',
					  clearcase  => 'lkCLEARCASE',
					  db2        => 'lkDB2',
					  dmmp       => 'lkDMMP',
					  dr         => 'lkDR',
					  gui        => 'lkGUI',
					  hdlm       => 'lkHDLM',
					  informix   => 'lkINF',
					  ip         => 'lkIP',
					  lvm        => 'lkLVM',
					  mailcenter => 'lkMAILCENTER',
					  man        => 'lkMAN',
					  md         => 'lkMD',
					  mqseries   => 'lkMQS',
					  mysql      => 'lkSQL',
					  nas        => 'lkNAS',
					  nfs        => 'lkNFS',
					  oracle     => 'lkORA',
					  postgres   => 'lkPGSQL',
					  postfix    => 'lkPOSTFIX',
					  ppath      => 'lkPPATH',
					  qwk        => 'lkQWK',
					  raw        => 'lkRAW',
					  sap        => 'lkSAP',
					  sapdb      => 'lkSAPDB',
					  sdd        => 'lkSDD',
					  sendmail   => 'lkSEN',
					  samba      => 'lkSMB',
					  sps        => 'lkSPS',
					  staging    => 'lkSTK',
					  sybase     => 'lkSYBASE',
					  vmware     => 'lkVMWARE',
					  xpclx      => 'lkXPCLX'
				};
			}

			case 'sap' {
				$type{$productKey}{$productVersion}{kits} = {
					apache       => 'lkAPA',
					  clearcase  => 'lkCLEARCASE',
					  db2        => 'lkDB2',
					  dmmp       => 'lkDMMP',
					  dr         => 'lkDR',
					  gui        => 'lkGUI',
					  hdlm       => 'lkHDLM',
					  informix   => 'lkINF',
					  ip         => 'lkIP',
					  lvm        => 'lkLVM',
					  mailcenter => 'lkMAILCENTER',
					  man        => 'lkMAN',
					  md         => 'lkMD',
					  mqseries   => 'lkMQS',
					  mysql      => 'lkSQL',
					  nas        => 'lkNAS',
					  nfs        => 'lkNFS',
					  oracle     => 'lkORA',
					  postgres   => 'lkPGSQL',
					  postfix    => 'lkPOSTFIX',
					  ppath      => 'lkPPATH',
					  qwk        => 'lkQWK',
					  raw        => 'lkRAW',
					  sap        => 'lkSAP',
					  sapdb      => 'lkSAPDB',
					  sdd        => 'lkSDD',
					  sendmail   => 'lkSEN',
					  samba      => 'lkSMB',
					  sps        => 'lkSPS',
					  staging    => 'lkSTK',
					  sybase     => 'lkSYBASE',
					  vmware     => 'lkVMWARE',
					  xpclx      => 'lkXPCLX'
				};
			}

			case 'smc' {
				$type{$productKey}{$productVersion}{kits} = undef;
			}

			case 'sps' {

				# Latest kits
				$type{$productKey}{'latest'}{setupKits} = {
					apache      => 'APA',
					  db2       => 'DB2',
					  dmmp      => 'DMMP',
					  dr        => 'DR',
					  hdlm      => 'HDLM',
					  lvm       => 'LVM',
					  md        => 'MD',
					  mqseries  => 'MQS',
					  mysql     => 'SQL',
					  nas       => 'NAS',
					  nfs       => 'NFS',
					  oracle    => 'ORA',
					  postgres  => 'PGSQL',
					  postfix   => 'POSTFIX',
					  powerpath => 'PPATH',
					  sap       => 'SAP',
					  sapdb     => 'SAPDB',
					  samba     => 'SMB',
					  necsps    => 'SPS',
					  sybase    => 'SYBASE'
				};

				$type{$productKey}{'latest'}{kits} = {
					apache    => 'lkAPA',
					db2       => 'lkDB2',
					dmmp      => 'lkDMMP',
					dr        => 'lkDR',
					hdlm      => 'lkHDLM',
					lvm       => 'lkLVM',
					md        => 'lkMD',
					mqseries  => 'lkMQS',
					mysql     => 'lkSQL',
					nas       => 'lkNAS',
					nfs       => 'lkNFS',
					oracle    => 'lkORA',
					postgres  => 'lkPGSQL',
					postfix   => 'lkPOSTFIX',
					powerpath => 'lkPPATH',
					sap       => 'lkSAP',
					sapdb     => 'lkSAPDB',
					samba     => 'lkSMB',
					necsps    => 'lkSPS',
					sybase    => 'lkSYBASE'
				};

				$type{$productKey}{'8.2.0'} = Storable::dclone( $type{$productKey}{'latest'} );
				$type{$productKey}{'8.1.3'} = Storable::dclone( $type{$productKey}{'latest'} );
				$type{$productKey}{'8.1.2'} = Storable::dclone( $type{$productKey}{'latest'} );
				$type{$productKey}{'8.1.1'} = Storable::dclone( $type{$productKey}{'latest'} );

				#8.1.0 APA DMMP DR LVM MD MQS NAS NFS ORA PGSQL SAP SMB SQL
				$type{$productKey}{'8.1.0'}{setupKits} = {
					apache   => 'APA',
					dmmp     => 'DMMP',
					dr       => 'DR',
					lvm      => 'LVM',
					md       => 'MD',
					mqseries => 'MQS',
					mysql    => 'SQL',
					nas      => 'NAS',
					nfs      => 'NFS',
					oracle   => 'ORA',
					postgres => 'PGSQL',
					sap      => 'SAP',
					samba    => 'SMB'
				};
				$type{$productKey}{8.1.0}{kits} = {
					apache   => 'lkAPA',
					dmmp     => 'lkDMMP',
					dr       => 'lkDR',
					lvm      => 'lkLVM',
					md       => 'lkMD',
					mqseries => 'lkMQS',
					mysql    => 'lkSQL',
					nas      => 'lkNAS',
					nfs      => 'lkNFS',
					oracle   => 'lkORA',
					postgres => 'lkPGSQL',
					sap      => 'lkSAP',
					samba    => 'lkSMB'
				};

				$type{$productKey}{'8.0.0'}{kits} = {
					apache     => 'lkAPA',
					clearcase  => 'lkCLEARCASE',
					db2        => 'lkDB2',
					dmmp       => 'lkDMMP',
					dr         => 'lkDR',
					gui        => 'lkGUI',
					hdlm       => 'lkHDLM',
					informix   => 'lkINF',
					ip         => 'lkIP',
					lvm        => 'lkLVM',
					mailcenter => 'lkMAILCENTER',
					man        => 'lkMAN',
					md         => 'lkMD',
					mqseries   => 'lkMQS',
					mysql      => 'lkSQL',
					nas        => 'lkNAS',
					nfs        => 'lkNFS',
					oracle     => 'lkORA',
					postgres   => 'lkPGSQL',
					postfix    => 'lkPOSTFIX',
					ppath      => 'lkPPATH',
					qwk        => 'lkQWK',
					raw        => 'lkRAW',
					sap        => 'lkSAP',
					sapdb      => 'lkSAPDB',
					sdd        => 'lkSDD',
					sendmail   => 'lkSEN',
					samba      => 'lkSMB',
					sps        => 'lkSPS',
					staging    => 'lkSTK',
					sybase     => 'lkSYBASE',
					vmware     => 'lkVMWARE',
					xpclx      => 'lkXPCLX'
				};

			}

			case 'vapp' {

				$type{$productKey}{'7.5.0'}{kits} = {
					apache       => 'lkAPA',
					  clearcase  => 'lkCLEARCASE',
					  db2        => 'lkDB2',
					  dmmp       => 'lkDMMP',
					  dr         => 'lkDR',
					  gui        => 'lkGUI',
					  hdlm       => 'lkHDLM',
					  informix   => 'lkINF',
					  ip         => 'lkIP',
					  lvm        => 'lkLVM',
					  mailcenter => 'lkMAILCENTER',
					  man        => 'lkMAN',
					  md         => 'lkMD',
					  mqseries   => 'lkMQS',
					  mysql      => 'lkSQL',
					  nas        => 'lkNAS',
					  nfs        => 'lkNFS',
					  oracle     => 'lkORA',
					  postgres   => 'lkPGSQL',
					  postfix    => 'lkPOSTFIX',
					  ppath      => 'lkPPATH',
					  qwk        => 'lkQWK',
					  raw        => 'lkRAW',
					  sap        => 'lkSAP',
					  sapdb      => 'lkSAPDB',
					  sdd        => 'lkSDD',
					  sendmail   => 'lkSEN',
					  samba      => 'lkSMB',
					  sps        => 'lkSPS',
					  staging    => 'lkSTK',
					  sybase     => 'lkSYBASE',
					  vmware     => 'lkVMWARE',
					  xpclx      => 'lkXPCLX'
				};

			}

		}

	}
}

# BUILD KIT LISTS ----------------------------------
our %kitList;

foreach my $productKey ( keys %type ) {
	foreach my $version ( keys %{ $type{$productKey} } ) {

		# Add 'all' and 'none' as kit lic options at all times
		$kitList{$productKey}{$version} = [ 'all', 'none', ( keys %{ $type{$productKey}{$version}{kits} } ) ];

		#print "KL: $productKey:$version: ".join(' ', @{$kitLicsList{$productKey}{$version}})."\n";
	}
}

1;

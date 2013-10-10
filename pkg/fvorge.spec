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

%define name fvorge
%define buildroot %{_tmppath}/%{name}-%{version}-%{release}-buildroot
%define fvorgedir /opt/fvorge

Name: %{name}
Version: %{version}
Release: %{release}
#Source: %{name}-%{version}-%{release}.tar.gz
Summary: Open Virtualization Format (OVF) configuration and management utility that forges virtual appliances from scratch.
License: GPLv3, VMware(r) SDK, CC BY-NC 3.0, Perl5
Group: FVORGE
Vendor: SIOS Technology Corp.
Packager: SIOS Technology Corp.
URL: http://www.us.sios.com/
BuildArch: noarch
BuildRoot: %{buildroot}
Requires: perl

%description
FVORGE is able to deploy OVF images and configure the image with unique system properties from OVF settings. This enables rapid, consistent and reproducible test environments. 

%prep
#%setup
#
# !!!!! NOTE: SKIPPING lib/VMware/sdk, lib/VMware/contrib from rpm/config/lkperl.req::process_file to avoid use/requires conflicts
#
%build
%install
RPMSRCDIR=${ROOT}/rpm/SOURCES

install -m 0750 -d $RPM_BUILD_ROOT/etc
install -m 0750 -d $RPM_BUILD_ROOT/etc/init.d

install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/bin
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/01-05-09-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/01-06-04-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/02-11-01-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/02-11-02-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/02-11-02-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-05-09-01
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-06-04-01/200
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/fvorge-deploy-examples
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/LIO
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Automation
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Custom
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Network
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/NFS
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/Samba
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/MySQL
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Oracle
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/PostgreSQL
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/SAPDB
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Sybase
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Graphic
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Graphic/XServer
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Locale
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/SNMP
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/Syslog
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Repository
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/AppArmor
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/Firewall
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/PAM
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/PAM/LDAP
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SELINUX
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SSH
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/ISCSI
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/Multipath
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Time
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Time/NTP
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Automation
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Prerequisites
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Product
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/Filesystems
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/LVM
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Vars
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/repos
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/sios
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/product
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/product/sps
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/qa
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/keys
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk
install -m 0750 -d $RPM_BUILD_ROOT%{fvorgedir}/sbin

install -m 0750 ${RPMSRCDIR}/bin/fvorge-deploy.pl $RPM_BUILD_ROOT%{fvorgedir}/bin/fvorge-deploy
install -m 0750 ${RPMSRCDIR}/bin/fvorge-lio.pl $RPM_BUILD_ROOT%{fvorgedir}/bin/fvorge-lio
install -m 0750 ${RPMSRCDIR}/bin/sp-erase.pl $RPM_BUILD_ROOT%{fvorgedir}/bin/sp-erase
install -m 0750 ${RPMSRCDIR}/bin/sp-setup.pl $RPM_BUILD_ROOT%{fvorgedir}/bin/sp-setup

install -m 0750 ${RPMSRCDIR}/etc/init.d/fvorge.sh $RPM_BUILD_ROOT/etc/init.d/fvorge

install -m 0644 ${RPMSRCDIR}/lib/OVF/example-ovf-defaults.xml $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/example-ovf-defaults.xml
install -m 0644 ${RPMSRCDIR}/lib/OVF/fvorge-ovf-snippet.xml $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/fvorge-ovf-snippet.xml
install -m 0644 ${RPMSRCDIR}/lib/OVF/clusters/03-06-04-01/200/01 $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-06-04-01/200/01
install -m 0644 ${RPMSRCDIR}/lib/OVF/clusters/03-06-04-01/200/02 $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-06-04-01/200/02
install -m 0644 ${RPMSRCDIR}/lib/OVF/clusters/03-06-04-01/200/02 $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-06-04-01/200/03
install -m 0644 ${RPMSRCDIR}/lib/OVF/clusters/03-06-04-01/200/02 $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/clusters/03-06-04-01/200/04
install -m 0644 ${RPMSRCDIR}/lib/OVF/fvorge-deploy-examples/batch_4node.cf $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/fvorge-deploy-examples/batch_4node.cf
install -m 0750 ${RPMSRCDIR}/lib/OVF/fvorge-deploy-examples/batch-fvorge.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/OVF/fvorge-deploy-examples/batch-fvorge

install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Distribution.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Distribution.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/LIO/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/LIO/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/LIO/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/LIO/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/State.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/State.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/VApp.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/VApp.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Automation/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Automation/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Automation/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Automation/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Custom/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Custom/Module.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Directories.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Directories.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Files.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Files.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Groups.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Groups.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Init.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Init.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Network.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Network.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Storage.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Storage.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Tasks.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Tasks.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Manage/Users.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Manage/Users.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Network/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Network/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Network/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Network/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/NFS/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/NFS/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/NFS/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/NFS/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/NFS/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/NFS/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/Samba/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/Samba/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/Samba/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/Samba/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/App/Samba/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/App/Samba/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/MySQL/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/MySQL/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/MySQL/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/MySQL/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/MySQL/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/MySQL/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/Oracle/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Oracle/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/Oracle/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Oracle/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/PostgreSQL/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/PostgreSQL/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/PostgreSQL/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/PostgreSQL/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/PostgreSQL/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/PostgreSQL/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/SAPDB/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/SAPDB/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/SAPDB/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/SAPDB/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/Sybase/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Sybase/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Database/Sybase/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Database/Sybase/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Graphic/XServer/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Graphic/XServer/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Graphic/XServer/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Graphic/XServer/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Locale/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Locale/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Locale/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Locale/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Locale/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Locale/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Report/SNMP/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/SNMP/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Report/SNMP/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/SNMP/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Report/SNMP/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/SNMP/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Report/Syslog/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/Syslog/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Report/Syslog/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Report/Syslog/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Repository/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Repository/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Repository/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Repository/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/AppArmor/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/AppArmor/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/AppArmor/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/AppArmor/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/Firewall/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/Firewall/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/Firewall/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/Firewall/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/PAM/LDAP/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/PAM/LDAP/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/PAM/LDAP/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/PAM/LDAP/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/PAM/LDAP/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/PAM/LDAP/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/SELINUX/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SELINUX/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/SELINUX/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SELINUX/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/SSH/Apply.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SSH/Apply.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Security/SSH/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Security/SSH/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/ISCSI/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/ISCSI/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/ISCSI/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/ISCSI/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/ISCSI/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/ISCSI/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/Multipath/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/Multipath/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/Multipath/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/Multipath/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Storage/Multipath/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Storage/Multipath/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Time/NTP/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Time/NTP/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Time/NTP/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Time/NTP/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Service/Time/NTP/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Service/Time/NTP/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Automation/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Automation/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Automation/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Automation/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Automation/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Automation/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Prerequisites/Packages.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Prerequisites/Packages.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Prerequisites/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Prerequisites/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Product/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Product/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/SIOS/Product/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/SIOS/Product/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Storage/Filesystems/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/Filesystems/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Storage/Filesystems/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/Filesystems/Vars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Storage/LVM/Module.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/LVM/Module.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Storage/LVM/Vars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Storage/LVM/Vars.pm

install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Vars/Common.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Vars/Common.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/OVF/Vars/Common.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/OVF/Vars/ovf-generic-template.ovf

install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/ArkVars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/ArkVars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/BuildVars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/BuildVars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/CommonVars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/CommonVars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/LicenseVars.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/LicenseVars.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/Logger.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/Logger.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/Product.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/Product.pm
install -m 0640 ${RPMSRCDIR}/lib/perl/SIOS/SysInfo.pm $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/SIOS/SysInfo.pm

install -m 0644 ${RPMSRCDIR}/lib/repos/rhel-fvorge.repo $RPM_BUILD_ROOT%{fvorgedir}/lib/repos/rhel-fvorge.repo
install -m 0644 ${RPMSRCDIR}/lib/repos/sles-fvorge.repo $RPM_BUILD_ROOT%{fvorgedir}/lib/repos/sles-fvorge.repo

install -m 0750 ${RPMSRCDIR}/lib/sios/qa/fill-cifs.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/qa/fill-cifs
install -m 0750 ${RPMSRCDIR}/lib/sios/qa/fill-nfs.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/qa/fill-nfs
install -m 0750 ${RPMSRCDIR}/lib/sios/qa/random-writers.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/qa/random-writers

install -m 0750 ${RPMSRCDIR}/lib/sios/product/sps/interfacelist.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/product/sps/interfacelist
install -m 0750 ${RPMSRCDIR}/lib/sios/product/sps/devicenames.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/sios/product/sps/devicenames

install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/centos5.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/centos5
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/centos6.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/centos6
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/rhel5.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/rhel5
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/rhel6.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/rhel6
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/sles10.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/sles10
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/sles11sp1.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/sles11sp1
install -m 0750 ${RPMSRCDIR}/lib/VMware/install-tools/sles11sp2.sh $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/sles11sp2
install -m 0644 ${RPMSRCDIR}/lib/VMware/install-tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub
install -m 0644 ${RPMSRCDIR}/lib/VMware/install-tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/install-tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub
install -m 0750 ${RPMSRCDIR}/lib/VMware/contrib/remove_vm.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/.
install -m 0750 ${RPMSRCDIR}/lib/VMware/contrib/remove_vm.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/remove_vm.pl
install -m 0750 ${RPMSRCDIR}/lib/VMware/contrib/vmISOManagement.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/vmISOManagement.pl
install -m 0750 ${RPMSRCDIR}/lib/VMware/sdk/powerops.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/powerops.pl
install -m 0750 ${RPMSRCDIR}/lib/VMware/sdk/removabledevices.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/removabledevices.pl
install -m 0750 ${RPMSRCDIR}/lib/VMware/sdk/snapshot.pl $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/snapshot.pl

install -m 0750 ${RPMSRCDIR}/sbin/fvorge.pl $RPM_BUILD_ROOT%{fvorgedir}/sbin/fvorge

# 3rd Party License Content
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/80x15.png $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/80x15.png
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/camel_head.v25e738a.png $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/camel_head.v25e738a.png
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/dev.v5f7fab3.css $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/dev.v5f7fab3.css
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/element.js $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/element.js
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/external.v1.png $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/external.v1.png
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/ga.js $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/ga.js
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/jquery.corner.v84b7681.js $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/jquery.corner.v84b7681.js
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/jquery.min.js $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/jquery.min.js
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/leostyle.v8cd7532.css $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/leostyle.v8cd7532.css
install -m 0640 ${RPMSRCDIR}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/leo.v9872b9c.js $RPM_BUILD_ROOT%{fvorgedir}/lib/perl/Linux/Perl\ Licensing\ -\ dev.perl.org_files/leo.v9872b9c.js

install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/191807.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/191807.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/brightedge.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/brightedge.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/buttons.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/buttons.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/downloads-tracker.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/downloads-tracker.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/elqCfg.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/elqCfg.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/elqImg.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/elqImg.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/ip.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/ip.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/ip.json $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/ip.json
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery-1.8.3.min.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery-1.8.3.min.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery-ui.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery-ui.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery.url.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/jquery.url.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/klx8ltg.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/klx8ltg.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/mbox.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/mbox.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/modernizr.custom.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/modernizr.custom.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/modernizr-latest.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/modernizr-latest.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/notice $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/notice
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/oo_conf_us.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/oo_conf_us.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/oo_engine.min.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/oo_engine.min.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/placeholder.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/placeholder.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/redesign-custom.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/redesign-custom.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/respond.min.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/respond.min.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/s_code_ts.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/s_code_ts.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/selectivizr-min.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/selectivizr-min.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/svrGP.aspx $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/svrGP.aspx
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.button.carousel.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.button.carousel.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.carousel.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.carousel.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw_cust.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw_cust.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.heightmatch.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.heightmatch.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.lbcarousel.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.lbcarousel.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.lightbox.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.lightbox.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.main.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.main.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.nav.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Community\ Terms\ of\ Use\ -\ United\ States_files/vmw.nav.js

install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/cc-logo.jpg $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/cc-logo.jpg
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/deed3.css $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/deed3.css
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/deed3-print.css $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/deed3-print.css
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/errata.js $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/errata.js
install -m 0640 ${RPMSRCDIR}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/unported.png $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/contrib/Creative\ Commons\ Legal\ Code_files/unported.png

install -m 0640 ${RPMSRCDIR}/lib/VMware/sdk/EULA $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/EULA
install -m 0640 ${RPMSRCDIR}/lib/VMware/sdk/open_source_licenses.txt $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/open_source_licenses.txt
install -m 0640 ${RPMSRCDIR}/lib/VMware/sdk/README.copyright $RPM_BUILD_ROOT%{fvorgedir}/lib/VMware/sdk/README.copyright


%clean
#if [ -d $RPM_BUILD_ROOT ]; then rm -rf $RPM_BUILD_ROOT; fi
#rm -rf $RPM_BUILD_DIR/%{name}-%{version}

%post
chkconfig --add fvorge
chkconfig fvorge on

if [ -f /root/.bash_profile ]; then
   grep -q 'PATH\s*=\s*.*\/opt\/fvorge\/bin.*' /root/.bash_profile
   if [ $? == 1 ]; then
      perl -p -i.fvorge.bak -e "s#PATH=(.*)#PATH=\$1:/opt/fvorge/bin#" /root/.bash_profile
   fi
else
   echo 'PATH=$PATH:/opt/fvorge/bin' > /root/.bash_profile
   echo 'export PATH' >> /root/.bash_profile
fi

DISTRO_VERSION=`less /proc/version | grep -i 'suse'`
if [ -z "${DISTRO_VERSION}" ]; then
   cp /opt/fvorge/lib/repos/rhel-fvorge.repo /etc/yum.repos.d/fvorge.repo
else
   cp /opt/fvorge/lib/repos/sles-fvorge.repo /etc/zypp/repos.d/fvorge.repo
fi

%files
%defattr(-,root,root)
/etc/init.d/fvorge
%{fvorgedir}

#%doc

%changelog
* Thu Sep 27 2013 james.crocker@us.sios.com
- Initial open source version of FVORGE

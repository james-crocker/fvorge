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

package OVF::Network::Module;

use strict;
use warnings;
use POSIX;
use Storable;

use lib '../../../perl';
use OVF::Manage::Files;
use OVF::Network::Vars;
use OVF::State;
use OVF::Vars::Common;
use SIOS::CommonVars;
use Debug;

my $sysDistro  = $SIOS::CommonVars::sysDistro;
my $sysVersion = $SIOS::CommonVars::sysVersion;
my $sysArch    = $SIOS::CommonVars::sysArch;

## For surpressing stdout, stderr.
my $quietCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{quietCmd};

sub apply ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	# Check if any config before processing
	if ( !defined $OVF::Network::Vars::network{$distro}{$major}{$minor}{$arch} ) {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO OVF PROPERTIES FOUND for $distro $major.$minor $arch} );
		return;
	}

	if ( OVF::State::ovfIsChanged( 'network.*', %options ) ) {
		Sys::Syslog::syslog( 'info', qq{$action ...} );
		destroy( \%options );
		create( \%options );
		resetHostname ( \%options ); # May avoid needing to reboot
		restartNetwork ( \%options ); # May avoid needing to reboot
	} else {
		Sys::Syslog::syslog( 'info', qq{$action ::SKIP:: NO changes to apply; Current network.* same as Previous properties} );
		return;
	}
}


sub create ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;

	my %currentOvf = %{ $options{ovf}{current} };
	my $arch       = $currentOvf{'host.architecture'};
	my $distro     = $currentOvf{'host.distribution'};
	my $major      = $currentOvf{'host.major'};
	my $minor      = $currentOvf{'host.minor'};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	#my %commonVars       = %{ $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName} };

	my %networkVars = %{ $OVF::Network::Vars::network{$distro}{$major}{$minor}{$arch} };

	my %generatedFiles;    # Collect created files for later creation

	my %hostnameTemplate = %{ Storable::dclone( $networkVars{files}{hostname} ) };
	my %resolvTemplate   = %{ Storable::dclone( $networkVars{files}{resolv} ) } if ( defined $networkVars{files}{resolv} );

	my $required        = [ 'network.if' ];
	my $requiredEnabled = [];
	return if ( OVF::State::checkRequired( $action, $required, '', $requiredEnabled, %options ) );

	my $resolvSearch = $currentOvf{'network.resolv.search'} if ( defined $currentOvf{'network.resolv.search'} );

	my $resolvNames = $currentOvf{'network.resolv.nameservers'} if ( defined $currentOvf{'network.resolv.nameservers'} );

	my $ipv4Gateway = $currentOvf{'network.gateway.ipv4'} if ( defined $currentOvf{'network.gateway.ipv4'} );

	my $ipv6Gateway = $currentOvf{'network.gateway.ipv6'} if ( defined $currentOvf{'network.gateway.ipv6'} );

	my $hostName = $currentOvf{'network.hostname'} if ( defined $currentOvf{'network.hostname'} );

	my $domainName = $currentOvf{'network.domain'} if ( defined $currentOvf{'network.domain'} );

	# Markup the resolv files (Ubuntu will have search and nameservers in the interface file configs)
	my $search = join( ' ', split( /,/, $resolvSearch ) ) if ( defined $resolvSearch );
	my @nameservers = split( /,/, $resolvNames ) if ( defined $resolvNames );

	if ( %resolvTemplate and $distro ne 'Ubuntu' ) {

		$resolvTemplate{apply}{1}{content} .= q{domain } . $domainName . qq{\n};
		$resolvTemplate{apply}{1}{content} .= qq{search $search\n};
		foreach my $nameserver ( @nameservers ) {
			$resolvTemplate{apply}{1}{content} .= qq{nameserver $nameserver\n};
		}

		$generatedFiles{resolv} = \%resolvTemplate;

	}

	if ( $distro eq 'Ubuntu' ) {
		my $resolvPrecedence = 'ipv6';
		if ( defined $currentOvf{'network.resolv.precedence'} and $currentOvf{'network.resolv.precedence'} eq 'ipv4' ) {
			$resolvPrecedence = $currentOvf{'network.resolv.precedence'};
			my %gaiPrecedence = %{ Storable::dclone( $networkVars{files}{'gai-precedence'} ) } if ( defined $networkVars{files}{'gai-precedence'} );

			if ( %gaiPrecedence and $resolvPrecedence eq 'ipv4' ) {
				$generatedFiles{'gai-precedence'} = \%gaiPrecedence;
			}

		}
	}

	# Markup the hostname
	if ( $hostName ) {
		$hostnameTemplate{apply}{1}{content} =~ s/<HOSTNAME>/$hostName/g;
		if ( $domainName ) {
			$hostnameTemplate{apply}{1}{content} =~ s/<DOMAIN>/.$domainName/g;
		} else {
			$hostnameTemplate{apply}{1}{content} =~ s/<DOMAIN>//g;
		}
		$generatedFiles{hostname} = \%hostnameTemplate;
	}

	if ( $distro eq 'SLES' ) {

		# SYNTAX EXAMPLE: default <IP> - -
		my %routesTemplate = %{ Storable::dclone( $networkVars{files}{routes} ) };
		my $routes;
		$routes .= qq{default $ipv4Gateway - -\n} if ( $ipv4Gateway );
		$routes .= qq{default $ipv6Gateway - -\n} if ( $ipv6Gateway ne '' );
		$routesTemplate{apply}{1}{content} = $routes;
		$generatedFiles{routes} = \%routesTemplate;
	}

	my $gatewaySetIpv6 = 0;
	my $gatewaySetIpv4 = 0;

	my %persistentUdev;
	if ( defined $networkVars{files}{'persistent'} ) {
		%persistentUdev = %{ Storable::dclone( $networkVars{files}{'persistent'} ) };
		$persistentUdev{apply}{1}{content} = '';
	}

	# Process the 'native' interfaces then aliases then bonded
	my %netIf = %{ $currentOvf{'network.if'} };
	foreach my $ifNum ( sort keys %netIf ) {
		dbg "configuring interface: $netIf{$ifNum}{'label'}\n";

		# Matching the 'VM MAC' with the defined interfaces. Order independent for the network.if
		my $if = $netIf{$ifNum}{if};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: network.if ($ifNum) 'if' not defined or not a digit } ) and next ) if ( !$if or !isdigit( $if ) );

		my $mac = $netIf{$if}{mac};
		# don't worry about mac on ubuntu
		if ($distro ne 'Ubuntu') {
			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Interface ($if) No matching VM Interface MAC address } ) and next ) if ( !$mac );
			$mac = lc( $mac );    # SLES seems sensitive to having lowercase mac for the udev rules
		}

		my $label = $netIf{$ifNum}{label};
		( Sys::Syslog::syslog( 'err', qq{::SKIP:: Interface ($if) Missing label } ) and next ) if ( !$label );

		my $persistentUdevTemplate = $networkVars{files}{persistent}{apply}{1}{content} if ( defined $networkVars{files}{persistent}{apply}{1}{content} );

		my $onboot = $networkVars{defaults}{onboot};
		if ( $netIf{$ifNum}{onboot} ) {
			$onboot = $netIf{$ifNum}{onboot};
		}

		# 'Native' interfaces
		if ( !$netIf{$ifNum}{'master-label'} ) {

			my %ifTemplate = %{ Storable::dclone( $networkVars{files}{if} ) };

			my $ipv4          = $networkVars{defaults}{'ipv4'};
			my $ipv6          = $networkVars{defaults}{'ipv6'};
			my $ipv4Prefix    = $networkVars{defaults}{'ipv4-prefix'};
			my $ipv6Prefix    = $networkVars{defaults}{'ipv6-prefix'};
			my $ipv4Bootproto = $networkVars{defaults}{'ipv4-bootproto'};
			my $ipv6Bootproto = $networkVars{defaults}{'ipv6-bootproto'};

			if ( defined $netIf{$ifNum}{'ipv4-bootproto'} and $netIf{$ifNum}{'ipv4-bootproto'} =~ /^(static|dhcp)$/ios ) {
				$ipv4Bootproto = lc( $netIf{$ifNum}{'ipv4-bootproto'} );
			}

			if ( defined $netIf{$ifNum}{'ipv6-bootproto'} and $netIf{$ifNum}{'ipv6-bootproto'} =~ /^(static|dhcp|auto)$/ios ) {
				$ipv6Bootproto = lc( $netIf{$ifNum}{'ipv6-bootproto'} );
			}

			if ( defined $netIf{$ifNum}{ipv4} ) {
				$ipv4 = $netIf{$ifNum}{ipv4};
			}

			if ( defined $netIf{$ifNum}{ipv6} ) {
				$ipv6 = $netIf{$ifNum}{ipv6};
			}

			if ( defined $netIf{$ifNum}{'ipv4-prefix'} ) {
				$ipv4Prefix = $netIf{$ifNum}{'ipv4-prefix'};
			}

			if ( defined $netIf{$ifNum}{'ipv6-prefix'} ) {
				$ipv6Prefix = $netIf{$ifNum}{'ipv6-prefix'};
			}

			$ifTemplate{path}              =~ s/<IF_LABEL>/$label/g;
			$ifTemplate{path}              =~ s/<IF_MAC>/$mac/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_LABEL>/$label/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_MAC>/$mac/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_ONBOOT>/$onboot/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_BOOTPROTO>/$ipv4Bootproto/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV4>/$ipv4/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV4_PREFIX>/$ipv4Prefix/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV4_GATEWAY>/$ipv4Gateway/g;

			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV6>/$ipv6/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV6_PREFIX>/$ipv6Prefix/g;
			$ifTemplate{apply}{1}{content} =~ s/<IF_IPV6_GATEWAY>/$ipv6Gateway/g;

			if ( defined $persistentUdev{apply} and defined $persistentUdevTemplate ) {
				$persistentUdevTemplate =~ s/<IF_MAC>/$mac/g;
				$persistentUdevTemplate =~ s/<IF_LABEL>/$label/g;

				$persistentUdev{apply}{1}{content} .= $persistentUdevTemplate . "\n";
			}

			if ( $distro eq 'Ubuntu' ) {
				$ifTemplate{path} =~ s/<IF_LABEL>/$label/g;

				# set the mac, unless none was given
				my $macSet = ($mac) ? 0 : 1;

				# IPv4 config
				$ifTemplate{apply}{1}{content} .= qq{auto $label\n};

				if ( $ipv4Bootproto ne 'disable' ) {
					$ifTemplate{apply}{1}{content} .= qq{iface $label inet $ipv4Bootproto\n};
					if ( !$macSet ) {
						$ifTemplate{apply}{1}{content} .= qq{\thwaddress ether $mac\n};
						$macSet = 1;
					}

					if ( $ipv4Bootproto eq 'static' and $ipv4 and $ipv4Prefix ) {
						$ifTemplate{apply}{1}{content} .= qq{\taddress $ipv4/$ipv4Prefix\n};
						if ( !$gatewaySetIpv4 ) {
							$ifTemplate{apply}{1}{content} .= qq{\tgateway $ipv4Gateway\n};
							$ifTemplate{apply}{1}{content} .= qq{\tdns-nameservers } . join( ' ', @nameservers ) . qq{\n};
							$ifTemplate{apply}{1}{content} .= qq{\tdns-search $search\n};
							$gatewaySetIpv4 = 1;
						}
					}
				}

				# IPv6 config
				if ( $ipv6Bootproto ne 'disable' ) {
					$ifTemplate{apply}{1}{content} .= qq{iface $label inet6 $ipv6Bootproto\n};
					$ifTemplate{apply}{1}{content} .= qq{\thwaddress ether $mac\n} if ( !$macSet );

					if ( ( $ipv6Bootproto eq 'static' ) and $ipv6 and $ipv6Prefix ) {
						$ifTemplate{apply}{1}{content} .= qq{\taddress $ipv6/$ipv6Prefix\n};
						if ( !$gatewaySetIpv6 ) {
							$ifTemplate{apply}{1}{content} .= qq{\tgateway $ipv6Gateway\n};
							$ifTemplate{apply}{1}{content} .= qq{\tdns-nameservers } . join( ' ', @nameservers ) . qq{\n};
							$ifTemplate{apply}{1}{content} .= qq{\tdns-search $search\n};
							$gatewaySetIpv6 = 1;
						}
					}
				}

			}

			$generatedFiles{"if-$if"} = \%ifTemplate;

			# Slaves
		} elsif ( $netIf{$ifNum}{'master-label'} ) {

			my %ifSlaveTemplate = %{ Storable::dclone( $networkVars{files}{ifSlave} ) };

			my $masterLabel = $netIf{$ifNum}{'master-label'};

			( Sys::Syslog::syslog( 'err', qq{::SKIP:: network.bond not defined for slave ($ifNum) master $masterLabel} ) and next ) if ( !defined $currentOvf{'network.bond'} );

			my %netBond = %{ $currentOvf{'network.bond'} };

			my $halt = 1;
			foreach my $ifNum ( sort keys %netBond ) {
				if ( defined $netBond{$ifNum}{'label'} and $netBond{$ifNum}{'label'} eq $masterLabel ) {
					$halt = 0;
					last;
				}
			}

			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Slave ($ifNum) label doesn't match any declared BOND interfaces} ) and next ) if ( $halt );

			if ( $distro eq 'Ubuntu' ) {
				$ifSlaveTemplate{path} =~ s/<IF_LABEL>/$label/g;
				$ifSlaveTemplate{apply}{1}{content} .= qq{auto $label\n};
				$ifSlaveTemplate{apply}{1}{content} .= qq{iface $label inet manual\n};
				$ifSlaveTemplate{apply}{1}{content} .= qq{\thwaddress ether $mac\n};
				$ifSlaveTemplate{apply}{1}{content} .= qq{iface $label inet6 manual\n};
				$ifSlaveTemplate{apply}{1}{content} .= qq{bond-master $masterLabel\n};
			} else {
				$ifSlaveTemplate{path}              =~ s/<IF_LABEL>/$label/g;
				$ifSlaveTemplate{path}              =~ s/<IF_MAC>/$mac/g;
				$ifSlaveTemplate{apply}{1}{content} =~ s/<IF_LABEL>/$label/g;
				$ifSlaveTemplate{apply}{1}{content} =~ s/<IF_MAC>/$mac/g;
				$ifSlaveTemplate{apply}{1}{content} =~ s/<IF_ONBOOT>/$onboot/g;
				$ifSlaveTemplate{apply}{1}{content} =~ s/<IF_MASTER_LABEL>/$masterLabel/g;
			}

			if ( defined $persistentUdev{apply} and defined $persistentUdevTemplate ) {

				$persistentUdevTemplate =~ s/<IF_MAC>/$mac/g;
				$persistentUdevTemplate =~ s/<IF_LABEL>/$label/g;

				$persistentUdev{apply}{1}{content} .= $persistentUdevTemplate . "\n";
			}

			$generatedFiles{"ifSlave-$label"} = \%ifSlaveTemplate;

		}

		$generatedFiles{persistent} = \%persistentUdev if ( %persistentUdev );

	}

	if ( $currentOvf{'network.alias'} ) {
		my %netAlias = %{ $currentOvf{'network.alias'} };

		# Alias definitions
		foreach my $ifNum ( sort keys %netAlias ) {

			my %ifAliasTemplate;
			my %slesAliasTemplate;

			if ( $distro eq 'SLES' ) {
				%slesAliasTemplate = %{ Storable::dclone( $networkVars{templates}{ifAlias} ) };
			} else {
				%ifAliasTemplate = %{ Storable::dclone( $networkVars{files}{ifAlias} ) };
			}

			my $ifForAlias = $netAlias{$ifNum}{if};
			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Alias ($ifForAlias) No matching 'physical' interface } ) and next ) if ( !$currentOvf{'network.if'}{$ifForAlias} );
			my $label = $netAlias{$ifNum}{label};
			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Alias ($ifForAlias) Missing label } ) and next ) if ( !$label );

			# SLES 10 uses mac for labeling interface files
			my $mac;
			if ( $distro eq 'SLES' ) {
				$mac = $netIf{$ifForAlias}{mac};
				( Sys::Syslog::syslog( 'err', qq{::SKIP:: Alias ($ifForAlias) No matching VM Interface MAC address } ) and next ) if ( !$mac );
			}

			my $onparent = $networkVars{defaults}{'onparent'};
			if ( $netAlias{$ifNum}{onparent} ) {
				$onparent = $netAlias{$ifNum}{onparent};
			}

			my $ipv4          = $networkVars{defaults}{'ipv4'};
			my $ipv6          = $networkVars{defaults}{'ipv6'};
			my $ipv4Prefix    = $networkVars{defaults}{'ipv4-prefix'};
			my $ipv6Prefix    = $networkVars{defaults}{'ipv6-prefix'};
			my $ipv4Bootproto = $networkVars{defaults}{'ipv4-bootproto'};
			my $ipv6Bootproto = $networkVars{defaults}{'ipv6-bootproto'};

			if ( defined $netAlias{$ifNum}{'ipv4-bootproto'} and $netAlias{$ifNum}{'ipv4-bootproto'} =~ /^(static|dhcp)$/ios ) {
				$ipv4Bootproto = lc( $netAlias{$ifNum}{'ipv4-bootproto'} );
			}

			if ( defined $netAlias{$ifNum}{'ipv6-bootproto'} and $netAlias{$ifNum}{'ipv6-bootproto'} =~ /^(static|dhcp|auto)$/ios ) {
				$ipv6Bootproto = lc( $netAlias{$ifNum}{'ipv6-bootproto'} );
			}

			if ( defined $netAlias{$ifNum}{ipv4} ) {
				$ipv4 = $netAlias{$ifNum}{ipv4};
			}
			if ( defined $netAlias{$ifNum}{ipv6} ) {
				$ipv6 = $netAlias{$ifNum}{ipv6};
			}
			if ( defined $netAlias{$ifNum}{'ipv4-prefix'} ) {
				$ipv4Prefix = $netAlias{$ifNum}{'ipv4-prefix'};
			}
			if ( defined $netAlias{$ifNum}{'ipv6-prefix'} ) {
				$ipv6Prefix = $netAlias{$ifNum}{'ipv6-prefix'};
			}

			# SLES appends to the parent interface
			if ( $distro eq 'SLES' ) {

				$slesAliasTemplate{content} =~ s/<IF_LABEL>/$label/g;
				if ( $ipv6 ) {
					$slesAliasTemplate{content} =~ s/<IF_IP>/$ipv6/g;
					$slesAliasTemplate{content} =~ s/<IF_IP_PREFIX>/$ipv6Prefix/g;
				} else {
					$slesAliasTemplate{content} =~ s/<IF_IP>/$ipv4/g;
					$slesAliasTemplate{content} =~ s/<IF_IP_PREFIX>/$ipv4Prefix/g;
				}

				# Concat to the 'native' interface the alias was defined
				$generatedFiles{"if-$ifForAlias"}{apply}{1}{content} .= $slesAliasTemplate{content};

			} elsif ( $distro eq 'Ubuntu' ) {

				$ifAliasTemplate{path} =~ s/<IF_LABEL>/$label/g;
				$ifAliasTemplate{apply}{1}{content} .= qq{auto $label\n};

				if ( $ipv4Bootproto ne 'disable' ) {
					$ifAliasTemplate{apply}{1}{content} .= qq{iface $label inet $ipv4Bootproto\n};
					if ( $ipv4Bootproto eq 'static' and $ipv4 and $ipv4Prefix ) {
						$ifAliasTemplate{apply}{1}{content} .= qq{\taddress $ipv4/$ipv4Prefix\n};
					}
				}

				if ( $ipv6Bootproto ne 'disable' ) {

					$ifAliasTemplate{apply}{1}{content} .= qq{iface $label inet6 $ipv6Bootproto\n};
					if ( $ipv6Bootproto eq 'static' and $ipv6 and $ipv6Prefix ) {

						$ifAliasTemplate{apply}{1}{content} .= qq{\taddress $ipv6/$ipv6Prefix\n};
					}
				}

				$generatedFiles{"ifAlias-$label"} = \%ifAliasTemplate;

			} else {

				$ifAliasTemplate{path}              =~ s/<IF_LABEL>/$label/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_LABEL>/$label/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_ONPARENT>/$onparent/g;

				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV4>/$ipv4/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV4_PREFIX>/$ipv4Prefix/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV4_GATEWAY>/$ipv4Gateway/g;

				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV6>/$ipv6/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV6_PREFIX>/$ipv6Prefix/g;
				$ifAliasTemplate{apply}{1}{content} =~ s/<IF_IPV6_GATEWAY>/$ipv6Gateway/g;

				$generatedFiles{"ifAlias-$label"} = \%ifAliasTemplate;

			}

		}
	}

	if ( $currentOvf{'network.bond'} ) {

		# Bond definitions
		my %netBond = %{ $currentOvf{'network.bond'} };

		foreach my $ifNum ( sort keys %netBond ) {

			my %ifBondTemplate = %{ Storable::dclone( $networkVars{files}{ifBond} ) };

			my $label = $netBond{$ifNum}{label};
			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Bond ($ifNum) Missing label} ) and next ) if ( !$label );
			
			my $slaves = $netBond{$ifNum}{'if-slaves'};
            ( Sys::Syslog::syslog( 'err', qq{::SKIP:: Bond ($ifNum) Missing slaves} ) and next ) if ( !$slaves );

			my @slaves = split( /,/, $netBond{$ifNum}{'if-slaves'} );
			my $halt   = scalar( @slaves );
			foreach my $slave ( @slaves ) {
				( Sys::Syslog::syslog( 'err', qq{::SKIP:: Bond ($ifNum) if-slaves ($slave) not an integer} ) and next ) if ( $slave !~ /^\d+$/ );				
				foreach my $ifNum ( sort keys %netIf ) {
					if ( defined $netIf{$ifNum}{'if'} and $netIf{$ifNum}{'if'} eq $slave ) {
						$halt--;
					}
				}
			}
			( Sys::Syslog::syslog( 'err', qq{::SKIP:: Bond ($ifNum) Not all if-slaves have matching 'physical' interfaces} ) and next ) if ( $halt != 0 );

			my $onboot = $networkVars{defaults}{'onboot'};
			if ( $netBond{$ifNum}{onboot} ) {
				$onboot = $netBond{$ifNum}{onboot};
			}

			my $bondOptions = $networkVars{defaults}{'bond-options'};
			if ( $netBond{$ifNum}{opts} ) {
				$bondOptions = $netBond{$ifNum}{opts};
			}

			my $ipv4          = $networkVars{defaults}{'ipv4'};
			my $ipv6          = $networkVars{defaults}{'ipv6'};
			my $ipv4Prefix    = $networkVars{defaults}{'ipv4-prefix'};
			my $ipv6Prefix    = $networkVars{defaults}{'ipv6-prefix'};
			my $ipv4Bootproto = $networkVars{defaults}{'ipv4-bootproto'};
			my $ipv6Bootproto = $networkVars{defaults}{'ipv6-bootproto'};

			if ( defined $netBond{$ifNum}{'ipv4-bootproto'} and $netBond{$ifNum}{'ipv4-bootproto'} =~ /^(static|dhcp)$/ios ) {
				$ipv4Bootproto = lc( $netBond{$ifNum}{'ipv4-bootproto'} );
			}

			if ( defined $netBond{$ifNum}{'ipv6-bootproto'} and $netBond{$ifNum}{'ipv6-bootproto'} =~ /^(static|dhcp|auto)$/ios ) {
				$ipv6Bootproto = lc( $netBond{$ifNum}{'ipv6-bootproto'} );
			}

			if ( defined $netBond{$ifNum}{ipv4} ) {
				$ipv4 = $netBond{$ifNum}{ipv4};
			}
			if ( defined $netBond{$ifNum}{ipv6} ) {
				$ipv6 = $netBond{$ifNum}{ipv6};
			}
			if ( defined $netBond{$ifNum}{'ipv4-prefix'} ) {
				$ipv4Prefix = $netBond{$ifNum}{'ipv4-prefix'};
			}
			if ( defined $netBond{$ifNum}{'ipv6-prefix'} ) {
				$ipv6Prefix = $netBond{$ifNum}{'ipv6-prefix'};
			}

			if ( $distro eq 'Ubuntu' ) {

				$ifBondTemplate{path} =~ s/<IF_LABEL>/$label/g;
				$ifBondTemplate{apply}{1}{content} .= qq{auto $label\n};

				if ( $ipv4Bootproto ne 'disable' ) {
					$ifBondTemplate{apply}{1}{content} .= qq{iface $label inet static\n};

					if ( $ipv4Bootproto eq 'static' and $ipv4 and $ipv4Prefix ) {
						$ifBondTemplate{apply}{1}{content} .= qq{\taddress $ipv4/$ipv4Prefix\n};
						if ( !$gatewaySetIpv4 ) {
							$ifBondTemplate{apply}{1}{content} .= qq{\tgateway $ipv4Gateway\n};
							$ifBondTemplate{apply}{1}{content} .= qq{\tdns-nameservers } . join( ' ', @nameservers ) . qq{\n};
							$ifBondTemplate{apply}{1}{content} .= qq{\tdns-search $search\n};
							$gatewaySetIpv4 = 1;
						}
					}
				}

				if ( $ipv6Bootproto ne 'disable' ) {
					$ifBondTemplate{apply}{1}{content} .= qq{iface $label inet6 static\n};

					if ( $ipv6Bootproto eq 'static' and $ipv6 and $ipv6Prefix ) {
						$ifBondTemplate{apply}{1}{content} .= qq{\taddress $ipv6/$ipv6Prefix\n};
						if ( !$gatewaySetIpv6 ) {
							$ifBondTemplate{apply}{1}{content} .= qq{\tgateway $ipv6Gateway\n};
							$ifBondTemplate{apply}{1}{content} .= qq{\tdns-nameservers } . join( ' ', @nameservers ) . qq{\n};
							$ifBondTemplate{apply}{1}{content} .= qq{\tdns-search $search\n};
							$gatewaySetIpv6 = 1;
						}
					}
				}

				if ( $bondOptions ) {
					my @options = split( /\s+/, $bondOptions );
					foreach my $opt ( @options ) {
						my ( $key, $value ) = split( /=/, $opt );
						$ifBondTemplate{apply}{1}{content} .= qq{bond-$key $value\n};
					}
				}

				my $bondedSlaves;
				foreach my $slave ( @slaves ) {
					$bondedSlaves .= $netIf{$slave}{label} . q{ };
				}

				$ifBondTemplate{apply}{1}{content} .= qq{bond-slaves $bondedSlaves};

			} else {

				$ifBondTemplate{path}              =~ s/<IF_LABEL>/$label/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_LABEL>/$label/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_ONBOOT>/$onboot/g;

				$ifBondTemplate{apply}{1}{content} =~ s/<IF_BOND_OPTIONS>/$bondOptions/g;

				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV4>/$ipv4/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV4_PREFIX>/$ipv4Prefix/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV4_GATEWAY>/$ipv4Gateway/g;

				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV6>/$ipv6/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV6_PREFIX>/$ipv6Prefix/g;
				$ifBondTemplate{apply}{1}{content} =~ s/<IF_IPV6_GATEWAY>/$ipv6Gateway/g;

			}

			if ( $distro eq 'SLES' ) {

				# SYNTAX EXAMPLE: BONDING_SLAVE0='eth0'
				my @bondSlaves;
				my $bondCount = 1;
				foreach my $slave ( @slaves ) {
					push( @bondSlaves, qq{BONDING_SLAVE$bondCount='} . $netIf{$slave}{label} . q{'} );
					$bondCount++;
				}
				my $bondSlavesLines = join( "\n", @bondSlaves );
				$ifBondTemplate{apply}{1}{content} =~ s/<BONDING_SLAVES>/$bondSlavesLines/;
			}

			$generatedFiles{"ifBond-$label"} = \%ifBondTemplate;

		}
	}

	# Ubuntu needs the default 'interfaces' file modified.
	$generatedFiles{'interfaces'} = $networkVars{files}{interfaces} if ( $distro eq 'Ubuntu' );

	OVF::Manage::Files::create( %options, %generatedFiles );
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub destroy ( \% ) {

	my %options = %{ ( shift ) };

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $rmCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{rmCmd};

	my %networkVars = %{ $OVF::Network::Vars::network{$distro}{$major}{$minor}{$arch} };

	my $ifcfgPath   = $networkVars{remove}{path};
	my $ifcfgPrefix = $networkVars{remove}{prefix};

	# Find all 'ifcfg-' files and remove them KEEP the loopback interface.
	my $findCmd = qq{find $ifcfgPath -maxdepth 1 -type f \\( -iname '$ifcfgPrefix*' ! -iname '$ifcfgPrefix} . q{lo' \)};
	my @rmFiles = qx{ $findCmd };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ($ifcfgPath) ...} );

	if ( !@rmFiles ) {
		Sys::Syslog::syslog( 'info', qq{::SKIP:: NO $ifcfgPrefix* files found.} );
		return;
	}

	foreach my $rmFile ( @rmFiles ) {
		chomp( $rmFile );
		Sys::Syslog::syslog( 'info', qq{REMOVING: ($rmFile) ...} );
		system( qq{$rmCmd "$rmFile" $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{Couldn't remove ($rmCmd "$rmFile") ($?:$!) } );
	}
	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );
}

sub restartNetwork ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my %options = %{ ( shift ) };

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my @restartCmds = @{ $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{restartCmds} };

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	foreach my $restartCmd ( @restartCmds ) {
		system( qq{$restartCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{Couldn't restart the network ($restartCmd) ($?:$!) } );
	}

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

sub resetHostname ( \% ) {

	my $thisSubName = ( caller( 0 ) )[ 3 ];

	my %options = %{ ( shift ) };

	my $action = $thisSubName;
	my $arch   = $options{ovf}{current}{'host.architecture'};
	my $distro = $options{ovf}{current}{'host.distribution'};
	my $major  = $options{ovf}{current}{'host.major'};
	my $minor  = $options{ovf}{current}{'host.minor'};

	my $resetCmd = $OVF::Vars::Common::sysCmds{$sysDistro}{$sysVersion}{$sysArch}{$thisSubName}{resetCmd};

	Sys::Syslog::syslog( 'info', qq{$action INITIATE ...} );

	system( qq{$resetCmd $quietCmd} ) == 0 or Sys::Syslog::syslog( 'warning', qq{Couldn't reset the hostname ($resetCmd) ($?:$!) } );

	Sys::Syslog::syslog( 'info', qq{$action COMPLETE} );

}

1;

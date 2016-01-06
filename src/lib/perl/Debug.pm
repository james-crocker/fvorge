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

package Debug;
use Exporter ();
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw(&debugging &dbg &dbg_hash);
@EXPORT_OK = qw(&debugging &dbg &dbg_hash);
%EXPORT_TAGS = ();

use strict;

my $_dbg = 0;
sub debugging { # params: [0|1 = disable/enable debug]
	$_dbg = shift;
}

sub mysprintf {
	return @_ if (@_ < 1);
	my $fmt = shift;
	return sprintf($fmt, @_);
}

sub msg {
	chomp(my $s = mysprintf(@_));
	print STDERR "$s\n";
}

sub dbg {
	if ($ENV{'OVF_DEBUG'} || $_dbg) {
		msg(@_);
	}
}

sub dbg_hash {
	my $preface = $_[0];
	my $data = $_[1];
	my $level = $_[2] || 1; # default indent level = 1

	return if (! $ENV{'OVF_DEBUG'} && ! $_dbg);

	if ($preface ne '') { msg "\n$preface\n"; }

	foreach (keys %$data) {
		if (ref($data->{$_}) eq 'HASH') {
			print STDERR " " x (4 * $level);
			print STDERR "$_:\n";
			dbg_hash('', $data->{$_}, $level + 1);
		} else {
			print STDERR " " x (4 * $level);
			print STDERR "$_: $data->{$_}\n";
		}
	}
}

1;

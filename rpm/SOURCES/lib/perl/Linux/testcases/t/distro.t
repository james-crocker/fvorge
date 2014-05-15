# Copyright (c) 2014 SIOS Technology Corp.
# Tests for the Linux distribution module
use Test::More tests => 2;

BEGIN {
    push @INC, "..";
}

use Distribution;
fail();
# does the distro id logic work?
# note: if not building on ubuntu, just skip this for now...
open(LSB, "< /etc/lsb-release") or die('no /etc/lsb-release');
if (grep /Ubuntu/, <LSB>) {
	# note: we build on ubuntu 13.10, if this changes, then change this...
	is(Linux::Distribution::distribution_name(), 'ubuntu', 'the distro name should be ubuntu');
	is(Linux::Distribution::distribution_version(), '13.10', 'the distro version is 13.10');
} else {
	pass('not testing distro');
	pass('not testing distro');
}

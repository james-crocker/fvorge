# Copyright (c) 2014 SIOS Technology Corp.
# Tests for the Linux distribution module
use Test::More;

use File::Find;

# Get directories under 'lib/perl', 'bin', 'sbin'
my @dirs = ('../../src/lib/perl', '../../src/bin', '../../src/sbin');

finddepth( \&wanted, @dirs );

done_testing();

sub wanted {
    my $file = $_;
    my $fullPath = $File::Find::name;
    my $dir = $File::Find::dir;
    if ( !-d $file ) {
    	if ( $file =~ /\.(pm|pl)$/ ) {
	        # Already 'cd'ed into the working directory
    	    my $ret = qx{perl -c $file 2>&1}; # perl -c goes to STDERR
        	$ret =~ s/\R//g if ( $? == 0 ); # Remove linebreaks on OK for readability.
        	is( $?, 0, qq{($File::Find::name) $ret} );
    	} else {
    		pass( qq{($File::Find::name) not a perl *.pm|pl} );
    	}
    }
}

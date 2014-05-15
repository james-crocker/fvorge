#!/usr/bin/perl

# Get propterties as reported via ovftool and prepare for use in ovftool for scripting changes

my $ovftoolBin = 'ovftool --machineOutput';
my $sourceOvf  = $ARGV[0];

$sourceOvf = 'http://fvorge.sc.steeleye.com/~fvorge/ovf/02-11-02-01-OVF/02-11-02-01-OVF.ovf' if ( !defined $sourceOvf );

@ovfProperties = qx{$ovftoolBin $sourceOvf};

my @key;
my $value;

my $onClassid = 0;
my $onKey = 0;
my $onInstanceid = 0;
my $onValue = 0;

my $next = 1;
foreach my $ovfp ( @ovfProperties ) {

	chomp( $ovfp );

	$ovfp =~ s/^\+\s+//;

	#print "OVFP: $ovfp\n";

	# Skip till we get to properties
	if ( $ovfp =~ /<properties>/ ) {
		$next = 0;
		next;
	}
	next if ( $next );

	if ( $ovfp =~ /^<\/property>$/ ) {
		print '--prop:"'.join('.', @key)."\"=\"$value\" \\\n";
		$value = '';

		$onClassid = 0;
		$onKey = 0;
		$onInstanceid = 0;
		$onValue =0;

		@key = ();
		next;
	}

	if ( $ovfp =~ /^<value>$/ ) {
		$onValue = 1;
		next;
	} elsif ( $ovfp =~ /^<\/value>$/ ) {
		$onValue = 0;
		next;
	}

	if ( $ovfp =~ /^<classId>$/ ) {
		$onClassid = 1;
		next;
	} elsif ( $ovfp =~ /^<\/classId>$/ ) {
		$onClassid = 0;
		next;
	}
		
	if ( $ovfp =~ /^<key>$/ ) {
		$onKey = 1;
		next;
	} elsif ( $ovfp =~ /^<\/key>$/ ) {
		$onKey = 0;
		next;
	}
		
	if ( $ovfp =~ /^<instanceId>$/ ) {
		$onInstanceid = 1;
		next;
	} elsif ( $ovfp =~ /^<\/instanceId>$/ ) {
		$onInstanceid = 0;
		next;
	}
		
	if ( $onValue ) {
		$value = $ovfp;
		$onValue = 0;
		next;
	}

	if ( $onClassid ) {
		push( @key, $ovfp );
		$onClassid = 0;
		next;
	}

	if ( $onKey ) {
		push( @key, $ovfp );
		$onKey = 0;
		next;
	}

	if ( $onInstanceid ) {
		push( @key, $ovfp );
		$onInstanceid = 0;
		next;
	}

}

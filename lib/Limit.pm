#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Limit;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $Limit    = bless {tests => []};
	$Limit->add(@_);
	return $Limit;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub add {
	my $Limit     = shift;
	my $test      = shift;
	my $threshold = shift;
	push @{$Limit->{tests}}, [$test, int($threshold)];
}

sub matches {
	my $Limit = shift;
	my $value = int shift;
	foreach my $test (@{$Limit->{tests}}) {
		my ($test, $threshold) = @{$test};
		if    ($test eq '>=') { return 0 unless $value >= $threshold; }
		elsif ($test eq '>' ) { return 0 unless $value >  $threshold; }
		elsif ($test eq '<=') { return 0 unless $value <= $threshold; }
		elsif ($test eq '<' ) { return 0 unless $value <  $threshold; }
	}
	return 1;
}

sub parse {
	my $Limit  = shift;
	my $string = shift;
    my $tokens = $string;
    my $test   = undef;
    while ($tokens)  {
    	if ($tokens =~ s/^([<>]=?)//) {
    		$test = $1;
    	} elsif ($tokens =~ s/^(\d+([.]\d+)?)//) {
    		$threshold = $1;
    		$Limit->add($test, $threshold);
    	} else {
    		$tokens =~ s/^\s+//;
    	}
    }
}

sub string {
	my $Limit = shift;
	my @tests = ();
	foreach my $test (@{$Limit->{tests}}) {
		push @tests, sprintf('%s %s', @{$test});
	}
	return join(' ', @tests);
}


1;
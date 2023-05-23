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

# $Limit->add(test:string, threshold:number)
#
# Adds a threshold test to the Limit.  The test must be one of '>', '>=', '<' or
# '<=' and the threshold is on the right side of the test (i.e. > threshold 
# means the amount must be greater than the threshold).  More than one test can
# be added (i.e. > lower bound, < upper bound) but there is no checking to 
# ensure the thresholds delimit a non-empty set.
#
sub add {
	my $Limit     = shift;
	my $test      = shift;
	my $threshold = shift;
	push @{$Limit->{tests}}, [$test, int($threshold)];
}


# $Limit->matches(value) => 0|1
#
# Returns 1 if the value meets the threshold tests, 0 otherwise.
#
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



1;

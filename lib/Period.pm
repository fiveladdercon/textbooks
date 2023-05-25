#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Period;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

use overload '""' => sub { shift->display; };

# YYYY
# YYYY-MM
# YYYY-MM:YYYY-MM
# YYYY-MM-DD:YYYY-MM-DD

sub new {
	my $invocant      = shift;
	my $class         = ref($invocant) || $invocant;
	my ($start, $end) = split /:/, shift;

	sub expand {
		my $date = shift;
		my ($year, $month, $day) = split /-/, $date;
		$day   = pop unless defined $day;
		$month = pop unless defined $month;
		return sprintf('%04d-%02d-%02d', $year, $month, $day);
	}

	$end   = $start unless defined $end;
	$end   = &expand($end, 12, 31);
	$start = &expand($start, 1, 1);
	return bless {start => $start, end => $end};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub end {
	return shift->{end};
}

sub start {
	return shift->{start};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Period->contains(Date) => 0|1
#
# Returns true if the Date supplied is or is after the start Date and is or is
# before the end Date.
#
sub contains {
	my $Period = shift;
	my $date   = shift;
	return (($Period->{start} le $date) and ($date le $Period->{end}));
}

# $Period->display(%options) => string
#
# Returns a display string.
#
sub display {
	my $Period = shift;
	return join(":", $Period->{start}, $Period->{end});
}


# $Period->overlaps(Period) => 0|1
#
# Returns true if this Period contains the start date or end date of the other 
# Period.
#
sub overlaps {
	my $Period    = shift;
	my $Reference = shift;
	return ($Reference->contains($Period->{start}) or $Period->contains($Reference->{start}))
}



1;

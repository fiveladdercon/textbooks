#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Period;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

use overload '""' => sub { shift->string; };

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

sub contains {
	my $Period = shift;
	my $date   = shift;
	return (($Period->{start} le $date) and ($date le $Period->{end}));
}

sub overlaps {
	my $Period    = shift;
	my $Reference = shift;
	return ($Reference->contains($Period->{start}) or $Period->contains($Reference->{start}))
}

sub string {
	my $Period = shift;
	return join(":", $Period->{start}, $Period->{end});
}


1;
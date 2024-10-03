#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Amount;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Console();

# Amount::column(number, zero=0) => string
#
# Returns the number as 10 character formatted string.  The number is two
# decimal places if it is non-zero or it is zero and the optional zero
# zeros flag is set.  Otherwise when it is zero and the optional show
# zeros flat is not set, the number is blank.  The number is colored red
# if it less than zero.
#
sub column {
	my $amount = shift;
	my $flags  = shift;
	return sprintf("%10.2f", $amount)      if $amount <= -.01 and $flags & 2;
	return Console::red("%10.2f", $amount) if $amount <= -.01;
	return sprintf("%10.2f", $amount)      if $amount >=  .01;
	return sprintf("%10.2f", 0)            if $flags & 1;
	return " " x 10;
}

# Amount::columns(debits, credits)          => (string, string)
# Amount::columns(debits, credits, balance) => (string, string, string)
#
# Returns a pair or triplet of formatted columns, depending on the
# number of arguments passed.
#
sub columns {
	my $debits  = shift;
	my $credits = shift;
	my $balance = shift;
	return (column($debits), column($credits)) unless defined $balance;
	return (column($debits), column($credits), column($balance, 1));
}

# Amount::net(debits, credits) => (string, string)
#
# Returns a formatted positive net amount in one column, a blank in the
# other column.
#
sub net {
	my $debits  = shift;
	my $credits = shift;
	return columns($debits - $credits, 0) if $debits > $credits;
	return columns(0, $credits - $debits);
}

# Amount::penny(number) => integer
#
# Converts a floating point amount to an integer for exact comparison.
#
sub penny {
	my $amount = shift;
	return int(sprintf("%.0f", 100 * $amount));
}



1;

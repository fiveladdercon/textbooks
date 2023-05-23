#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Entry;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Amount();
use Draw();

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my %options  = @_;
	my $Entry = {
		number  => $options{number},
		debits  => [],
		credits => []
	};
	return bless $Entry, $class;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub number {
	my $Entry  = shift;
	my $number = shift;
	$Entry->{number} = $number if defined $number;
	return $Entry->{number};
}

sub debits {
	return @{shift->{debits}};
}

sub credits {
	return @{shift->{credits}};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Properties
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Entry->valid => 0|1
#
# Return if the total debits equals the total credits.
#
sub valid {
	my $Entry   = shift;
	my $debits  = 0;
	my $credits = 0;
	foreach my $debit  ($Entry->debits ) { $debits  += $debit->{Action}->debit;    }
	foreach my $credit ($Entry->credits) { $credits += $credit->{Action}->credit ; }
	return Amount::penny($debits) == Amount::penny($credits); # Do an integer compare
}


#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Entry->action(Account, Action)
#
# Adds the Action to the Entry and updates the Entry pointer in the Action.
#
sub action {
	my $Entry   = shift;
	my $Account = shift;
	my $Action  = shift;
	$Action->{Entry} = $Entry;
	if ($Action->debit) {
		push @{$Entry->{debits}}, {Account => $Account, Action => $Action};
	} else {
		push @{$Entry->{credits}}, {Account => $Account, Action => $Action};
	}
}

# $Entry->credit(Account, date, item, amount)
#
# Creates a credit Action in the Account with the given date, item and amount
# then adds it to the Entry.
#
sub credit {
	my $Entry   = shift;
	my $Account = shift;
	my $date    = shift;
	my $item    = shift;
	my $amount  = shift;
	$Entry->action($Account, $Account->action(date=>$date, item=>$item, credit=>$amount));
}

# $Entry->debit(Account, date, item, amount)
#
# Creates a debit Action in the Account with the given date, item and amount
# then adds it to the Entry.
#
sub debit {
	my $Entry   = shift;
	my $Account = shift;
	my $date    = shift;
	my $item    = shift;
	my $amount  = shift;
	$Entry->action($Account, $Account->action(date=>$date, item=>$item, debit=>$amount));
}

# $Entry->display(%options) => string
#
# Returns the Entry as a highlighted display string.
#
sub display {
	my $Entry = shift;
	my $entry = defined $Entry->number ? sprintf("%06d", $Entry->number) : '';
	$string   = sprintf("ENTRY   %s\n", $entry);
	$string  .= $CHANGE::LINE;
	foreach my $debit (@{$Entry->{debits}}) {
		$string .= $debit->{Account}->display(entry => 1);
		$string .= $debit->{Action}->display(entry => 1);
	}
	foreach my $credit (@{$Entry->{credits}}) {
		$string .= $credit->{Account}->display(entry => 1);
		$string .= $credit->{Action}->display(entry => 1);
	}
	$string .= "\n\n";
	return $string;
}



1;

#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Entry;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Amount();
use Draw();
use Console();

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
# Getters/Setters
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
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub action {
	my $Entry   = shift;
	my $Account = shift;
	my $Action  = shift;
	if ($Action->debit) {
		$Entry->debit($Account, $Action);
	} else {
		$Entry->credit($Account, $Action);
	}
}

sub debit {
	# $Entry->debit($Account, $Action);
	# $Entry->debit($Account, $date, $item, $amount);
	my $Entry   = shift;
	my $Account = shift;
	my $Action  = $_[0]; 
	my $date    = shift;
	my $item    = shift;
	my $amount  = shift;
	$Action = $Account->action(date=>$date, item=>$item, debit=>$amount) unless ref $Action;
	$Action->{Entry} = $Entry;
	push @{$Entry->{debits}}, {Account => $Account, Action => $Action};
}

sub credit {
	# $Entry->credit($Account, $Action);
	# $Entry->credit($Account, $date, $item, $amount);
	my $Entry   = shift;
	my $Account = shift;
	my $Action  = $_[0]; 
	my $date    = shift;
	my $item    = shift;
	my $amount  = shift;
	$Action = $Account->action(date=>$date, item=>$item, credit=>$amount) unless ref $Action;
	$Action->{Entry} = $Entry;
	push @{$Entry->{credits}}, {Account => $Account, Action => $Action};
}

# sub parse {
# 	my $Entry  = shift;
# 	my $string = shift;
# 	foreach my $line (split /\n/, $string) {
# 		# The + 0 coerces the scalar into a true number.
# 		if ($line =~ s/^ENTRY\s+//) {
# 			my $number;
# 			my ($item, $date) = split /\s*,\s*/, $line;
# 			($number, $item)  = split /\s{6}/, $item, 2 if $item =~ m/^\d{6}\s{6}/;
# 			$Entry->{number}  = $number + 0 if defined $number;
# 			$Entry->{item}    = $item;
# 			$Entry->{date}    = $date;
# 		} elsif ($line =~ /,/) {
# 			my ($account, $debit, $credit) = split /\s*,\s*/, $line;
# 			# I can see a hand edited entry file only having a name pattern as
# 			# the account reference, but we'll assume for the moment that that
# 			# case is unlikely.
# 			$account =~ s/\s+.*//; # Toss the label & keep only the account id
# 			if ($debit) {
# 				push @{$Entry->{debits}}, {Account => $account, amount => $debit + 0};
# 			} else {
# 				push @{$Entry->{credits}}, {Account => $account, amount => $credit + 0};
# 			}
# 		}
# 	}
# }

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

sub valid {
	my $Entry   = shift;
	my $debits  = 0;
	my $credits = 0;
	foreach my $debit  ($Entry->debits ) { $debits  += $debit->{Action}->debit;    }
	foreach my $credit ($Entry->credits) { $credits += $credit->{Action}->credit ; }
	return Amount::penny($debits) == Amount::penny($credits); # Do an integer compare
}


1;
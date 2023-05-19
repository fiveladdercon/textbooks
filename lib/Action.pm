#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Action;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Amount();
use Draw();

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my %options  = @_;
	my $Action   = {
		#
		date    => $options{date},
		item    => $options{item},
		debit   => $options{debit}  || 0,
		credit  => $options{credit} || 0,
		balance => $options{balance},
		settled => 0,
		Line    => undef,
		#
		Entry   => undef,  # undef | number | Entry
		Pattern => undef,  # The Pattern used to select this Action, if any
	};

	return bless $Action, $class;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub Entry {
	return shift->{Entry};
}

sub Pattern {
	return shift->{Pattern};
}

sub Line {
	return shift->{Line};
}

sub balance {
	return shift->{balance};
}

sub credit {
	return shift->{credit};
}

sub date {
	return shift->{date};
}

sub debit {
	return shift->{debit};
}

sub item {
	return shift->{item};
}

sub settled {
	return shift->{settled};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Properties
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Action->amount => numbers
#
# Returns the debit or credit amount for limit checking.
#
sub amount {
	my $Action = shift;
	return $Action->{credit} + $Action->{debit};
}

# $Action->entry => string
#
# Returns a formatted Entry number as a string.  The Entry number is empty
# if the Action was imported and has no Entry, or it is an integer (if the 
# Action was loaded but not cross-referenced into an Entry) or it is the number 
# of the cross-referenced Entry.  This value is used in ledger reporting and 
# storage to uniquely identify the related Actions that form an Entry.
#
sub entry {
	my $Action = shift;
	my $entry  = $Action->Entry;
	   $entry  = $entry->number if ref $entry;
	return sprintf("%06d", $entry) if $entry;
	return "";
}

# $Action->identifer => string
#
# Returns a uniquely identify string
sub identifier {
	my $Action  = shift;
	my $date    = $Action->{date};
	my $item    = $Action->{item};
	my $debit   = $Action->{debit};
	my $credit  = $Action->{credit};
	my $balance = $Action->{balance};
	return sprintf("%s:%.2f:%.2f:%.2f",$date,$debit,$credit,$balance);
}

# $Action->net => number
#
# Returns the debits less the credits.
#
sub net {
	$Action = shift; return $Action->{debit} - $Action->{credit};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Action->display(%options) => string
#
# Returns the action as a highlighted display string.
# 
# ledger => 1  formatted for ledger reports
# entry  => 1  formatted for Entry reports
#
sub display {
	my $Action  = shift;
	my %options = @_;
	my $string  = "";
	my $date    = $Action->date;
	my $entry   = $Action->entry;
	my $item    = $Action->item;
	my $debit   = &Amount::column($Action->debit);
	my $credit  = &Amount::column($Action->credit);
	if ($options{ledger}) {
		$string = sprintf($CHANGE::ACTION, $date, $entry, $item, $debit, $credit);
	} elsif ($options{entry}) {
		$string = sprintf("    %10s, %-48s, %10s, %10s\n", $date, $item, $debit, $credit);
	}
	return $Action->Pattern->matches($string) if $Action->Pattern;
	return $string;
}

# $Action->eq(Action) => 0|1
#
# Returns true if both Actions are the same.  That is they have the same date,
# item, and debit, credit & balance values.
#
sub eq {
	$This = shift;
	$That = shift;
	return 0 unless $This->{date} eq $That->{date};
	return 0 unless $This->{item} eq $That->{item};
	# Using amount::column(x) equates 0 with "" and covers ACCOUNT OPEN & ACCOUNT CLOSE
	# actions with 0 valued debits or credits that get stored as "" after import.
	return 0 unless &Amount::column($This->{debit})   eq &Amount::column($That->{debit});
	return 0 unless &Amount::column($This->{credit})  eq &Amount::column($That->{credit});
	return 0 unless &Amount::column($This->{balance}) eq &Amount::column($That->{balance});
	return 1;
}

# get Action(Line) => Action
#
# Constructs an Action from a GL Line.
#
sub get {
	my $Action  = shift; $Action = new Action() unless ref $Action;
	my $Line    = shift;
	my @columns = $Line->csv;

	my ($date, $entry, $item, $debit, $credit, $balance) = $Line->csv;
	my $settled = $balance =~ s/ [*]$//;

	$Action->{date}    = $date;
	$Action->{Entry}   = int($entry) || undef;
	$Action->{item}    = $item;
	$Action->{debit}   = $debit  || 0;
	$Action->{credit}  = $credit || 0;
	$Action->{balance} = $balance;
	$Action->{settled} = $settled;
	$Action->{Line}    = $Line;

	return $Action;
}

# import Action(Line) => Action
#
# Constructs an Action from a bank record Line.
#
sub import {
	my $Action = shift; $Action = new Action unless ref $Action;
	my $Line   = shift;

	my ($date, $item, $debit, $credit, $balance) = $Line->csv;
	my ($mm,$dd,$yyyy) = split /\//, $date;

	#
	# Bank statements are from the bank's perspective, which is the opposite
	# of mine: A chequing account is a liability for the bank, and credits
	# increase the liability, while debits decrease the liability.  From
	# my perspective, however, the chequing account is an asset, so debits
	# should increase the asset, while credits decrease the asset.
	# 
	# In the following I flip the debit/credit to flip perspectives.
	#

	$Action->{date}    = "${yyyy}-${mm}-${dd}";
	$Action->{item}    = $item;
	$Action->{debit}   = $credit || 0;
	$Action->{credit}  = $debit  || 0;
	$Action->{balance} = $balance;
	$Action->{settled} = 1;
	$Action->{Line}    = $Line;

	return $Action;
}

# $Action->put(%options) => string
#
# Returns the Action as a storage string.
#
sub put {
	my $Action  = shift;
	my $date    = $Action->{date};
	my $entry   = $Action->entry; 
	my $item    = $Action->{item};
	my $debit   = &Amount::column($Action->{debit});
	my $credit  = &Amount::column($Action->{credit});
	return sprintf("%10s, %6s, %-44s, %10s, %10s\n", $date, $entry, $item, $debit, $credit) unless defined $Action->{balance};
	my $balance = $Action->{balance};
	my $settled = $Action->{settled} ? ' *' : '';
	return sprintf("%10s, %6s, %-44s, %10s, %10s, %10.2f%s\n", $date, $entry, $item, $debit, $credit, $balance, $settled);
}



1;

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

# A transaction has at least two Actions - at least one debit and at least one 
# credit.  Actions are bound together in an Entry.

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

# $Action->amount => number
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
# Returns a uniquely identify string.
#
# NOTE: this method is only used in an obsolete means to detecting import
#       collisions.  Since the obsolete method is still around, so is this
#       supporting method.
# 
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
# ledger   => 1        formatted for ledger reports
# balanced => 1        formatted for ledgers with balances
# entry    => 1        formatted for Entry reports
#
sub display {
	my $Action  = shift;
	my %options = @_;
	my $string  = "";
	my $Pattern = $Action->Pattern;
	my $date    = $Action->date;
	my $entry   = $Action->entry;
	my $item    = $Action->item;
	my $debit   = &Amount::column($Action->debit);
	my $credit  = &Amount::column($Action->credit);
	my $balance = &Amount::column($Action->balance, 1);
	if ($options{ledger}) {
		# Clip items to 41 characters to keep the report box lines in the right
		# place.  This is because there is a slight difference in format between
		# the GL and the report which comes from the fact that commas are 
		# omitted or replaced with padded box lines.
		#
		# GL     : %10s, %6s, %-44s, %10s, %10s, %10s
		# Report : %10s %6s %-41s │ %10s │ %10s │ %10s │
		#              +   +     -      -      -      --
		$item = substr($item, 0, 38)."..." if length($item) > 41;
		if ($options{balanced} and not $Pattern) {
			# Show the balance if you're supposed to, but not if a Pattern was
			# used to select the Action since the balance won't make much sense.
			$string = sprintf($STATE::ACTION, $date, $entry, $item, $debit, $credit, $balance);
		} else {
			$string = sprintf($CHANGE::ACTION, $date, $entry, $item, $debit, $credit);
		}
	} elsif ($options{entry}) {
		$string = sprintf("    %10s, %-48s, %10s, %10s\n", $date, $item, $debit, $credit);
	}
	# Pattern matching must happen after box drawing since box drawing
	# characters are not counted properly in string formatting.
	return $Pattern->matches($string) if $Pattern;
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
# Constructs an Action from a bank record Line, which has a slightly different
# format than a GL Line.  Most notably bank records are from the bank's point
# of view, not ours.
#
sub import {
	my $Action = shift; $Action = new Action unless ref $Action;
	my $Line   = shift;

	my ($date, $item, $debit, $credit, $balance) = $Line->csv;
	my ($mm,$dd,$yyyy) = split /\//, $date;

	#
	# Bank statements are from the bank's perspective, which is the opposite
	# of ours: A chequing account is a liability for the bank, and credits
	# increase the liability, while debits decrease the liability.  From
	# our perspective, however, the chequing account is an asset, so debits
	# should increase the asset, while credits decrease the asset.
	# 
	# In the following the debits & credits are flipped to flip perspectives.
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
	#my $balance = sprintf("%10.2f", $Action->{balance}); $balance = s/-0.00$/ 0.00/;
	my $balance = &Amount::column($Action->{balance}, 3);
	my $settled = $Action->{settled} ? ' *' : '';
	return sprintf("%10s, %6s, %-44s, %10s, %10s, %10s%s\n", $date, $entry, $item, $debit, $credit, $balance, $settled);
}



1;

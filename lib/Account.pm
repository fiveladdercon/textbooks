#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Account;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Action();
use Draw();

my %TYPE = (
	'A' => 'ASSET',
	'L' => 'LIABILITY',
	'I' => 'INCOME',
	'E' => 'EXPENSE'
);

sub new {
	my $invocant  = shift;
	my $class     = ref($invocant) || $invocant;
	my $type      = shift;
    my $Account   = {
    	#  
    	type        => exists $TYPE{$type} ? $TYPE{$type} : $type,
    	number      => shift,
    	Parent      => shift,  # Stored as the Account number of the Parent
    	name        => shift,
    	Line        => shift,
    	import      => undef,
    	Selections  => [],
    	Actions     => [],
    	#
    	Children    => [],
    	Name        => undef,  # The Name used to select this Account, if any
    };
	return bless $Account, $class;
}

# Actions created by importing bank records are generally immutable - they can 
# not be reordered, rebalanced or have actions added with Entries.  However they
# can be assigned to or removed from Entries (which is the whole point).

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub Actions {
	return  @{shift->{Actions}};
}

sub Children {
	return @{shift->{Children}};
}

sub Line {
	return shift->{Line};
}

sub Name {
	return shift->{Name};
}

sub Parent {
	return shift->{Parent};
}

sub Selections {
	return @{shift->{Selections}};
}

sub import {
	return shift->{import};
}

sub name {
	return shift->{name};
}

sub number {
	return shift->{number};
}

sub type {
	return shift->{type};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Properties
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Account->balanced => 0|1
#
# Returns whether the Account tracks a balance or not.
#
sub balanced {
	my $type = shift->{type};
	return 1 if ($type eq 'ASSET') or ($type eq 'LIABILITY');
	return 0;
}

# $Account->family => @Account
#
# Return a list of all Accounts in the family.
#
sub family {
	my $Account  = shift;
	my @Accounts = ($Account);
	foreach my $Child ($Account->Children) {
		push @Accounts, $Child->family;
	}
	return @Accounts;
}

# $Account->generation => number
#
# Returns hierarchical level of the account.
#
sub generation {
	my $Parent = shift->{Parent};
	return $Parent ? $Parent->generation + 1 : 0;
}

# $Account->line => string
#
# Returns a horizontal line with a width that depends on Account type.
#
sub line {
	return shift->balanced ? $STATE::LINE : $CHANGE::LINE;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Account->action(date => Date, item => string, debit|credit => number) => Action
#
# Add an Action to the Account via an Entry if the Account does not have 
# imported Actions.
#
sub action {
	my $Account = shift; return if $Account->import;
	my $Action  = new Action(@_);
	push @{$Account->{Actions}}, $Action; # Add the Action
	$Account->reorder;                    # Entries are not sequential
	return $Action;
}

# $Account->balances(%options) => (implicit, explicit)
#
# Returns the implicit and explicit balance for the Account, optionally
# including the balances of any Children.
#
# date   => Date  returns the balance as the the specified Date.
# rollup => 1     includes the balances from Children.
#
# The implicit balance is a value with an implicit sign: asset balances are 
# implicitly understood to have a positive sign while liability balances are 
# implicitly understood to have a negative sign.  Implicit balances are reported
# for each Account, since the sign is implied from the Account type.
#
# The explicit balance is a value with an explicit sign.  Liability balances
# are inverted from implied sign to explicit sign for the purpose of totalling
# accross Account types (e.g. while reporting a Balance Sheet).
#
sub balances {
	my $Account  = shift;
	my %options  = @_;
	my $date     = $options{date};
	my $implicit = 0;
	foreach $Action ($Account->Actions) {
		last if $date and $Action->date gt $date;
		$implicit = $Action->balance;
	}
	my $explicit = ($Account->type eq 'ASSET') ? $implicit : -$implicit;
	if ($options{rollup}) {
		foreach $Child ($Account->Children) {
			@balances = $Child->balances(%options);
			$implicit += $balances[0];
			$explicit += $balances[1];
		}
	}
	return ($implicit, $explicit);
}

# $Account->display(%options) => string
#
# Returns the Account identifier as a highlighted display string.
#
# ledger => 1  includes the header drawing for ledger reporting
# entry  => 1  includes the @ prefix for Entry reporting
#
sub display {
	my $Account = shift;
	my %options = @_;
	my $string  = "";
	if ($options{ledger}) {
		$string = sprintf($CHANGE::HEADER, $Account->identifier, '');
	} elsif ($options{entry}) {
		$string = sprintf("@%s\n", $Account->identifier);
	} else {
		$string = $Account->identifier;
	}
	return $Account->Name->matches($string) if $Account->Name;
	return $string;
}

# get Account(Line) => Account
#
# Constructs an Account from a storage string.
#
sub get {
	my $Account = shift; $Account = new Account() unless ref $Account;
	my $Line    = shift;

	my ($type, $number, $identifier) = split /\s+/, $Line, 3;
	my ($number, $parent) = split /:/, $number;
	my @name = split /:/, $identifier;
	my $name = pop @name; chomp $name;

	$Account->{type}   = $type;
	$Account->{number} = $number;
	$Account->{Parent} = $parent;
	$Account->{name}   = $name;
	$Account->{Line}   = $Line;

	return $Account;
}

# $Account->identifier(%options) => string
#
# Returns the name of the Account qualified by Parent names.
#
# implicit => 1  replaces Parent names with indentation
#
sub identifier {
	my $Account = shift;
	my %options = @_;
	return $Account->{name} unless $Account->{Parent};
	return join('', '  ' x $Account->generation, $Account->{name}) if $options{implicit};
	return join(':', $Account->{Parent}->identifier(%options), $Account->{name});
}

# $Account->put(%options) => string
#
# Returns the Account as a storage string
#
# %options are passed to $Account->identifer.
#
sub put {
	my $Account = shift;
	my %options = @_;
	return sprintf("%-9s %8s%-8s %s\n",
		$Account->{type},
		$Account->{number},
		$Account->{Parent} ? ':'.$Account->Parent->number : '',
		$Account->identifier(%options)
	);
}

# $Account->rebalance
#
# Recalcuate the Action balances if a non-imported, balanced Account.
#
sub rebalance {
	my $Account = shift; return if $Account->import or not $Account->balanced;
	my @Actions = $Account->Actions;
	my $sign    = ($Account->type eq 'ASSET') ? 1 : -1;
	my $balance = $Actions[0]->amount ? 0 : $Actions[0]->balance;
	foreach my $Action (@Actions) {
		$balance +=	$sign * ($Action->debit - $Action->credit);
		$Action->{balance} = $balance;
	}
}

# $Account->remove(Action)
#
# Remove an Action from the Account.  If the Action was imported, only the
# Entry reference is removed.  Otherwise the entire Action is removed.
#
sub remove {
	my $Account = shift;
	my $Action  = shift;
	if ($Account->import) {
		$Action->{Entry} = undef;
	} else {
		$Account->{Actions} = [grep { $_ != $Action } @{$Account->{Actions}}];
		$Account->rebalance;
	}
}

# $Account->reorder
#
# Resort the Actions by Date and rebalance if needed.
#
sub reorder {
	my $Account = shift; return if $Account->import;
	$Account->{Actions} = [sort { $a->date cmp $b->date } $Account->Actions];
	$Account->rebalance;
}

# $Account->totals(%options) => (debits - credits, 0) |
#                               (0, credits - debits) |
#                               (debits  , credits )  |
#                               (implicit, explicit)
#
# Returns net debits & credits for Actions with Entries for the Account.
#
# Period => PERIOD  includes only Actions contained in the PERIOD
# rollup => 1       includes totals from Children
# totals => 1       return debit & credit totals for two column reports
# signed => 1       return implicit & explicit totals for single column reports
#
# Two & three column reports have debit & credit columns, so two values are 
# returned. Normally the column with the larger total holds the net: 
# (debits-credits, 0) or (0, credits-debits). The totals option overrides this 
# to return (debits, credits).
#
# A one column report should return a single value: the net of debits & credits.
# Nominally this is always just debits - credits.  For accounts that are normally
# debited - namely assets & expenses - this difference is positive.  For
# accounts that are normally credited - namely liabilities & income - this
# difference is negative.  The signs make sense for assets (+) & liabilities (-)
# but are reversed for income (-) and expense (+), so the difference is reversed
# for income & expense accounts, i.e. credits - debits.  Even though liabilities
# and expenses are negative values, they are generally not reported that way
# because it is understood that they are negative values and so are reported as
# positive values.  Hence liabilities and expenses have there signs reversed for
# reporting.  The point is that there are two layers of sign flipping  between a
# simple difference and what's reported.
#
# explicit total  = (debits - credits) for Asset & Liability Accounts, 
#                   (credits - debits) for Income & Expense Accounts
# implicit total  =  explicit total    for Asset & Income Accounts
#                   -explicit total    for Liability & Expense Accounts
# 
# both the (explicit, implicit) totals are returned when the signed option is
# set. The implicit value is reported for the Account while the explicit value
# is used to total accross accounts of different types.  e.g. to find the net
# of income less expenses in and income & expense report
#
sub totals {
	my $Account = shift;
	my %options = @_;
	my $Period  = $options{Period};
	my $credits = 0;
	my $debits  = 0;
	foreach $Action ($Account->Actions) {
		next if $Period and not $Period->contains($Action->date);
		next unless $Action->Entry;
		$debits  += $Action->debit;
		$credits += $Action->credit;
	}
	my $type     = $Account->type;                                  #  ASSET   - LIABILITY : INCOME    - EXPENSE
	my $explicit = (($type eq 'LIABILITY') or ($type eq 'ASSET'  )) ? ($debits - $credits) : ($credits - $debits);
	my $implicit = (($type eq 'LIABILITY') or ($type eq 'EXPENSE')) ? -$explicit : $explicit;
	if ($options{rollup}) {
		foreach $Child ($Account->Children) {
			@totals = $Child->totals(%options);
			$debits   += $totals[0];
			$credits  += $totals[1];
			$implicit += $totals[0];
			$explicit += $totals[1];
		}
	}
	return ($implicit, $explicit)  if $options{signed};
	return ($debits, $credits)     if $options{totals};
	return ($debits - $credits, 0) if $debits > $credits;
	return (0, $credits - $debits);
}



1;

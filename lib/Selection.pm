#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Selection;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Name();
use Pattern();
#
# 
#
# A *Selection* uses Names and Patterns to identify Actions in one or more source Accounts and 
# optionally relate them to Actions in a sink Account.  Pairs of Actions thus form *transactions* 
# that capture the change in financial state. So Selections are used to recreate transactions 
# working backwards from Actions (rather than starting with an Entry that defines the a minimum of
# two Actions, which is normal, active accounting). 
#
# If no sink Name is provided, the source Patterns define a *Query*, since they select Actions
# but do not define where they "go".  Querries are used to refine the source and sink Names and 
# Patterns until they precisely identify the desired group of Actions.
#
# If a sink Name is provided but not a sink Pattern, the Selection defines an *Allocation*, 
# since the Actions selected are "allocated" to the identifed sink Account unconditionally
# (because the Action doesn't yet exist in the sink Account).  An Allocation is the most general 
# when it only provides only a source Pattern and omits a source Name, meaning the Pattern applys
# to all Actions in all Accounts (with one-sided Actions).  An example would be a Pattern that 
# would pick up actions in different bank accounts and credit card accounts and allocates them to
# an expense account.  A source Name could be added to scope a source Pattern, and multiple Name 
# scoped Patterns can be combined to identify source Actions accross specific Accounts, but a use
# case requiring this has yet to be hit so this is not supported.
#
# If a sink Name AND a sink Pattern is provided, the selection defines a *Transfer*, because the 
# Actions in the source Account have a specific corresponding Action in the sink Account (that
# already exists).  Often a Transfer is from one Account to another, but it can also be many 
# accounts to one - as is the case of credit card payments that come from different bank accounts.
#
# The moral:
#
# A *Query* has a SOURCE PATTERN and an optional SOURCE ACCOUNT.
#
# An *Allocation* has a SOURCE PATTERN, an optional SOURCE ACCOUNT and a SINK ACCOUNT.
#
# A *Transfer* has a SOURCE PATTERN, an optional SOURCE ACCOUNT, a SINK ACCOUNT and a SINK PATTERN. 
#
# Selections can further be refined by date specifying a Period and by Action amount by specifying
# a Limit.
#
# Selection = {source => {Name?, Pattern}, sink => {Name, Pattern?}? }
#
# Selection = {source => {Name?, Pattern}                         }  is a  Query
# Selection = {source => {Name?, Pattern}, sink => {Name}         }  is an Allocation
# Selection = {source => {Name?, Pattern}, sink => {Name, Pattern}}  is a  Transfer
#

#
# ENTITY File Format
# ------------------
#
# SINK_ACCOUNT
#
# @ SOURCE_ACCOUNT?
# | SOURCE_PATTERN
# ...
# --?
# | SINK_PATTERN
#
#
# ENTRY File Format
# -----------------
#
# @ SOURCE_ACCOUNT?
# | SOURCE_PATTERN
# ...
# --?
# @ SINK_ACCOUNT
# | SINK_PATTERN

sub new {
	my $invocant  = shift;
	my $class     = ref($invocant) || $invocant;
	my %options   = @_;
	my $Selection = {
		#
		Period => $options{Period},  # Period?
		Limit  => $options{Limit},   # Limit?
		source => {},                # {Name?, Pattern}
		sink   => {},                # {Name , Pattern?}?
		#
		_side  => 'source'           # for parsing
	};
	return bless $Selection;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub Period {
	return shift->{Period};
}

sub Limit {
	return shift->{Limit};
}

sub sink {
	return shift->{sink};
}

sub source {
	return shift->{source};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Properties
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Selection->is_allocation;
#
# Returns true if the Selection has a sink Name but not a sink Pattern.
#
sub is_allocation {
	my $Selection = shift;
	return ((defined $Selection->{sink}->{Name}) and not (defined $Selection->{sink}->{Pattern}));
}

# $Selection->is_empty;
#
# Returns true if the Selection has no source Pattern.
#
sub is_empty {
	my $Selection = shift;
	return (not defined $Selection->{source}->{Pattern});
}

# $Selection->is_query;
#
# Returns true if the Selection doesn't have a sink Name.
#
sub is_query {
	my $Selection = shift;
	return (not defined $Selection->{sink}->{Name});
}

# $Selection->is_transfer;
#
# Returns true if the Selection has a sink Name and a sink Pattern.
#
sub is_transfer {
	my $Selection = shift;
	return ((defined $Selection->{sink}->{Name}) and (defined $Selection->{sink}->{Pattern}));
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Selection->display(%options) => string
#
# Returns a display string.
#
sub display {
	my $Selection = shift;

	sub _display {
		my $filter = shift;
		my $string = "";
		$string .= $filter->{Name}->display(pad => 1)."\n" if $filter->{Name};
		$string .= $filter->{Pattern}->string              if $filter->{Pattern};
		return $string;
	}

	my $source = _display($Selection->{source});
	my $sink   = _display($Selection->{sink});

	return sprintf("%s--\n%s", $source, $sink) if $sink;
	return $source;
}

# $Selection->parse(string);
#
# Assembles a selection from a series of storage strings.
#
sub parse {
	my $Selection = shift;
	my $string    = shift;
	my $side      = $Selection->{_side};
	my @lines     = split /\n/, $string;
	foreach my $line (split /\n/, $string) {
		if ($line =~ s/^\s*@\s*//) {
			$line =~ s/\s+$//;
			$Selection->{$side}->{Name} = new Name($line);
		} elsif ($line =~ m/^\s*--/) {
			$Selection->{_side} = $side = 'sink';
		} elsif ($line =~ m/^\s*[&+|^!~-]/) {
			$Selection->{$side}->{Pattern} = new Pattern unless $Selection->{$side}->{Pattern};
			$Selection->{$side}->{Pattern}->parse($line);
		}
	}
}

# $Selection->put => string
#
# Returns a storage string.
#
sub put {
	return shift->display;
}



1;

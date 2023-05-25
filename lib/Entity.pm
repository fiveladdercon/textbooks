#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Entity;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use strict;
use Account();
use Console();
use Draw();
use Entry();
use Limit();
use Name();
use Period();
use Selection();
use Source();

sub new {
	my $invocant  = shift;
	my $class     = ref($invocant) || $invocant;
	my $file      = shift;
    my $Entity    = {
    	file      => $file,
    	entry     => 0,
    	Accounts  => [],
    };
	return bless $Entity, $class;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Persistence
#───────────────────────────────────────────────────────────────────────────────────────────────────
# R Construct an Entity from a file                        get
# R Save an Entity to file                                 put

sub get {
	#
	# get Entity $file
	# get()                  {file}
	# get(file   => $file)   $file
	# get(string => $string) $string
	#
	my $Entity  = shift; $Entity = new Entity(shift) unless ref $Entity;
	my %options = @_;    
	my $file    = $options{file} || $Entity->{file};
	my @Lines   = ();

	# Input redirection
	if ($options{string}) {
		my $number = 0;
		foreach (split /\n/, $options{string}) {
			push @Lines, new Line('mem', ++$number);
		}
	} elsif (defined $file) {
		@Lines = Source::line($file)
	}
	return $Entity unless @Lines;

	# Build an index by number for cross referencing Parents & Children
	my $Accounts   = {};
	my $Account    = undef;
	my $Selection  = undef;
	foreach my $Line (@Lines) {
		my $selection = 0;
		if ($Line =~ /^\s*ASSET|LIABILITY|INCOME|EXPENSE/) {
			# printf("ACCOUNT: %s\n", $Line);
			$Account = get Account $Line;
			push @{$Entity->{Accounts}}, $Account;
			$Accounts->{$Account->number} = $Account;
		} elsif ($Line =~ /^\s*[*]/) {
			# printf("IMPORT : %s\n", $Line);
			my (undef, $rule) = split /\s+/, $Line;
			Console::error("IMPORT rule defined before an Account") unless defined $Account;
			$Account->{import} = $rule;
		} elsif ($Line =~ m/^\s*[@&+|^!~-]/) {
			# printf("SELECTION : %s%s\n", $Line, $Selection ? "": " *");
			Console::error("SELECTION defined before an Account") unless defined $Account;
			if (not $Selection) {
				$Selection = new Selection;
				push @{$Account->{Selections}}, $Selection;
			}
			$Selection->parse($Line);
			$selection = 1;
		} elsif ($Line =~ /,/) {
			# printf("ACTION : %s\n", $Line);
			Console::error("ACTION defined before an Account") unless defined $Account;
			my $Action = get Action $Line;
			push @{$Account->{Actions}}, $Action;
			my $entry = $Action->entry;
			$Entity->{entry} = int($entry) if defined $entry and $entry > $Entity->{entry};
		}
		$Selection = undef if $Selection and not $selection;
	}

	# Cross reference Account Parents & Children
	foreach my $Account ($Entity->getAccounts()) {
		next unless $Account->{Parent};
		$Account->{Parent} = $Accounts->{$Account->{Parent}};
		push @{$Account->{Parent}->{Children}}, $Account;
	}

	# Reconstruct Entries?

	return $Entity;
}

sub put {
	#
	# put()                 STDOUT    -
	# put(commit => 1)      {file}    -
	# put(file => $file)    $file     -
	# put(string => 1)      -         $string
	# 
	my  $Entity  = shift;
	our %options = @_;  
	our $output  = "";
	my  $file    = $options{file};  $file = $Entity->{file} if $options{commit} and not defined $file;
	# Redirect output
	sub output { 
		my $fmt  = shift; 
		my $line = sprintf($fmt, @_);
		if ($options{string}) { $output .= $line; } else { print $line; } 
	}
	# Output the Entity
	Source::open($file) if defined $file and not $options{string};
	foreach my $Account ($Entity->getAccounts()) {
		&output($Account->put);
		&output($Account->line);
		if ($Account->import) {
			&output("* %s\n", $Account->import);
			&output($Account->line);
		}
		if (scalar $Account->Selections) {
			&output(join("\n", map { $_->put } $Account->Selections));
			&output($Account->line);
		}
		if (scalar $Account->Actions) {
			if ($options{open}) {
				if ($Account->balanced and not $Account->import) {
					my $Last    = $Account->{Actions}->[-1];
					my $date    = $options{Period} ? $options{Period}->{start} : $Last->date;
					my $Balance = new Action (date => $date, item => "BALANCE IN", balance => $Last->balance);
					&output($Balance->put);
					&output($Account->line);
				}
			} else {
				foreach my $Action ($Account->Actions) {
					&output($Action->put);
				}
				&output($Account->line);
			}
		}
		&output("\n\n");
	}
	Source::close($file) if defined $file and not $options{string};
	# Return a string if requested
	return $output if $options{string};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Chart of Accounts
#───────────────────────────────────────────────────────────────────────────────────────────────────
# R Add a new Account                                      createAccount
# R Show the chart of Accounts                             readAccounts
# R Filter the chart of Accounts                           readAccounts
# ? Renumber an Account
# ? Move an Account
# ? Rename an Account
# ? Delete an Account

# Return an Account identified by Name or number.
sub getAccount {
	my $Entity     = shift;
	my $identifier = shift;
	if (ref $identifier eq "Name") {
		my $Name     = $identifier;
		my @Accounts = $Entity->getAccounts($Name);
		if (@Accounts == 0) {
			Console::error("No accounts identified by '%s'", $Name->display);
			return;
		} elsif (@Accounts > 1) {
			Console::error("More than one account identified by '%s':\e[0m\n%s", $Name->display, $Entity->readAccounts(Name => $Name));
			return;
		}
		return $Accounts[0];
	} else {
		foreach my $Account ($Entity->getAccounts()) {
			return ($Account) if $Account->number eq $identifier;
		}
		return $Entity->getAccount(new Name($identifier));
	}
}

# Return the list of Accounts optionaly by Name.
sub getAccounts {
	my $Entity   = shift;
	my $Name     = shift;
	my @Accounts = ();
	foreach my $Account (@{$Entity->{Accounts}}) {
		$Account->{Name} = undef;
		next if $Name and not $Name->matches($Account->identifier);
		$Account->{Name} = $Name;
		push @Accounts, $Account;
	}
	return @Accounts;
}

# Add a new Account
sub createAccount {
	my $Entity  = shift;
	my $type    = shift;
	my $number  = shift;
	my $parent  = shift;
	my $name    = shift;
	my $Line    = shift;
	my $Account = new Account($type, $number, $parent, $name, $Line);
	if (not defined $Line and defined $parent) {
		# Find the Parent account if not already an Account
		my $Parent = (ref $parent eq "Account") ? $parent : $Entity->getAccount($parent);
		# Update the Account Parent to an Account
		$Account->{Parent} = $Parent;
		# Add the Account as a Child of the Parent
		push @{$Parent->{Children}}, $Account;
		# Reorder the accounts by family
		my @Accounts = ();
		foreach my $Account ($Entity->getAccounts()) {
			push @Accounts, $Account->family unless $Account->Parent;
		}
		$Entity->{Accounts} = [@Accounts];
	} else {
		# Otherwise the Account is parentless or the order has been defined by the Line number
		push @{$Entity->{Accounts}}, $Account;
	}
	return $Account;
}

# Return an optionally filtered or highlighted chart of accounts as a string
sub readAccounts {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $number  = $options{number};
	my $chart   = "";
	if ($Name) {
		foreach my $Account ($Entity->getAccounts()) {
			my $id      = $Account->identifier;
			my $match   = $Name->matches($id);
			next unless $match;
			my $account = $Account->put;
			substr($account, index($account, $id), length($id), $match); # avoid issues with regex characters in the id
			$chart .= $account;
		}
	} elsif ($number) {
		foreach my $Account ($Entity->getAccounts()) {
			my $account = $Account->put;
			$chart .= ($Account->number eq $number) ? Console::green($account) : $account;
		}
	} else {
		foreach my $Account ($Entity->getAccounts()) {
			$chart .= $Account->put;
		}
	}
	return $chart;
}

my $CHART = <<'_';
Usage: gl [OPTIONS] chart [-h | --help]
                          [-c | --commit] 
                          [-e | --explicit]                          
                          [-f | --file CHART]
                          [-i | --implicit]
                          [-r | --renumber ACCOUNT NUMBER]
                          [PATTERN ...]

Displays the chart of account in implicit or explict format.

The implicit format uses indentation to signal hierarchy, while the
explicit format specifies all parent accounts.

If PATTERNs are specified, the explicit accounts that match the
PATTERNs will be displayed.

Unless a CHART file is specified with --file, the chart file for the
ENTITY will be used (ENTITY.ch).

An account can be renumbered using the --renumber option, and the
change will only be commited to the CHART file when the --commit
option is specified.
_

sub chart {
	my $Entity = shift;
	my @args   = @_;
	my $type;
	my $number;
	my $parent;
	my @name;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-a") or ($op eq "--asset")    ) { $type = 'ASSET';       }
		elsif (($op eq "-l") or ($op eq "--liability")) { $type = 'LIABILITY';   }
		elsif (($op eq "-i") or ($op eq "--income")   ) { $type = 'INCOME';      }
		elsif (($op eq "-e") or ($op eq "--expense")  ) { $type = 'EXPENSE';     }
		elsif (($op eq "-p") or ($op eq "--parent")   ) { $parent = shift @args; }
		elsif (defined $type and not defined $number  ) { $number = $op;         }
		else                                            { push @name, $op;       }
	}

	my $name = join(" ", @name);

	if (defined $type) {
		return Console::error("Account number is missing.") unless defined $number;
		return Console::error("Account name is missing."  ) unless @name;
		foreach my $Account ($Entity->getAccounts()) {
			return Console::error("Account number $number is %s.", $Account->identifier) if $Account->number eq $number;
		}
		return if defined $parent and not defined $Entity->getAccount($parent);
		my $Account = $Entity->createAccount($type, $number, $parent, $name);
		Console::stdout($Entity->readAccounts(number => $number));
	} else {
		Console::stdout($Entity->readAccounts(Name => new Name($name)));
	}

	return 1;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Bank Record Import
#───────────────────────────────────────────────────────────────────────────────────────────────────
# R Add a new Account                                      createAccount
# R Add an import rule to an Account                       createImportRule
# R Show the import rules                                  readImportRules
# R Show the import files                                  readImportRules
# R Select import rules by Pattern                         readImportRules
# R Select import files by Pattern                         readImportRules
# R Import bank statements by Period                       createRecords
# R Show records                                           readRecords
# R Reconcile bank statement balances                      reconcileRecords
# R Deport bank statements by Period                       deleteRecords

sub createImportRule {
	my $Entity  = shift;
	my $name    = shift;
	my $import  = shift;
	my $Account = $Entity->getAccount($name);
	$Account->{import} = $import;
}

#
# Returns import rules, filenames or files, optionally filtered by Name and/or Pattern
#
# readImportRules([Name => $Name,] [Pattern => $Pattern ])            -> matched @files
# readImportRules([Name => $Name,] [Pattern => $Pattern,] files => 1) -> matched $files
# readImportRules([Name => $Name,] [Pattern => $Pattern,] rules => 1) -> matched $rules
#
# Name matches Account identifier
# Pattern matches import rule or import file
#
sub readImportRules {
	my $Entity   = shift;
	my %options  = @_;
	my $Name     = $options{Name};
	my $Pattern  = $options{Pattern};
	my @Accounts = $Entity->getAccounts();
	if ($options{rules}) {
		my $rules = "";
		foreach my $Account (@Accounts) {
			next unless $Account->{import};
			my $account = $Account->identifier; $account = $Name->matches($account) if defined $Name; next unless $account;
			my $rule = $Account->{import}; $rule = $Pattern->matches($rule) if defined $Pattern; next unless $rule;
			$rules .= sprintf("%-50s * %s\n", $account, $rule);
		}
		return $rules;
	} elsif ($options{files}) {
		my $files = "";
		foreach my $Account (@Accounts) {
			next unless $Account->{import};
			my $account = $Account->identifier; $account = $Name->matches($account) if defined $Name; next unless $account;
			foreach my $file (Source::glob($Account->{import})) {
				$file = $Pattern->matches($file) if defined $Pattern; next unless $file;
				$files .= sprintf("%-50s * %s\n", $account, $file);
			}
		}
		return $files;
	} else {
		my @files = ();
		foreach my $Account (@Accounts) {
			next unless $Account->{import};
			my $account = $Account->identifier; $account = $Name->matches($account) if defined $Name; next unless $account;
			foreach my $file (Source::glob($Account->{import})) {
				$file = $Pattern->matches($file) if defined $Pattern; next unless $file;
				push @files, $file;
			}
		}
		return @files;
	}
}

sub createRecords {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Pattern = $options{Pattern};
	my $Period  = $options{Period};

	Console::note("Importing...") if $Console::VERBOSITY < $Console::PROFUSE;

	my $total_imports = 0;
	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->{import};

	   	# Import each source
		my $account_imports = 0;
	   	foreach my $source (Source::glob($Account->{import})) {
	   		
	   		# Filter by Pattern
	   		if ($Pattern) {
	   			my $include = $Pattern->includes($source);
	   			my $exclude = $Pattern->excludes($source);

				if    (    $exclude) { Console::info($Console::PROFUSE, "Skipping  $exclude"); next; }
				elsif (not $include) { Console::info($Console::PROFUSE, "Skipping  $source" ); next; }
	   		}

			# Load the actions to import
		   	my $source_actions = 0;
		   	my $source_imports = 0;
			my @inbound = ();
			foreach my $Line (Source::line($source)) {
				next unless $Line =~ /,/;
				my $Action = import Action $Line;
				$source_actions++;
				# Fitler by Period
		   		next if defined $Period and not $Period->contains($Action->date);
		   		push @inbound, $Action;
			}
			next unless @inbound;

			# Merge the inbound actions with the existing actions
		   	my @existing = $Account->Actions;
			my @merged   = ();
			# Insert the existing actions that are before the first inbound action
			while ((scalar @existing) and ($inbound[0]->date gt $existing[0]->date)) {
				push @merged, shift @existing;
			}
			# Compare action by action since the inbound and existing actions are now lined 
			# up by date.
			foreach my $Action (@inbound) {
				if (scalar @existing) {
					#print($Action->put);
					#print($existing[0]->put);
					#print("\n");
					if ($existing[0]->date gt $Action->date) {
						# Insert inbound action that are before the existing action.
						push @merged, $Action;
						$source_imports++;
						$total_imports++;
					} elsif ($Action->date eq $existing[0]->date) {
						# Otherwise the inbound and existing actions have the
						# same date, so either they are entirely the same or not.
						if ($Action->eq($existing[0])) {
							# If the action is the same, it has already been imported
							# so either copy is fine.
							push @merged, shift @existing;
						} else {
							# If the action is different, it is probably due to:
							# 1) Hand editing of the item
							# 2) Different download formats
							# In either case, one needs to be picked.
				   			Console::warn('The record on %s at %s has an item collision', $Action->date, $Action->Line->coord);
			   				Console::stderr("Existing : %s\n", $existing[0]->put);
				   			Console::stderr("Current  : %s\n", $Action->put);
				   			Console::stderr("[%s]eep existing / [%s]pdate to current?\n", Console::green('k'), Console::green('u'));
				   			my $selection = "x";
				   			while ($selection !~ /^[ku]$/) {
				   				Console::stderr(">>>");
					   			$selection = lc Console::stdin; chomp $selection;
				   			}
				   			if ($selection eq "k") {
				   				Console::note(Console::green("Keeping %s", $existing[0]->item));
				   				push @merged, shift @existing;

				   			} elsif ($selection eq "u") {
				   				Console::note(Console::green("Updating to %s", $Action->item));
				   				push @merged, $Action; shift @existing;
					   		}
						}
					} else {
						# The inbound action is after the existing action, which shouldn't happen
						# without some serious pathalogical hacking.
						Console::error("Out of order data.");
						return;
					}
				} else {
					# Insert inbound actions after the end of existing data.
					push @merged, $Action;
					$source_imports++;
					$total_imports++;
				}
			}
			# Merge the existing actions that are after the last inbound action
			push @merged, @existing;

			# Update the Account
			$Account->{Actions} = [@merged];

		   	# A partial import is suspicious, so warn
		   	my $source_skips = $source_actions - $source_imports;
		   	my $message = sprintf("%%-9s %%s of %3d records into ACCOUNT %s from %s.", $source_actions, $Account->number, $source);
		   	if    ($source_imports == 0) { Console::info($Console::PROFUSE, $message, "Skipping" , sprintf("%3d", $source_skips));	        } 
		   	elsif ($source_skips   == 0) { Console::info($Console::VERBOSE, $message, "Importing", Console::green("%3d", $source_imports)); }
		   	else                         { Console::warn($message, "Importing", sprintf("%3d", $source_imports));                           }

		}
	}
	Console::note("Imported %s new transactions", $total_imports ? Console::green("%d",$total_imports) : "no");
}

sub createRecordsOrig {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Pattern = $options{Pattern};
	my $Period  = $options{Period};

	Console::note("Importing...") if $Console::VERBOSITY < $Console::PROFUSE;

	my $total_imports = 0;
	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->{import};

	   	# Build an index of existing transactions and retain the order
	   	my $existing = 0;
	   	my $index    = {};
	   	foreach my $Action ($Account->Actions) {
	   		$Action->{existing} = $existing++;
	   		$index->{$Action->identifier}->{$Action->item} = $Action;
	   	}

	   	# Import each source
		my $account_imports = 0;
	   	foreach my $source (Source::glob($Account->{import})) {
	   		
	   		# Filter by Pattern
	   		if ($Pattern) {
	   			my $include = $Pattern->includes($source);
	   			my $exclude = $Pattern->excludes($source);

				if    (    $exclude) { Console::info($Console::PROFUSE, "Skipping  $exclude"); next; }
				elsif (not $include) { Console::info($Console::PROFUSE, "Skipping  $source" ); next; }
	   		}

			# Load the statement
		   	my $source_actions = 0;
		   	my $source_imports = 0;
		   	foreach my $Line (Source::line($source)) {
		   		next unless $Line =~ /,/;
		   		$source_actions++;
		   		my $Action = import Action $Line;
		   		# Filter by date
		   		next if defined $Period and not $Period->contains($Action->date);

		   		my $identifier = $Action->identifier;
		   		my $item       = $Action->item;
				if (exists $index->{$identifier}) {

		   			# Filter the action if the item is in the index
					next if exists $index->{$identifier}->{$item};

	   				my @existing = sort keys %{$index->{$identifier}};
	   				my $existing = shift @existing;
	   				
	   				Console::error("Can't handle multiple existing items\n") if @existing;

                    # If the item is different there are a number of scenarios
                    # 1) I manually edited a source, so pick one
                    # 2) I have two copies of the source but the download format is different, so pick one
                    # 3) Two different transactions have the same identifier, so import anyways.
		   			Console::warn('The record on %s at %s has an item collision', $Action->date, $Action->Line->coord);
	   				Console::stderr("Existing : $existing\n");
		   			Console::stderr("Current  : $item\n");
		   			Console::stderr("[%s]eep existing / [%s]pdate to current / [%s]mport ?\n", Console::green('k'), Console::green('u'), Console::green('i'));
		   			my $selection = "x";
		   			while ($selection !~ /^[kui]$/) {
		   				Console::stderr(">>>");
			   			$selection = lc Console::stdin; chomp $selection;
		   			}
		   			if ($selection eq "k") {
		   				Console::note(Console::green("Keeping %s", $existing));
		   				next;
		   			} elsif ($selection eq "u") {
		   				Console::note(Console::green("Updating to %s", $item));
		   				$index->{$identifier}->{$existing}->{item} = $item;
		   				# Count the update as an import, but don't actually add the action
				   		$source_imports++;
				   		$account_imports++;
				   		$total_imports++;
		   				next;
			   		} else {
		   				Console::note(Console::green("Importing %s", $Action->item));
			   		}
		   		}

		   		$source_imports++;
		   		$account_imports++;
		   		$total_imports++;
		   		$Action->{imported} = $account_imports;
		   		$index->{$identifier}->{$item} = $Action;
		   		push @{$Account->{Actions}}, $Action;
		   	}
		   	my $source_skips = $source_actions - $source_imports;

		   	# A partial import is suspicious, so warn
		   	my $message = sprintf("%%-9s %%s of %3d records into ACCOUNT %s from %s.", $source_actions, $Account->number, $source);
		   	if    ($source_imports == 0) { Console::info($Console::PROFUSE, $message, "Skipping" , sprintf("%3d", $source_skips));	        } 
		   	elsif ($source_skips   == 0) { Console::info($Console::VERBOSE, $message, "Importing", Console::green("%3d", $source_imports)); }
		   	else                         { Console::warn($message, "Importing", sprintf("%3d", $source_imports));                           }
		}

	    # Resort the actions since imports are not necessarily in date order.
	    my $sort_warning = 0;
	    $Account->{Actions} = [sort {
	    	# Retain the order of the imported actions and the order of the existing actions,
	    	# but blend the two groups of ordered actions together by date.
	    	my $date = ($a->{date} cmp $b->{date}); return $date if $date;
			return ($a->{imported} <=> $b->{imported}) if exists $a->{imported} and exists $b->{imported};
			return ($a->{existing} <=> $b->{existing}) if exists $a->{existing} and exists $b->{existing};
			$sort_warning = 1;	return $date;
	    } @{$Account->{Actions}}] if $account_imports;
		Console::warn("Records imported on a date with existing records may be incorrectly ordered.") if $sort_warning;

	}
	Console::note("Imported %s new transactions", $total_imports ? Console::green("%d",$total_imports) : "no");
}

sub readRecords {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Pattern = $options{Pattern};
	my $Period  = $options{Period};
	my $Limit   = $options{Limit};

	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->import;
		my $debits  = 0;
		my $credits = 0;
		foreach my $Action ($Account->Actions) {
			next if $Action->Entry;
			my $date = $Action->date;
			my $item = $Action->item;
			next if defined $Period  and not $Period->contains($date);
			next if defined $Pattern and not $Pattern->matches($item);
			my $debit  = $Action->debit;
			my $credit = $Action->credit;
			next if defined $Limit and not $Limit->matches($debit + $credit);
			my $line   = sprintf($CHANGE::ACTION, $date, $item, Amount::column($debit), Amount::column($credit));
			Console::stdout($CHANGE::HEADER, $Account->identifier) unless $debits or $credits;
			Console::stdout("%s", defined $Pattern ? $Pattern->matches($line) : $line);
			$debits  += $debit;
			$credits += $credit;
		}
		if ($debits or $credits) {
			my $net_debit  = Amount::column(($debits > $credits) ? $debits - $credits : 0);
			my $net_credit = Amount::column(($debits < $credits) ? $credits - $debits : 0);
			my $debit  = Amount::column((not $options{totals}) ? $debits  : (($debits > $credits) ? $debits - $credits : 0));
			my $credit = Amount::column((not $options{totals}) ? $credits : (($debits < $credits) ? $credits - $debits : 0));
			Console::stdout($CHANGE::NET, $debit, $credit, $net_debit, $net_credit);
		}

	}
}

sub deleteRecords {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Period  = $options{Period};

	my $deported = 0;
	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->{import};
		my @Actions = ();
		foreach my $Action ($Account->Actions) {
			if (not defined $Action->Entry and (not defined $Period or $Period->contains($Action->date))) {
				print($Action->put) if $Console::VERBOSITY >= $Console::PROFUSE;
				$deported++;
			} else {
				push @Actions, $Action;
			}
		}
		$Account->{Actions} = [@Actions];
	}
	Console::note('Deported %s records.', $deported ? Console::green($deported) : 'no');
}

sub reconcileRecords {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Period  = $options{Period};

	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->balanced;

		my @Actions = $Account->Actions; 
		next unless @Actions;

		my $sign    = ($Account->type eq 'ASSET') ? 1 : -1;
		my $debit   = $sign < 0 ? '-' : '+';
		my $credit  = $sign > 0 ? '-' : '+';
		my $actions = 0;
		my $issues  = 0;
		my $issue;
		my $current;
		my $next;
		my $balance;
		my $recorded;
		my $computed;
		Console::stdout($Account->line) if $Console::VERBOSITY >= $Console::PROFUSE;
		foreach my $Action (@Actions) {
			# next if defined $Action->Entry;
			next unless not defined $Period or $Period->contains($Action->date);
			$actions++;
			if (not defined $current) {
				$current = $Action->balance;
			} else {
				$issue    = 0;
				$next     = $current + $sign * $Action->net;
				$balance  = $Action->balance;
				$recorded = sprintf('%.2f', $balance); # $recorded = '0.00' if $recorded eq '-0.00';
				$computed = sprintf('%.2f', $next);    $computed = '0.00' if $computed eq '-0.00';
				if ($computed ne $recorded) {
					$issue = 1;
					$issues++;
				}
				if ($Console::VERBOSITY >= $Console::PROFUSE) {
					my $line = sprintf('%-5s %s %10.2f %s %10.2f %s %10.2f = %10.2f ',
										$Account->number, $Action->date, 
										$current, $debit, $Action->debit, $credit, $Action->credit, $balance); 
					Console::stdout("%s %s\n", $line, $issue ? Console::yellow('!= %10.2f', $next) : Console::green('== %10.2f', $next));
				} elsif ($issue) {
					Console::warn('%s balance on %s is calculated as %.2f but recorded as %.2f.', $Account->number, $Action->date, $next, $balance);
				}
				$current = $balance;
			}
		}
		Console::stdout("%s\n\n", $Account->line) if  $Console::VERBOSITY >= $Console::PROFUSE;
		Console::note('Reconciled %s records from account %s and found %s issues.', $issues ? $actions : Console::green($actions), Console::green($Account->identifier), $issues ? Console::yellow($issues) : 'no');
	}
}

my $IMPORT = <<'_';
Usage: gl [OPTIONS] import [-h | --help]
                           [-c | --commit] 
                           [-d | --destination ACCOUNT STATEMENT ...]
                           [-f | --file RULES]
                           [-p | --period PERIOD]
                           [PATTERN ...]

Imports transactions from .csv bank statements into the asset or liability
accounts in the general ledger.  

At the lowest level, the source STATEMENTs and destination ACCOUNT can
be specified explicitly as a series of --destination options.

These rules can be captured in a import RULES file and passed in with
the --file option.  If the rules are saved as the ENTITY import rules
file (ENTITY.ir), the --file option can be omitted.  

The format for the RULES file is:

IMPORT <ACCOUNT> FROM <STATEMENT>

The <STATEMENT> can be a glob to succinctly specify many files at once,
and contain environment variable references:

IMPORT 10000 FROM $STATEMENTS/Checking/*.csv
IMPORT 20000 FROM $STATEMENTS/Savings/*.csv

Specifying the import rules this way will mean that new statements
that get added will get imported without changing the rules.

Regardless of how the statements get collected, which statements get
imported can be filtered by either specifying one or more filter PATTERNs 
and/or a statement PERIOD.

PATTERNS are regular expressions.  If they start with ! or ~ then the PATTERN
excludes things.


PERIOD
------

A period is a span of time between a start date and an end date:

YYYY[-MM[-DD]][:YYYY[-MM[-DD]]]

If an end date is not specified, the start date is used.

If a date does not specify the day, 1 is used if the date is a start date
or 31 is used if the date is the end date.

YYYY-MM:yyyy-mm == YYYY-MM-01:yyyy-mm-31

If a date does not specify the month, 1 is used if the date is a start date
and 12 is used if the date is the end date

YYYY:yyyy == YYYY-01-01:yyyy-12-31

This allows for succinctly specifying a particular month:

YYYY-MM == YYYY-MM-01:YYYY-12-31

Or a particular year:

YYYY == YYYY-01-01:YYYY-12-31
_

sub import {
	my $Entity  = shift;
	my @args    = @_;
	my $rules   = 0;
	my $files   = 0;
	my $Pattern = new Pattern();
	my $Period;
	my $Name;
	my $source;
	my $orig = 0;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-r") or ($op eq "--rules")  ) { $rules  = 1;                      }
		elsif (($op eq "-f") or ($op eq "--files")  ) { $files  = 1;                      }
		elsif (($op eq "-s") or ($op eq "--source") ) { $source = shift @args;            }
		elsif (($op eq "-p") or ($op eq "--period") ) { $Period = new Period shift @args; }
		elsif (($op eq "-a") or ($op eq "--account")) { $Name   = new Name   shift @args; }
		elsif (($op =~ m/^@/)                       ) { $Name   =  new Name($op);         }
		elsif (($op eq "--orig")) { $orig = 1; }
		else                                          { $Pattern->term($op);              }
	}

	if ($Name and $source) {
		$Entity->createImportRule($Name, $source);
		$rules = 1;
	}

	return Console::stdout($Entity->readImportRules(
		rules   => $rules, 
		files   => $files, 
		Name    => $Name, 
		Pattern => $Pattern,
	)) if $rules or $files;

	$Entity->createRecords(Name => $Name, Pattern => $Pattern, Period => $Period) unless $orig;
	$Entity->createRecordsOrig(Name => $Name, Pattern => $Pattern, Period => $Period) if $orig;

	return 1;
}

my $DEPORT = <<'_';
Usage: gl [OPTIONS] deport [-h | --help] 
                           [-c | --commit]
                           [-p | --period PERIOD]
                           [PATTERN ...]
_

sub deport {
	my $Entity = shift;
	my @args   = @_;
	my $Period;
	my $Name;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-p") or ($op eq "--period") ) { $Period = new Period shift @args; }
		elsif (($op eq "-a") or ($op eq "--account")) { $Name   = new Name   shift @args; }
	}

	$Entity->deleteRecords(Name => $Name, Period => $Period);
}

my $RECONCILE = <<'_';
Usage: gl [OPTIONS] reconcile [-h | --help]
                              [-p | --period PERIOD]
                              [PATTERN ...]
_

sub reconcile {
	my $Entity = shift;
	my @args   = @_;
	my $Period;
	my $Name;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-p") or ($op eq "--period") ) { $Period = new Period shift @args; }
		elsif (($op eq "-a") or ($op eq "--account")) { $Name   = new Name   shift @args; }
	}

	$Entity->reconcileRecords(Name => $Name, Period => $Period);
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Bank Record Selection
#───────────────────────────────────────────────────────────────────────────────────────────────────
#
# Booking Keeping Process:
#
# 1] Import bank records.
# 2] Review & commit allocations according to existing rules.
#    ? May need to tweak rules
# 3] Manually allocate remaining actions.
#
# Manual Allocation Process:
#
# 1] See the list of unallocated actions.
# 2] Add an item pattern and see the list of selected unallocated actions. Repeat until happy.
# 3] Add an account name and see the entries that will be made. Repeat until happy.
# 4] Commit the entries and optionally the allocation pattern.
# 5] Repeat until no unallocated actions.
#
# Creating a rule
#
# no args : view unallocated actions
# pattern : view unallocated actions by pattern
# account : view allocated entries
# 
# Selecting, applying, updating existing rules
# no args : apply all existing rules
# account : 
#

# Form a Selection = {source => {Name?, Pattern}, sink => {Name, Pattern?}?, Period?, Limit?}
#                    e.g. a Pair of (Name, Pattern) Filters
# Get actions = {source => [{Account, Actions => []}], source => [{Account, Actions => []}]}}
#

sub selectActions {
	my $Entity    = shift;
	my $Selection = shift;
	my %options   = @_;
	my $accounts  = {source => [], sink => []};
	my $actions   = {source => 0 , sink => 0 };

	# Query      : {source => {             }, sink => {             }} -> {source => [{Account, Actions}], sink => [                  ]}
	# Query      : {source => {Name         }, sink => {             }} -> {source => [{Account, Actions}], sink => [                  ]}
	# Query      : {source => {Name, Pattern}, sink => {             }} -> {source => [{Account, Actions}], sink => [                  ]}
	# Query      : {source => {      Pattern}, sink => {             }} -> {source => [{Account, Actions}], sink => [                  ]}
	# Allocation : {source => {      Pattern}, sink => {Name         }} -> {source => [{Account, Actions}], sink => [{Account, []     }]}
	# Allocation : {source => {Name, Pattern}, sink => {Name         }} -> {source => [{Account, Actions}], sink => [{Account, []     }]}
	# Transfer   : {source => {Name, Pattern}, sink => {Name, Pattern}} -> {source => [{Account, Actions}], sink => [{Account, Actions}]}
	foreach my $Account ($Entity->getAccounts()) {
		foreach my $side ('source', 'sink') {
			my $filter = $Selection->{$side}; 
			next if $filter->{Name} and not $filter->{Name}->matches($Account->identifier);
			$Account->{Name} = $filter->{Name};
			my $Actions = [];
			if ($Account->import and (($side eq 'source') or ($filter->{Pattern}))) {
				#Console::error('%s sink identifies the %s source.', $filter->{Name}->display, $Account->{Name}->display) if $Account->{Name} and $filter->{Name};
				foreach my $Action ($Account->Actions) {
					next if defined $Action->Entry;  # Need entry selection
					next if defined $Selection->Period and not $Selection->Period->contains($Action->date);
					next if defined $Selection->Limit  and not $Selection->Limit->matches($Action->amount);
					next if defined $filter->{Pattern} and not $filter->{Pattern}->matches($Action->item);
					$Action->{Pattern} = $filter->{Pattern};
					next unless $Action->amount;
					push @{$Actions}, $Action;
					$actions->{$side}++;
				}
			}
			push @{$accounts->{$side}}, {Account => $Account, Actions => $Actions} if @{$Actions} or $filter->{Name};
		}
	}

	# Reporting & error checking

	my $source_accounts = scalar @{$accounts->{source}};
	my $source_actions  = $actions->{source};
	my $sink_accounts   = scalar @{$accounts->{sink}};
	my $sink_actions    = $actions->{sink};

	sub p { my $n = shift; return $n == 1 ? ($n, "") : ($n, "s"); }

	Console::info($Console::VERBOSE, '%d action%s in %d source account%s, %d action%s in %d sink account%s selected.', p($source_actions), p($source_accounts), p($sink_actions), p($sink_accounts)) if $options{display};
	if ($Selection->is_query) {
		Console::error('%d sink account%s selected in query, not 0.', p($sink_accounts)) unless $sink_accounts == 0;
	} elsif ($Selection->is_allocation) {
		if ($sink_accounts != 1) {
			Console::stdout($Selection->display);
			Console::error('%d sink account%s selected in allocation, not 1.', p($sink_accounts));
		}
	} elsif ($Selection->is_transfer) {
		if ($sink_accounts != 1) {
			Console::stdout($Selection->display);
			Console::error('%d sink account%s selected in transfer, not 1.', p($sink_accounts));
		}
		if ($sink_actions != $source_actions) {
			Console::stdout($Selection->display);
			Console::error('%d sink action%s != %d source action%s in transfer', p($sink_actions), p($source_actions));
		}
	}

	return $accounts;  # {source => [{Account, Actions}], sink => [{Account, Actions}]}
}

sub showSelectedActions {
	my $Entity    = shift;
	my $Selection = shift;
	my $accounts  = $Entity->selectActions($Selection);

	foreach my $side ('source', 'sink') {
		foreach my $account (@{$accounts->{$side}}) {
			my $Account = $account->{Account};
			my @Actions = @{$account->{Actions}}; next unless @Actions;
			my $debits  = 0;
			my $credits = 0;
			Console::stdout($Account->display(ledger => 1));
			foreach my $Action (@Actions) {
				Console::stdout($Action->display(ledger => 1));
				$debits  += $Action->debit;
				$credits += $Action->credit;
			}
			my $debit      = Amount::column($debits);
			my $credit     = Amount::column($credits);
			my $net_debit  = Amount::column(($debits > $credits) ? $debits - $credits : 0);
			my $net_credit = Amount::column(($debits < $credits) ? $credits - $debits : 0);
			Console::stdout($CHANGE::NET, $debit, $credit, $net_debit, $net_credit);
		}
	}
}

sub createAllocationEntries {
	my $Entity    = shift;
	my $Selection = shift;
	my %options   = @_;
	my $accounts  = $Entity->selectActions($Selection, %options);
	my $entries   = 0;

	my $sink = $accounts->{sink}->[0];
	foreach my $source (@{$accounts->{source}}) {
		foreach my $Source (@{$source->{Actions}}) {
			my $date   = $Source->date;
			my $item   = $Source->item;
			my $amount = $Source->amount;
			my $Entry  = new Entry;
			if ($Source->debit) {
				$Entry->action($source->{Account}, $Source);
				$Entry->credit($sink->{Account}, $date, $item, $amount);
			} else {
				$Entry->debit($sink->{Account}, $date, $item, $amount);
				$Entry->action($source->{Account}, $Source);
			}
			Console::stdout($Entry->display);
			$Entry->{number} = ++$Entity->{entry};
			$entries++;
		}
	}
	Console::note("Created %s allocation entries.", Console::green($entries)) if $options{display};
	return $entries;
}

sub updateSelection {
	my $Entity = shift;
	my $Update = shift; return unless $Update->{sink}->{Name};
	my $Sink   = $Entity->getAccount($Update->{sink}->{Name});

	#printf("Update selection %s\n", $Sink->display);

	# Update the Pattern of the existing Selection that identifies the same 
	# set of Accounts as the new Selection
	my @Update  = $Entity->getAccounts($Update->{source}->{Name});
	my $updates = scalar @Update;
	my $updated = 0;
	my $index;
	foreach my $Current ($Sink->Selections) {
		#printf("CURRENT:\n%s", $Current->display);
		my @Current = $Entity->getAccounts($Current->{source}->{Name});
		# The set must be the same size
		next unless scalar @Current == $updates;
		# and contain the same elements
		for($index=0; $index<$updates; $index++) {
			last unless $Update[$index] eq $Current[$index];
		}
		next unless $index == $updates;
		# for an update to happen
		#printf("BEFORE:\n%s", $Current->{source}->{Pattern}->display);
		$Current->{source}->{Pattern}->append($Update->{source}->{Pattern});
		#printf("AFTER:\n%s", $Current->{source}->{Pattern}->display);
		if ($Update->is_transfer) {
			$Current->{sink}->{Pattern} = new Pattern() unless $Current->{sink}->{Pattern};
			$Current->{sink}->{Pattern}->append($Update->{sink}->{Pattern});
		}
		$updated = 1;
		last;
	}
	#printf("INSERTING:\n%s", $Update->display) unless $updated;
	# Add the Selection if an existing Selection wasn't updated
	push @{$Sink->{Selections}}, $Update unless $updated;
}

sub createTransferEntries {
	my $Entity    = shift;
	my $Selection = shift;
	my %options   = shift;
	my $accounts  = $Entity->selectActions($Selection, %options);
	my $entries   = 0;

	# Sink Actions are the result of "zippering" Actions from different
	# source Accounts over time.  So start from the Sink Action, then
	# find the Source Account with the partner action at the head of
	# it's action list.
	my $sink = $accounts->{sink}->[0];
	foreach my $Sink (@{$sink->{Actions}}) {
		foreach my $source (@{$accounts->{source}}) {
			my @Sources = @{$source->{Actions}}; next unless @Sources;
			my $Source  = $Sources[0];
			if (($Source->debit == $Sink->credit) and ($Source->credit == $Sink->debit)) {
				$Source = shift @{$source->{Actions}};
				my $Entry = new Entry;
				$Entry->action($source->{Account}, $Source);
				$Entry->action($sink->{Account}  , $Sink  );
				Console::stdout($Entry->display);
				$Entry->{number} = ++$Entity->{entry};
				$entries++;
				last;
			}
		}
	}
	# Assert: all source Actions have been consumed.
	Console::note("Created %s transfer entries.", Console::green($entries)) if $options{display};
	return $entries;
}


my $ALLOCATE = <<'_';

Usage: textbooks ENTITY alloc
         [-h | --help]
         [@NAME]

_
sub allocate {
	my $Entity = shift;
	my @args   = @_;
	my $Name   = undef;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help")) { return &usage($ALLOCATE); }
		else                                       { $Name = new Name($op);    }
	}

	my $entries = 0;
	foreach my $Account ($Entity->getAccounts($Name)) {
		foreach my $Selection ($Account->Selections) {
			if ($Selection->is_allocation) {
				$entries += $Entity->createAllocationEntries($Selection, display => 0);
			} else {
				$entries += $Entity->createTransferEntries($Selection, display => 0);
			}
		}
	}
	Console::note("Created %s entries.", Console::green($entries));
}


my $SELECT = <<'_';

Usage: textbooks GL select 
         [-h | --help]
         [-p | --period PERIOD]
         [-u | --under LIMIT]
         [-o | --over LIMIT]
         [-l | --learn]
         [-a | --actions]
         [[@NAME] PATTERN [PATTERN ...] [-- @NAME [PATTERN ...]]]

The select command identifies unpaired actions for display or for reconstructing
transactions.

The set of unpaired actions selected can be refined by date by passing a PERIOD
with the --period option or by amount by passing a dollar LIMIT to the --under 
or --over options.

The command has several styles of invocation intended for progressively building
up a *selection*, which is a set of @NAMEs and PATTERNs that compactly describe 
a collection of transactions.  Selections that describe a large collection of 
recurring transactions (e.g. allocating pay deposits as income) can be saved in
the ENTITY file with the --learn option.  (Conversely a selection that describes
a single, unlikely and/or unique transaction should not be saved).

select
	Displays all unpaired actions.

select @NAME
	Displays unpaired actions in the Account(s) identified by @NAME.

select PATTERN ...
	Displays unpaired actions that match the PATTERN in any Account.

select @NAME PATTERN ...
	Displays unpaired actions that match the PATTERN in the Account(s) 
	identified by @NAME.

select [@SOURCE] PATTERN ... -- @SINK
	Allocates unpaired actions that match the PATTERN in the source Account(s) 
	identified by @SOURCE, if provided, to the Account identifies by @SINK.
	This formulation creates a complimentary action in the @SINK Account to make 
	the action a transaction that allocates the unpaired action.

	Displays a list of journal entries unless the --actions option is specified.

select [@SOURCE] PATTERN ... -- @SINK PATTERN ...
	Pairs unpaired actions that match the PATTERN in the source Account(s)
	identified by @SOURCE, if provided, to unpaired actions that match the
	PATTERN identified in the @SINK Account.  This formulation defines
	transactions that are transfers between Accounts with unpaired actions.

	Displays a list of journal entries unless the --actions option is specified.

_
sub select {
	my $Entity    = shift;
	my $commit    = shift;
	my @args      = @_;
	my $Selection = new Selection;
	my $Limit     = new Limit;
	my $terms     = {source => [], sink => []};
	my $side      = 'source';
	my $limit     = 0;
	my $learn     = 0;
	my $actions   = 0;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help"   )) { return &usage($SELECT);                         }
		elsif (($op eq "-p") or ($op eq "--period" )) { $Selection->{Period} = new Period(shift @args); }
		elsif (($op eq "-u") or ($op eq "--under"  )) { $limit   = 1; $Limit->add('<', shift @args);    }
		elsif (($op eq "-o") or ($op eq "--over"   )) { $limit   = 1; $Limit->add('>', shift @args);    }
		elsif (($op eq "-l") or ($op eq "--learn"  )) { $learn   = 1;                                   }
		elsif (($op eq "-a") or ($op eq "--actions")) { $actions = 1;                                   }
		elsif (($op eq "--")                        ) { $side  = 'sink';                                }
		elsif (($op =~ m/^@/)                       ) { $Selection->{$side}->{Name} = new Name($op);    }
		else                                          { push @{$terms->{$side}}, $op;                   }
	}

	$Selection->{Limit}             = $Limit if $limit;
	$Selection->{source}->{Pattern} = new Pattern(@{$terms->{source}}) if @{$terms->{source}};
	$Selection->{sink}->{Pattern}   = new Pattern(@{$terms->{sink}})   if @{$terms->{sink}};

	$Entity->updateSelection($Selection) if $learn;

	if ($Selection->is_query or $actions) {
		$Entity->showSelectedActions($Selection);
	} elsif ($Selection->is_allocation) {
		$Entity->createAllocationEntries($Selection, display => 1);
	} else {
		$Entity->createTransferEntries($Selection, display => 1);
	}

#	$Entity->select(0, $Entity->items) if $commit;

	return 1;
}

sub items {
	my $Entity = shift;
    my %items  = ();
    my $total  = 0;

    foreach my $Account ($Entity->getAccounts) {
    	next unless $Account->import;
    	for my $Action ($Account->Actions) {
    		next if $Action->Entry;
    		my $item = $Action->item;
    		$items{$item} = 0 unless $items{$item};
    		$items{$item}++;
    		$total++;
    	}
    }

    my %counts = ();
    foreach my $item (keys %items) {
    	my $count = $items{$item};
    	$counts{$count} = [] unless $counts{$count};
    	push @{$counts{$count}}, $item;
    }

    my @counts = sort {$b <=> $a} keys %counts;
    my $count  = $counts[0];
    my $item   = $counts{$count}->[0];

    $Entity->select(0, $item);

    Console::note("%d unallocated actions.", $total);
    Console::note("%d instances of %s.", $count, Console::green($item));

    return $item;
}


#───────────────────────────────────────────────────────────────────────────────────────────────────
# Fine Allocation
#───────────────────────────────────────────────────────────────────────────────────────────────────

my $ENTRY = <<'_';

Usage: textbooks GL entry 
         [-h | --help]
         [-d | --delete]
         [RANGE+]

The entry command is used to display and optionally delete one or more journal
entries.

Without any RANGEs specified, all journal entries are processed.  Otherwise only
those entries specified with one or more RANGE values are processed.  Each RANGE
is a START:STOP:STEP triplet, with STEP equal to 1 if unspecified and STOP equal
to START if unspecified.  The STOP value is inclusive, so that a 0:4:2 RANGE
specifies 0, 2, 4.

Journal entries are always displayed.  They are deleted if the --delete option
is specified.  Each action in the journal entry is deleted from the account,
unless the action was imported, in which case only the entry number is deleted.

_
sub entry {
	my $Entity  = shift;
	my @args    = @_;
	my @ranges  = ();
	my $delete  = 0;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help"  )) { return &usage($ENTRY);   }
		elsif (($op eq "-d") or ($op eq "--delete")) { $delete = 1;             }
		else                                         { push @ranges, shift;     }
	}

	my %entries = ();
	foreach my $range (@ranges) {
		my ($start, $stop, $step) = split /:/, $range;
		$stop = $start unless defined $stop;
		$step = 1      unless defined $step;
		while ($start <= $stop) {
			$entries{$start} = 1;
			$start += $step;
		}
	}
	Console::error("Can not delete unspecified entries.") if $delete and not %entries;

	my %Entries = ();
	foreach my $Account ($Entity->getAccounts()) {
		foreach my $Action ($Account->Actions) {
			my $entry = $Action->Entry; next unless $entry;
			next if %entries and not $entries{$entry};
			$Entries{$entry} = new Entry(number => $entry) unless $Entries{$entry};
			$Entries{$entry}->action($Account, $Action);
		}
	}

	my @invalid = ();
	foreach my $entry (sort {$a <=> $b} keys %Entries) {
		my $Entry = $Entries{$entry};
		Console::stdout($Entry->display);
		if (not $Entry->valid) {
			Console::warn("Invalid entry");
			push @invalid, $Entry->number;
		}
		next unless %entries and $delete;
		Console::warn("Deleting entry %06d", $entry);
		foreach my $debit ($Entry->debits) {
			$debit->{Account}->remove($debit->{Action});
		}
		foreach my $credit ($Entry->credits) {
			$credit->{Account}->remove($credit->{Action});
		}
	}

	my $entries = scalar keys %Entries;
	Console::note("%s entries", Console::green($entries)) if $entries > 1;
	Console::error("invalid: %s", join(", ", @invalid)) if @invalid;
	
	return 1;
}

my $ENTER = <<'_';

Usage: textbooks GL enter
         [-h | --help]
         @NAME  DATE   ITEM+  DEBIT, | ,CREDIT
         @NAME [DATE] [ITEM+] DEBIT, | ,CREDIT
         ...

The enter command is used to hand craft journal entries.

_
#NEED: Needs clean up.  Wasn't very user friendly for simple transactions.  Would
#      be nice to only have to enter one amount that applies to both sides.
sub enter {
	my $Entity  = shift;
	my @args    = @_;
	my $Account = undef;
	my @date    = localtime;
	my $date    = sprintf("%d-%02d-%02d", $date[5]+1900, $date[4]+1, $date[3]);
	my $item    = "";
	my $reset   = 1;
	my $Entry   = new Entry();

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help")) { return &usage($ENTER);                              }
	    elsif ($op =~ m/^@/                      ) { $Account = $Entity->getAccount(new Name $op);           }
	    elsif ($op =~ m/\d\d\d\d-\d\d-\d\d/      ) { $date = $op;                                            }
		elsif ($op =~ m/(\d+([.]\d\d)?)[:,]/     ) { $Entry->debit($Account, $date, $item, $1);  $reset = 1; }
		elsif ($op =~ m/[:,](\d+([.]\d\d)?)/     ) { $Entry->credit($Account, $date, $item, $1); $reset = 1; }
		elsif ($reset                            ) { $item = $op; $reset = 0;                                }
		else                                       { $item .= " ".$op;                                       }
	}

	Console::stdout($Entry->display);
	Console::error('Invalid') unless $Entry->valid;
	$Entry->{number} = ++$Entity->{entry};

	return 1;

}

my $REBALANCE = <<'_';

Usage: textbooks GL rebalance
         [-h | --help]
         [@NAME]

The rebalance command recalculates balances in asset & liability accounts that
do not have imported actions.

All asset & liability accounts with imported actions are rebalanced unless
a selection of accounts is specified with an @NAME.

Rebalancing is generally only required if the GL is edited by hand.

_
sub rebalance {
	my $Entity = shift;
	my @args   = @_;
	my $Name   = undef;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help")) { return &usage($REBALANCE); }
		else                                       { $Name = new Name($op);     }
	}

	foreach my $Account ($Entity->getAccounts($Name)) {
		next if $Account->import or not $Account->balanced;
		Console::note("Rebalancing %s", $Account->display);
		$Account->rebalance;
	}
	return 1;

}

my $REORDER = <<'_';

Usage: textbooks GL reorder
         [-h | --help]
         [@NAME]

The reorder command reorders actions in assending date order.  If the account
has a balance, it is rebalanced as well.

All accounts without imported actions are reordered unless a selection of 
accounts is specified with an @NAME.

Reordering is generally only required if the GL is edited by hand.

_
sub reorder {
	my $Entity = shift;
	my @args   = @_;
	my $Name   = undef;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help")) { return &usage($REORDER); }
		else                                       { $Name = new Name($op);   }
	}

	foreach my $Account ($Entity->getAccounts($Name)) {
		next if $Account->import;
		Console::note("Reordering %s", $Account->display);
		$Account->reorder;
	}
	return 1;

}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Reporting
#───────────────────────────────────────────────────────────────────────────────────────────────────

# Displays parital ledgers from one or more accounts.
sub reportLedgers {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Period  = $options{Period};
	my $Pattern = $options{Pattern};
	my $HEADER;
	my $ACTION;
	my $FOOTER;
	foreach my $Account ($Entity->getAccounts($Name)) {
		my @Actions = $Account->Actions;
		next unless @Actions;
		if ($Account->balanced and not $Pattern) {
			$HEADER = $STATE::HEADER;
			$FOOTER = $STATE::NET;
		} else {
			$HEADER = $CHANGE::HEADER;
			$FOOTER = $CHANGE::NET;
		}
		my $debits  = 0;
		my $credits = 0;
		my @lines   = ();
		foreach my $Action (@Actions) {
			next if $Period  and not $Period->contains($Action->date);
			next if $Pattern and not $Pattern->matches($Action->item);
			$Action->{Pattern} = $Pattern;
			$debits  += $Action->debit;
			$credits += $Action->credit;
			push @lines, $Action->display(ledger => 1, balanced => $Account->balanced);
		}
		next unless @lines;
		# Color in the Account messes up the Period alignment when present.
		# Normally we'd do Name matching after the sprintf, but in this case the
		# Period includes a colon character that interfers with the process.  So
		# instead we just add the number of non-printable characters to the
		# column width. It would be nice to push this into Console, since it is
		# a recurring problem.
		my $width = 57 + length($Account->display) - length($Account->identifier);
		Console::stdout($HEADER, sprintf("%-${width}s", $Account->display), $Period);
		foreach my $line (@lines) {
			Console::stdout($line);
		}
		Console::stdout($FOOTER, Amount::columns($debits, $credits), Amount::net($debits, $credits));
	}
}

# Displays a Trial Balance report.
sub reportTrialBalance {
	my $Entity  = shift;
	my %options = @_;
	my $Period  = $options{Period};
	my $totals  = $options{totals};
	my $debits  = 0;
	my $credits = 0;
	Console::stdout($CHANGE::HEADER, "TRIAL BALANCE", $Period);
	foreach my $Account ($Entity->getAccounts()) {
		my ($debit, $credit, $net) = $Account->totals(totals => $totals, Period => $Period);
		Console::stdout($CHANGE::ACCOUNT, $Account->identifier, Amount::columns($debit, $credit)) if $debit or $credit;
		$debits  += $debit;
		$credits += $credit;
	}
	Console::stdout($CHANGE::TOTAL, Amount::columns($debits, $credits));
}

# Displays an income & expense statement.
sub reportIncomeExpense {
	my $Entity  = shift;
	my %options = @_;
	my $Period  = $options{Period};
	my $net     = 0;
	Console::stdout($NET::HEADER, "INCOME & EXPENSE", $Period);
	foreach my $Account ($Entity->getAccounts()) {
		next if $Account->balanced;
		my ($implicit, $explicit) = $Account->totals(signed => 1, rollup => 1, Period => $Period);
		next unless Amount::penny($implicit);  # Catch rollups that are 0.00
		$net += $explicit unless $Account->Parent;
		$implicit = Amount::column($implicit);
		$implicit = Console::cyan($implicit) if $Account->Children;
		Console::stdout($NET::ACCOUNT, $Account->identifier(implicit => 1), $implicit);
	}
	Console::stdout($NET::FOOTER, Amount::column($net));
}

# Displays a balance sheet.
sub reportBalanceSheet {
	my $Entity  = shift;
	my %options = @_;
	my $date    = $options{date};
	my $net     = 0;
	Console::stdout($NET::HEADER, "BALANCE SHEET", $date);
	foreach my $Account ($Entity->getAccounts()) {
		next unless $Account->balanced;
		my ($implicit, $explicit) = $Account->balances(rollup => 1, date => $date);
		next unless Amount::penny($implicit);  # Catch rollups that are 0.00
		$net += $explicit unless $Account->Parent;
		$implicit = Amount::column($implicit);
		$implicit = Console::cyan($implicit) if $Account->Children;
		Console::stdout($NET::ACCOUNT, $Account->identifier(implicit => 1), $implicit);
	}
	Console::stdout($NET::FOOTER, Amount::column($net));
}

my $REPORT = <<'_';

Usage: textbooks GL report
         [-h | --help]
         [-t | --trial]
         [-p | --period PERIOD]
         [@NAME] [PATTERN]

Without any arguments the report command displays the Balance Sheet and the
Income & Expense statement.  

If the --trial options is specified, a Trial Balance report is displayed.  This
report shows non-zero net debits & credits for each account.  A element of this
report is that total debits equals the total credits.

If an @NAME and/or PATTERN is provided, the actions from ledgers that match the
criteria are displayed.

When a PERIOD is specified, balances are as of the end date of the period, and
only actions within the PERIOD are reported.  Otherwise balances are as of the
last recorded action and all actions are reported.

_
sub report {
	my $Entity  = shift;
	my @args    = @_;
	my $trial   = 0;
	my @terms   = ();
	my $Pattern;
	my $Period;
	my $Name;
	my $date;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help"  )) { return &usage($REPORT);            }
		elsif (($op eq "-t") or ($op eq "--trial" )) { $trial = 1;                       }
		elsif (($op eq "-p") or ($op eq "--period")) { $Period = new Period shift @args; }
		elsif ($op =~ m/^@/                        ) { $Name = new Name($op);            }
		else                                         { push @terms, $op;                 }
	}

	$Pattern = new Pattern(@terms) if @terms;

	return $Entity->reportTrialBalance(Period => $Period) || 1 if $trial;

	return $Entity->reportLedgers(Name => $Name, Period => $Period, Pattern => $Pattern) || 1 if $Name or $Pattern;

	$date = $Period->end if $Period;

	$Entity->reportBalanceSheet(date => $date);
	$Entity->reportIncomeExpense(Period => $Period);

	return 1;
}

my $RULES = <<'_';

Usage: textbooks GL rules 
         [-h | --help]
         [-i | --imports]
         [-s | --selections]
         [@NAME]

The rules command displays import and selection rules saved in the GL.

Only import rules are displayed if the --imports option is specified, or only
selection rules are displayed if the --selections option is specified, otherwise
both types of rules are displayed.

Only rules from Account(s) identified by @NAME are display when specified.

Rules are generally created through the import and select commands that also
use those rules to process actions in CSV bank statements. Rules can also be 
created, updated or deleted by simply editing the GL.

_
sub rules {
	my $Entity = shift;
	my @args   = @_;
	my $Name   = undef;
	my $import = 1;
	my $select = 1;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help"      )) { return &usage($RULES);   }
		elsif (($op eq "-s") or ($op eq "--selections")) { $import = 0;             }
		elsif (($op eq "-i") or ($op eq "--imports"   )) { $select = 0;             }
		else                                             { $Name   = new Name($op); }
	}

	foreach my $Account ($Entity->getAccounts($Name)) {
		my $selections = ($select and $Account->Selections);
		my $imports    = ($import and $Account->import);
		next unless $selections or $imports;
		Console::stdout("%s\n", $Account->display);
		Console::stdout($CHANGE::LINE);
		Console::stdout("* %s\n", $Account->import) if $imports;
		Console::stdout($CHANGE::LINE) if $imports and $selections;
		Console::stdout(join("\n", map {$_->display} $Account->Selections)) if $selections;
		Console::stdout("%s\n\n", $CHANGE::LINE);
	}
}


#───────────────────────────────────────────────────────────────────────────────────────────────────
# Finishing
#───────────────────────────────────────────────────────────────────────────────────────────────────

my $OPEN = <<'_';

Usage: textbooks GL open
         [-h | --help]
         [-p | --period PERIOD]
         NEW_GL

The open command prepares a new GL from an existing GL, keeping the chart of 
accounts, import rules, selection rules and balances, but omitting any actions.  
The balances in the new GL are the balances at the end of the period captured
by the old GL.  Balances are transferred with the last recorded date, or the
start date of the PERIOD when specified.

_
# NEED: update PERIOD to DATE (like enter command)
sub open {
	my $Entity = shift;
	my @args   = @_;
	my $Period = undef;
	my $file   = undef;

	while (@args) {
		my $op = shift @args;
		if    (($op eq "-h") or ($op eq "--help"  )) { return &usage($REBALANCE);        }
		elsif (($op eq "-p") or ($op eq "--period")) { $Period = new Period shift @args; }
		else                                         { $file = $op;                      }
	}

	Console::error("The new GL not specified.") unless $file;
	Console::error("The new GL can not be the current GL.") if $file eq $Entity->{file};

	$Entity->put(file => $file, Period => $Period, open => 1);

	return 0;  # Don't change the current file
}


#───────────────────────────────────────────────────────────────────────────────────────────────────
# Application
#───────────────────────────────────────────────────────────────────────────────────────────────────
# Note: This not a method

my $SESSION = <<"_";

Usage: textbooks GL [-h | --help] COMMAND [OPTIONS]
         [[-M | --mute] | [-V | --verbose] | [-P | --profuse]]
         [-N | --no-color]
         [-C | --commit]

Manages the text based books for the specified general ledger (GL).

OPTIONS :

	The following options can be specified before or after the command. All 
	other options or arguments are passed to the command.  Note that options 
	controlling the overall sesssion have upper case short forms, while options
	for commands have lower case short forms.

	--help, -h    : display this help or the help for the command when
	                specified after the command.

	--mute, -M    : disable the display of warnings & notes.
	--verbose, -V : display more information about the requested command.
	--profuse, -P : display all information about the requested command.

	--commit, -C  : commit the changes to disk.

COMMANDS :

    Setup Commands
    --------------

	chart         : Create, display & update the chart of accounts.

	Data Gathering Commands
	-----------------------

	import        : Create & update import rules and import single sided actions.
	reconcile     : Validate the integrity of balances.
	deport        : Deport previously imported actions.

	Coarse Allocation Commands
	--------------------------

	alloc         : Create transactions by applying existing selection rules
	                to newly imported single sided actions.
	select        : Create & update new selection rules to reconstruct 
	                transactions from single sided actions.
	items         : Find and display the most frequent unallocated items.

	Fine Allocation Commands
	------------------------

	entry         : Find & delete specific transactions.
	enter         : Create transactions.
	rebalance     : Recalculate balances in asset & liability accounts.

	Reporting Commands
	------------------

	report        : report the balance sheet, income & expense statement
	                and other reports.
	rules         : display saved import & selection rules.

	Finishing Commands
	------------------

	open          : Create a new GL from the existing GL.

_

# Displays a help message and optional error message.
sub usage {
	my $help  = shift;
	my $error = shift;

	Console::stdout($help);
	Console::error($error, @_) if $error;
	return 0;
}

# The main entry point for the command line script.
sub session {
	my @argv   = @_;
	my $commit = 0;
	my $entity;
	my $command;
	my @args;
	my $success;

	while (@argv) {
		my $op = shift @argv;
		if    (($op eq "-C") or ($op eq "--commit"  )) { $commit             = 1; }
		elsif (($op eq "-M") or ($op eq "--mute"    )) { $Console::VERBOSITY = 0; }
		elsif (($op eq "-V") or ($op eq "--verbose" )) { $Console::VERBOSITY = 2; }
		elsif (($op eq "-P") or ($op eq "--profuse" )) { $Console::VERBOSITY = 3; }
		elsif (($op eq "-N") or ($op eq "--no-color")) { $Console::COLOR     = 0; }
		elsif (defined $command                      ) { push @args, $op;         }
		elsif (($op eq "-h") or ($op eq "--help"    )) { return usage($SESSION);  }
		elsif (not defined $entity                   ) { $entity    = $op;        }
		else                                           { $command   = $op;        }
	}

	usage($SESSION, "No <entity> specified.") unless defined $entity;
	$command = "report" unless defined $command;

	my $Entity = -e $entity ? get Entity($entity) : new Entity();

	# Setup
	if    ($command eq "chart"    ) { $success = $Entity->chart(@args);                    }
	# Data Gathering
	elsif ($command eq "import"   ) { $success = $Entity->import(@args);                   }
	elsif ($command eq "reconcile") { $success = $Entity->reconcile(@args);                }
	elsif ($command eq "deport"   ) { $success = $Entity->deport(@args);                   }
	# Coarse Allocation
	elsif ($command eq "alloc"    ) { $success = $Entity->allocate(@args);                 }
	elsif ($command eq "select"   ) { $success = $Entity->select($commit, @args);          }
	elsif ($command eq "items"    ) { $success = $Entity->items(@args);                    }
	# Fine Allocation
	elsif ($command eq "entry"    ) { $success = $Entity->entry(@args);                    }
	elsif ($command eq "enter"    ) { $success = $Entity->enter(@args);                    }
	elsif ($command eq "rebalance") { $success = $Entity->rebalance(@args);                }
	elsif ($command eq "reorder"  ) { $success = $Entity->reorder(@args);                  }
	# Reporting
	elsif ($command eq "report"   ) { $success = $Entity->report(@args);                   }
	elsif ($command eq "rules"    ) { $success = $Entity->rules(@args);                    }
	# Finishing
	elsif ($command eq "open"     ) { $success = $Entity->open(@args);                     }
	else                            { return usage($SESSION, "Invalid COMMAND: $command"); }

	$Entity->put(file => $entity) if $success and $commit;

	return 1;
}


1;
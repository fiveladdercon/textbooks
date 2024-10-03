#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Merge;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Console;
use Period;


sub merge {
	my @existing = @{shift @_};
	my @inbound  = @{shift @_};

	return [@inbound] unless @existing;

	my $ex_length = scalar @existing;
	my $ib_length = scalar @inbound;

	my $exp = new Period(sprintf("%s:%s", $existing[0]->date, $existing[-1]->date));
	my $inp = new Period(sprintf("%s:%s", $inbound[0]->date , $inbound[-1]->date));

	printf("%s into %s (%d)\n", $inp->display, $exp->display, scalar @existing);

	if ($inp->end lt $exp->start) {
		# entirely before
		printf("Entirely Before\n");
		unshift @existing, @inbound;
		return [@existing];
	} elsif ($exp->end lt $inp->start) {
		# entirely after
		printf("Entirely After\n");
		push @existing, @inbound;
		return [@existing];
	} else {
		# overlap
		print("Overlap!\n");
		return [@existing];
	}

	my $ex_length = scalar @existing;
	my $ib_length = scalar @inbound;

	if ($ib_length <= $ex_length) {
		# Check that inbound is not entirely contained within the existing
		my $contained = 0;
		for (my $offset=0; $offset < $ex_length-$ib_length+1; $offset++) {
			my $match = 1;
			for (my $index=0; $index < $ib_length; $index++) {
				if ($existing[$offset+$index]->balance != $inbound[$index]->balance) {
					$match = 0; 
					break;
				}
			}
			if ($match) {
				$contained = 1;
				break;
			}
		}
		printf("contained %d\n", $contained);
	}



	return [@existing];
}

sub zip {
	my $Entity  = shift;
	my %options = @_;
	my $Name    = $options{Name};
	my $Pattern = $options{Pattern};
	my $Period  = $options{Period};

	Console::note("Importing...") if $Console::VERBOSITY < $Console::PROFUSE;

	my $total_imports = 0;
	foreach my $Account ($Entity->getAccounts($Name)) {
		next unless $Account->{import};
		Console::info($Console::NORMAL, "Importing %s", $Account->display);

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

			Console::info($Console::NORMAL, "%d (of %d) actions from %s", scalar @inbound, $source_actions, $source);

			my @existing = $Account->Actions;

			$Account->{Actions} = &merge(\@existing, \@inbound);

	   	}

	}

	return 1;

}

1;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Name;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $pattern  = shift; $pattern =~ s/^\s*@\s*//; $pattern =~ s/\s+$//;
    my $Ref      = bless { 
    	pattern => $pattern,
    }, $class;
	return $Ref;
}

sub matches {
	my $Name    = shift;
	my $string  = shift;
	my @pattern = split /:/, $Name->{pattern};
	my $pattern = shift @pattern;
	my @output  = ();
	for my $input (split /:/, $string) {
		$pattern = shift @pattern if defined $pattern and $input =~ s/$pattern/\e[32m$&\e[0m/i;
		push @output, $input;
	}
	return undef if defined $pattern;
	return join(":", @output);
}


sub string {
	return shift->{pattern};
}


1;
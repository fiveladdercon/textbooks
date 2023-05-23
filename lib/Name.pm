#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Name;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Console();

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $pattern  = shift; $pattern =~ s/^\s*@\s*//; $pattern =~ s/\s+$//;
    my $Ref      = bless { 
    	pattern => $pattern,
    }, $class;
	return $Ref;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Name->display(%options) => string
#
# Returns a display string.
#
# pad => 1 : add a space between the '@' and the pattern.
#
sub display {
	my $Name    = shift;
	my %options = @_;
	my $padding = $options{pad} ? ' ' : '';
	return '@'.$padding.$Name->{pattern};
}

# $Name->matches(string) => string|undef
#
# Returns a highlighted copy of the string if the Name can be found in the 
# string or undef if not.
#
# The string and Name are compared component-wise after splitting on a colon 
# (:), and a match is deemed if no Name components remain after exhausting all 
# input string components.  Component matches are highlighted with green.
#
sub matches {
	my $Name    = shift;
	my $string  = shift;
	my @pattern = split /:/, $Name->{pattern};
	my $pattern = shift @pattern;
	my @output  = ();
	for my $input (split /:/, $string) {
		$pattern = shift @pattern if defined $pattern and $input =~ s/$pattern/&Console::green($&)/ie;
		push @output, $input;
	}
	return undef if defined $pattern;
	return join(":", @output);
}



1;

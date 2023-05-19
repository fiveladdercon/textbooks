#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Pattern;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Console();

#-----------------------------------------------
# Need:
#-----------------------------------------------
#
# (A & B) | (C & !D) | (E & !F) ...
#
# 1) construct line-by-line from a file
# 2) construct from a string on the command line
#
#   &   |   !     : unusable on the command line
#   +   ^   -     : usable on the command line
#           ~     : usable if not alone or
#                   followed by /, as in a path
# 
#-----------------------------------------------
# File Format:
#-----------------------------------------------
#
# | A & B 
# | C & !D
# | E & !F
#
#-----------------------------------------------
# Command Line:
#-----------------------------------------------
#
# The command line is assembling one term in the
# disjunction of conjunctions:
#
# import JCHQ HLOC JUSD VISA  => JCHQ | HLOC | JUSD | VISA
#
# allocate MCDONALD HARVEY TIM +HORTON => MCDONALD | HARVEY | TIM & HORTON
#
# allocate ESSO ~EXPRESSO PETROCAN => ESSO & !EXPRESSO | PETROCAN
#

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
    my $Pattern  = bless {
    	disjunc  => [],
    	conjunc  => undef,
    	exclude  => 0,
    }, $class;
    $Pattern->parse(join(" ", @_));
	return $Pattern;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Input
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub parse {
	my $Pattern = shift;
	my $string  = shift;
	my $tokens  = $string;
	while ($tokens) {
		if ($tokens =~ s/^\s*([&+.*|^!~-])\s*//) {
			my $op = $1;
			if ($op =~ /[|^]/) {
				$Pattern->{conjunc} = undef;
			} elsif ($op =~ /[!~-]/) {
				$Pattern->{exclude} = 1;
			}
		} elsif ($tokens =~ s/^(([^\[&.*+|^!~-]|\[[^\]]\])+)//) {
			my $term = $1; $term =~ s/\s+$//;
			if (not defined $Pattern->{conjunc}) {
				$Pattern->{conjunc} = scalar @{$Pattern->{disjunc}};
				push @{$Pattern->{disjunc}}, []
			}
			push @{$Pattern->{disjunc}->[$Pattern->{conjunc}]}, [$Pattern->{exclude}, $term];
			$Pattern->{exclude} = 0;
		} else {
			Console::error("Can not parse rule: '%s'", $string);
		}
	}
}

sub term {
	my $Pattern = shift;
	my @terms   = @_;
	foreach my $term (@terms) {
		if ($term =~ /^[!~-]/) {
			$term = "& $term";
		} elsif ($term !~ /^[&+|^]/) {
			$term = "| $term";
		}
		$Pattern->parse($term);
	}
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Output
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub string {
	my $Pattern = shift;
	my $string  = "";
	foreach my $dj (@{$Pattern->{disjunc}}) {
		my $op = "| ";
		foreach my $cj (@{$dj}) {
			my ($exclude, $term) = @{$cj};
			$string .= sprintf("%s%s%s", $op, $exclude ? "!" : "", $term);
			$op = " & ";
		}
		$string .= "\n";
	}
	return $string;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Functional
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub append {
	my $Pattern = shift;
	my $Source  = shift;
	push @{$Pattern->{disjunc}}, @{$Source->{disjunc}};
}

sub amend {
	my $Pattern = shift;
	my $Source  = shift;
	foreach my $sdj (@{$Source->{disjunc}}) {
		my ($sterm, @scond) = @{$sdj};
		foreach my $ddj (@{$Pattern->{disjunc}}) {
			my ($dterm) = @{$ddj};
			if ($dterm->[1] eq $sterm->[1]) {
				push @{$ddj}, @scond;
			}
		}
	}
}

sub excludes {
	my $Pattern = shift;
	my $string  = shift;
	my (undef, $excluded) = $Pattern->matched($string);
	return $excluded;
}

sub includes {
	my $Pattern = shift;
	my $string  = shift;
	my ($included, undef) = $Pattern->matched($string);
	return $included;
}

sub matches {
	my $Pattern  = shift;
	my $string   = shift;
	my ($included, $excluded) = $Pattern->matched($string);
  	return $excluded ? undef : $included;
}

sub terms {
	return scalar @{shift->{disjunc}} > 0;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Private
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub matched {
	my $Pattern  = shift;
	my $string   = shift;
	my $excluded = undef;
	my $included = $string;
	my @dj       = @{$Pattern->{disjunc}};
	return ($included, $excluded) unless @dj;
	my $any = 0;
	my $all = 1;
	foreach my $dj (@dj) {
		$included = $string;
		$all = 1;
		foreach my $cj (@{$dj}) {
			my ($exclude, $term) = @{$cj};
			$term =~ s/\\//g;
			if ($exclude) {
				if ($string =~ m/$term/i) {
					$excluded = $string;
					$excluded =~ s/$term/\e[31m$&\e[0m/gi;
					$all = 0;
					last;
				}
			} else {
				if ($string =~ m/$term/i) {
					$included =~ s/$term/\e[32m$&\e[0m/gi;
				} else {
					$all = 0;
					last;
				}
			}
		}
		if ($all) {
			$excluded = undef;
			$any = 1;
			last;
		}
	}
	if (not $any) {
		$included = undef;
	}
	return ($included, $excluded);
}


1;
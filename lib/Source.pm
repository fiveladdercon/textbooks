#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Variable;
#═══════════════════════════════════════════════════════════════════════════════════════════════════
use Console();

# Variable::expansion(string) => {}
#
# Returns a name, value mapping of environment variables in the given string.
# Throws an error if the environment variable is not set.
#
# e.g.  Variable::expansion("Hello $PWD") => {PWD => "/..."}
#
sub expansion {
	my $string = shift;
	my $value  = {};

	while ($string =~ s/\$((\w+)|\{([^\}]+)\})//) {
		my $name = $2 | $3;
		Console::error("Environment variable $name is not set.") unless exists $ENV{$name};
		$value->{$name} = $ENV{$name};
	}

	return $value;
}

# Variable::expand(string, expansion=undef) => string
#
# Replaces environment variable names with values from the given expansion.
# If the expansion isn't given, it is extracted from the string.
#
# e.g.  Variable::expand("Hello $PWD") => "Hello /..."
#
sub expand {
	my $string = shift;
	my $value  = shift; $value = Variable::expansion($string) unless defined $value;

	foreach my $name (keys %{$value}) {
		$string =~ s/\$($name|\{$name\})/$value->{$name}/g;
	}

	return $string;
}

# Variable::contract(string, expansion) => string
#
# Replaces environment variable values with names from the given expansion.
#
# e.g.  Variable::constract("Hello /...", {PWD => "/..."}) => "Hello ${PWD}"
#
sub contract {
	my $string = shift;
	my $value  = shift;

	foreach my $name (keys %{$value}) {
		$string =~ s/$value->{$name}/\$\{$name\}/g;
	}

	return $string;
}

#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Line;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

use overload '""' => sub { shift->string; };

sub new {
	my $invocant = shift;
	my $class    = ref($invocant) || $invocant;
	my $Line     = {
		file     => shift,
		number   => shift,
		string   => shift || $_
	};
	return bless $Line, $class;
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Attributes
#───────────────────────────────────────────────────────────────────────────────────────────────────

sub file {
	return shift->{file};
}

sub number {
	return shift->{number};
}

sub string {
	return shift->{string};
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Properties
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Line->coord => string
#
# Returns a file, line number "coordinate" of the line of text.
#
sub coord {
	my $Line = shift;
	return sprintf("<%s:%d>", $Line->file, $Line->number);
}

#───────────────────────────────────────────────────────────────────────────────────────────────────
# Methods
#───────────────────────────────────────────────────────────────────────────────────────────────────

# $Line->csv => ()
#
# Returns the list of comma separated values (csv) from the current line.
#
sub csv {
	my $Line   = shift;
	my $value  = "";
	my @values = ();
	my $string = $Line->string;
	my $attempt = 100;
	while ($string and $attempt) {
		if ($string =~ s/^,//) {
			$value =~ s/^\s+//;
			$value =~ s/\s+$//;
			push @values, $value;
			$value = "";
		} elsif ($string =~ s/^(([^,"]|"[^"]*")+)//) {
			$value = $1;
		}
		$attempt--;
	}
	$value =~ s/^\s+//;
	$value =~ s/\s+$//;
	push @values, $value if $value;
	return @values;
}

#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Source;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

# Source::close();
#
# Closes the source file being written and selects STDOUT.
#
sub close {
	close(FILE);
	select STDOUT;
}

# Source::glob(string) => (string)
#
# Returns a list of files from the glob string.  If the glob string contains
# environment variable names, the are expanded before the glob and contracted
# afterwards.
#
# e.g. Source::glob("$PWD/*.csv") => ("${PWD}/A.csv", "${PWD}/B.csv", ...)
#
sub glob {
	my $glob  = shift;
	my $map   = Variable::expansion($glob);
	my @files = ();
	foreach my $file (glob(Variable::expand($glob, $map))) {
		push @files, Variable::contract($file, $map);
	}
	return @files;
}

# Source::line(filename) => (Line)
#
# Returns a list of Line objects from the give filename.  Environement variables
# in filename are expanded.  Box drawing characters and comments following a #
# are removed, as are leading and trailing spaces and the newline.  All white
# space is reduced to a single character.
#
sub line {
	my $file   = shift;
	my $path   = Variable::expand($file);
	my $number = 0;
	my @Lines  = ();

	open(FILE, "<$path") or Console::error("Can't open $file for reading: $!");
	while (<FILE>) {
		$number++;
		chomp;		  	     # Remove the new line
		s/^\s*#.*//;         # Remove leading comments
		s/\s*[│├┌└─╔║╚].*//; # Remove box drawings
		s/\s+/ /g;           # Reduce all white space to a single character
		s/^ //;              # Remove leading white space
		s/ $//;              # Remove trailing white space
		
		push @Lines, new Line($file, $number);
	}
	close(FILE);

	return @Lines;
}

# Source::open(filename)
#
# Opens the given filename for writting, expanding environment variables in
# the filename if needed.
#
sub open {
	my $file = shift;
	my $path = Variable::expand($file);
	my $ok = open(FILE,">$path");
	if ($ok) {
	    Console::note("Writing $file");
		select FILE;	
	} else {
		Console::error("Can't open $file for writing: $!");
	}
}



1;

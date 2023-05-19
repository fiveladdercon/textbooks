#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Variable;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

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

sub expand {
	my $string = shift;
	my $value  = shift; $value = Variable::expansion($string) unless defined $value;

	foreach my $name (keys %{$value}) {
		$string =~ s/\$($name|\{$name\})/$value->{$name}/g;
	}

	return $string;
}

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

# Getters

sub file {
	return shift->{file};
}

sub number {
	return shift->{number};
}

sub string {
	return shift->{string};
}

# Methods

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

sub coord {
	my $Line = shift;
	return sprintf("<%s:%d>", $Line->file, $Line->number);
}

#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Source;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

sub close {
	close(FILE);
	select STDOUT;
}

sub glob {
	my $glob  = shift;
	my $map   = Variable::expansion($glob);
	my @files = ();
	foreach my $file (glob(Variable::expand($glob, $map))) {
		push @files, Variable::contract($file, $map);
	}
	return @files;
}

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
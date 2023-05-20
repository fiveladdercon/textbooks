#═══════════════════════════════════════════════════════════════════════════════════════════════════
package Console;
#═══════════════════════════════════════════════════════════════════════════════════════════════════

# Public COLOR constants
my $RED        = "\e[31m";
my $GREEN      = "\e[32m";
my $YELLOW     = "\e[33m";
my $BLUE       = "\e[34m";
my $MAGENTA    = "\e[35m";
my $CYAN       = "\e[36m";
my $WHITE      = "\e[37m";
my $CLEAR      = "\e[0m";

# Public VERBOSITY constants
our $MUTE      = 0;
our $NORMAL    = 1;
our $VERBOSE   = 2;
our $PROFUSE   = 3;

# Public MODE controls
our $TESTING   = 0;       # Test mode. 0|1
our $COLOR     = 1;       # Color mode.  0|1
our $VERBOSITY = $NORMAL; # Verbosity level.  Set to a Verbosity constant.

# Private test mode variables
our @STDIN     = ();      # Redirect STDIN
our @STDOUT    = ();      # Redirect STDOUT
our @STDERR    = ();      # Redirect STDERR

# Setting $TESTING to 1 redirects stdio to internal variables so that they can 
# be compared to expected values.  The internal variables are not inspected 
# directly, but rather manipulated through the stdin/stdout/stderr methods.


# Console::stdin() => string
#
# Collects a string from STDIN and returns it.
#
# Console::stdin(format, ...)
#
# Pushes a formatted string onto @STDIN for testing.
#
sub stdin {
	my $fmt = shift;
	if (defined $fmt) {
		push @STDIN, sprintf($fmt, @_);
	} elsif ($TESTING) {
		my $stdin = shift @STDIN;
		die("<STDIN>: no test input defined!\n") unless defined $stdin;
		return $stdin;
	} else {
		return <STDIN>;
	}
}

# Console::stdout(format, ...)
#
# Formats and prints to STDOUT.  Color coding is removed if the $COLOR mode is 
# not set.
#
# Console::stdout => string
#
# Returns buffered output as a string for testing and flushes the buffer.
#
sub stdout  { 
	my $fmt = shift;
	if (not defined $fmt) {
		my $stdout = join("", reverse @STDOUT);
		@STDOUT = ();
		return $stdout;
	} else {
		my $string = sprintf($fmt, @_); $string =~ s/\e\[\d+m//g unless $COLOR;
		if ($TESTING) { 
			unshift @STDOUT, $string;
		} else {
			print ($string);
		}
	}
}

# Console::stderr(format, ...)
#
# Formats and prints to STDERR.  Color coding is removed if the $COLOR mode is 
# not set.
#
# Console::stderr => string
#
# Returns buffered output as a string for testing and flushes the buffer.
#
sub stderr  { 
	my $fmt = shift;
	if (not defined $fmt) {
		my $stderr = join("", reverse @STDERR);
		@STDERR = ();
		return $stderr;
	} else {
		my $string = sprintf($fmt, @_); $string =~ s/\e\[\d+m//g unless $COLOR;
		if ($TESTING) { 
			unshift @STDERR, $string;
		} else {
			printf STDERR $string;
		}
	}
}

# Console::color(COLOR, format, ...)
#
# Colors the formated string with the given COLOR. 
#
sub color { 
	my $color = shift;
	my $text  = sprintf(shift, @_);
	   $text = $color . $text;         # Prepend COLOR
	   $text =~ s/\e\[0m/$color/g;     # Replace embedded CLEARS with COLOR
	   $text =~ s/(\n)*$/${CLEAR}$&/;  # Append CLEAR after text but before any trailing newlines
	return $text;
}

# Console::<color>(format, ....)
#
# Convience methods for color coding formated strings.
#
sub red     { return &color($RED    , @_); }
sub green   { return &color($GREEN  , @_); }
sub yellow  { return &color($YELLOW , @_); }
sub blue    { return &color($BLUE   , @_); }
sub magenta { return &color($MAGENTA, @_); }
sub cyan    { return &color($CYAN   , @_); }

# Console::info(level, format, ...)
# Console::note(format, ...)
# Console::warn(format, ...)
# Console::error(format, ...)
#
# Verbosity controlled session messaging methods that print to STDERR instead of
# STDOUT.
#
# INFO  - normal text, custom verbosity level.
# NOTE  - normal text, normal verbosity level.
# WARN  - yellow text, always shown.
# ERROR - red text   , always shown, exiting (unless testing).
#
sub info    { my $level = shift; &stderr(        "** INFO  : %s\n", sprintf(shift, @_) ) if $VERBOSITY >= $level;  }
sub note    {                    &stderr(        "** NOTE  : %s\n", sprintf(shift, @_) ) if $VERBOSITY >= $NORMAL; }
sub warn    {                    &stderr(&yellow("** WARN  : %s\n", sprintf(shift, @_)));                          }
sub error   {                    &stderr(&red   ("** ERROR : %s\n", sprintf(shift, @_))); exit unless $TESTING;    }



1;

use lib ("$ENV{TEXTBOOKS}/lib");
use Source();
use Draw();
use Console();

$Console::TESTING = 1;

describe("Source", sub {

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Variable
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Variable", sub {

		$ENV{HELLO} = "hello";

		describe("::expansion", sub {

			it("returns a environment variable name to value mapping from a string", sub {
				my $expansion = Variable::expansion('/A/$HELLO/world/example');
				expect($expansion->{HELLO}, "hello");

				my $expansion = Variable::expansion('/A/${HELLO}/world/example');
				expect($expansion->{HELLO}, "hello");
			});

			it("throws an error if the environment variable is not defined", sub {
				my $expansion = Variable::expansion('/A/hello/$WORLD/example');
				expect(Console::stderr, "\e[31m** ERROR : Environment variable WORLD is not set.\e[0m\n");
			});

		});

		describe("::expand", sub {

			it("returns a string with variable names replaced with variable values", sub {
				expect(Variable::expand('$HELLO world'), "hello world");
			});

			it("can be passed a expansion mapping", sub {
				expect(Variable::expand('$HELLO world', {HELLO => 'hi'}), "hi world");
			});

			it("uses global replacement", sub {
				expect(Variable::expand('$HELLO ${HELLO}'), "hello hello");
			});
		
		});

		describe("::contract", sub {

			it("returns a string with variable values replaced with variable names", sub {
				expect(Variable::contract('hello world', {HELLO => 'hello'}), '${HELLO} world');
			});

			it("uses global replacement", sub {
				expect(Variable::contract('hello hello', {HELLO => 'hello'}), '${HELLO} ${HELLO}');
			});

		});

	}); # Variable

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Line
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Line", sub {

		my $Line = new Line('${TEXTBOOKS}/test/test.txt', 2, "test line text");

		describe("new", sub {

			it("returns a new Line instance", sub {
				expect(ref $Line, "Line");
			});

			it("is an overloaded string", sub {
				expect("$Line", "test line text");
			});

			it("falls back on \$_", sub {
				$_ = "line text";
				my $Line = new Line('test.txt', 15);
				expect($Line->string, "line text");
			});
		
		});

		describe(".file", sub {

			it("returns the file name of the Line", sub {
				expect($Line->file, '${TEXTBOOKS}/test/test.txt');
			});

		});

		describe(".number", sub {

			it("returns the line number of the Line", sub {
				expect($Line->number, 2);
			});

		});

		describe(".string", sub {

			it("returns the text of the Line", sub {
				expect($Line->string, "test line text");
			});

		});

		describe(".csv", sub {

			it("returns a list of values split by comma", sub {
				my $Line   = new Line('test.csv', 5, ' simple , csv, data value');
				my @values = $Line->csv;
				expect($values[0], 'simple');
				expect($values[1], 'csv');
				expect($values[2], 'data value');
			});

			it("handles missing values", sub {
				my $Line   = new Line('test.csv', 5, ' missing ,, data value');
				my @values = $Line->csv;
				expect($values[0], 'missing');
				expect($values[1], '');
				expect($values[2], 'data value');
			});

			it("handles a missing value at the end", sub {
				my $Line   = new Line('test.csv', 5, 'missing  , data value,');
				my @values = $Line->csv;
				expect($values[0], 'missing');
				expect($values[1], 'data value');
				expect($values[2], '');
			});

			it("handles embedded commas", sub {
				my $Line   = new Line('test.csv', 5, 'embedded, "comma (,)", data value');
				my @values = $Line->csv;
				expect($values[0], 'embedded');
				expect($values[1], '"comma (,)"');
				expect($values[2], 'data value');
			});

		});

		describe(".coord", sub {

			it("returns the file name and line number of the Line", sub {
				expect($Line->coord, '<${TEXTBOOKS}/test/test.txt:2>');
			});

		});

	}); # Line

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Source
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Source", sub {

		describe("::open & ::close", sub {

			it("throws an error of the file can not be written", sub {
				Source::open('${TEXTBOOKS}/testing/test');
				expect(Console::stderr, "\e[31m** ERROR : Can't open \${TEXTBOOKS}/testing/test for writing: No such file or directory\e[0m\n");
			});

			it("opens and selects a file for output, then closes and deselects the file", sub {
				my $write = "This is a test\n";
				
				# Note environment variable name in file name
				Source::open('${TEXTBOOKS}/test/test.txt');
				print($write);
				Source::close();

				my $ok = open(TEST, "$ENV{TEXTBOOKS}/test/test.txt");
				if ($ok) {
					my @lines = <TEST>; my $read = join('', @lines);
					close(TEST);
					expect($read, $write);
					unlink "$ENV{TEXTBOOKS}/test/test.txt";
				} else {
  					fail('${TEXTBOOKS}/test/test.txt does not exist');
				}
			});

		});

		describe("::glob", sub {

			it("returns a list of files", sub {
				# Note environment variable name in glob is returned in results
				my @actual   = Source::glob('${TEXTBOOKS}/lib/*.pm');
				my @expected = glob("$ENV{TEXTBOOKS}/lib/*.pm");

				expect(scalar @actual, scalar @expected);
				for(my $i=0; $i<scalar @expected; $i++) {
					$expected[$i] =~ s/$ENV{TEXTBOOKS}/\${TEXTBOOKS}/;
					expect($actual[$i], $expected[$i]);
				}
			});

		});

		describe("::line", sub {

			it("returns the lines of a file as an array of Line objects", sub {
				
				Source::open('$TEXTBOOKS/test/test.txt');
				printf($DOUBLE::BANNER, "Test");
				print("ASSET\n");
				print($SINGLE::LINE);
				print("\n\n");
				print("LIABILITY\n");
				print($SINGLE::LINE);
				print("\n\n");
				Source::close();

				my @Lines = Source::line('$TEXTBOOKS/test/test.txt');
				expect(scalar @Lines, 2);
				expect("$Lines[0]", "ASSET");
				expect("$Lines[1]", "LIABILITY");
				expect($Lines[0]->coord, '<$TEXTBOOKS/test/test.txt:8>');
				expect($Lines[1]->coord, '<$TEXTBOOKS/test/test.txt:12>');

				unlink "$ENV{TEXTBOOKS}/test/test.txt";

			});

		});

	}); # Source

});

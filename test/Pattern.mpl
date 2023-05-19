use lib ("$ENV{TEXTBOOKS}/lib");
use Pattern();
use Data::Dumper;

$FILE = <<'_';
| A & B B
| C & !D
| E & !F
_

describe("Pattern", sub {

	#───────────────────────────────────────────────────────────────────────────────────────────
	# New
	#───────────────────────────────────────────────────────────────────────────────────────────

	describe("new", sub {

		it("constructs a disjunction of conjunctions", sub {
			$pattern = new Pattern('A & B & C');
			expect($pattern->string, "| A & B & C\n");
		});

	});

	#───────────────────────────────────────────────────────────────────────────────────────────
	# Input
	#───────────────────────────────────────────────────────────────────────────────────────────

	describe(".parse", sub {

		it("constructs a disjuction of conjunctions line by line", sub {
			$file = new Pattern();
			$file->parse("| A");
			$file->parse("& B B");
			$file->parse("| C &");
			$file->parse("!D");
			$file->parse("| E & !F");
			expect($file->string, $FILE);
		});

	});

	describe(".term", sub {

		it("constructs a disjuction of conjunctions by command line arguments", sub {
			$cmd  = new Pattern();

			$cmd->term("A");
			$cmd->term("+B B");
			$cmd->term("C", "~D", "^E-F");
			expect($cmd->string, $FILE);
		});

		it("has the correct semantics for command line use", sub {
			$cmd = new Pattern();
			$cmd->term("SHELL", "PETROCAN", "ESSO", "~EXPRESSO");
			expect($cmd->string, "| SHELL\n| PETROCAN\n| ESSO & !EXPRESSO\n");
		});

	});

	#───────────────────────────────────────────────────────────────────────────────────────────
	# Output
	#───────────────────────────────────────────────────────────────────────────────────────────

	describe(".string", sub {

		it("outputs the Pattern in a parsable format", sub {
			$p = new Pattern();
			$p->parse($FILE);
			expect($p->string, $FILE);
		});

	});

	#───────────────────────────────────────────────────────────────────────────────────────────
	# Functional
	#───────────────────────────────────────────────────────────────────────────────────────────

	describe(".append", sub {

		it("appends a new Pattern to an existing Pattern", sub {
			my $p = new Pattern("PETROCAN", "ESSO", "!EXPRESSO");
			expect($p->string, "| PETROCAN\n| ESSO & !EXPRESSO\n");

			my $a = new Pattern("SHELL", "ULTRAMAR");
			expect($a->string, "| SHELL\n| ULTRAMAR\n");

			$p->append($a);
			expect($p->string, "| PETROCAN\n| ESSO & !EXPRESSO\n| SHELL\n| ULTRAMAR\n");
		});

	});

	describe(".amend", sub {

		it("updates a conjunctive term", sub {
			my $p = new Pattern("PETROCAN", "ESSO", "SHELL", "ULTRAMAR");
			expect($p->string, "| PETROCAN\n| ESSO\n| SHELL\n| ULTRAMAR\n");

			my $c0 = new Pattern("ESSO", "!ESPRESSO");
			expect($c0->string, "| ESSO & !ESPRESSO\n");

			$p->amend($c0);
			expect($p->string, "| PETROCAN\n| ESSO & !ESPRESSO\n| SHELL\n| ULTRAMAR\n");

			my $c1 = new Pattern("ESSO", "!IMPRESSO");
			expect($c1->string, "| ESSO & !IMPRESSO\n");

			$p->amend($c1);
			expect($p->string, "| PETROCAN\n| ESSO & !ESPRESSO & !IMPRESSO\n| SHELL\n| ULTRAMAR\n");
		});

	});

	describe(".excludes", sub {
		
		$p = new Pattern();

		it("returns undef when no exlusion terms are defined", sub {
			expect($p->excludes("Income:Dave")  , undef);
			expect($p->excludes("Income:Karyn") , undef);
			expect($p->excludes("Income:Emma")  , undef);
			expect($p->excludes("Income:Bryce") , undef);
			expect($p->excludes("Expense:Bryce"), undef);
		});

		it("returns a highlighted string when the string matches the exclusion pattern", sub {
			$p->parse("!Da & !Ka & !Br");
			expect($p->excludes("Income:Dave")  , "Income:\e[31mDa\e[0mve"  );
			expect($p->excludes("Income:Karyn") , "Income:\e[31mKa\e[0mryn" );
			expect($p->excludes("Income:Bryce") , "Income:\e[31mBr\e[0myce" );
			expect($p->excludes("Expense:Bryce"), "Expense:\e[31mBr\e[0myce");
		});

		it("returns undef when the string does not match the exclusion pattern", sub {
			expect($p->excludes("Income:Emma"), undef);
		});

	});

	describe(".includes", sub {

		$p = new Pattern();

		it("returns the string when no inclusion terms are defined", sub {
			expect($p->includes("Income:Dave")  , "Income:Dave"  );
			expect($p->includes("Income:Karyn") , "Income:Karyn" );
			expect($p->includes("Income:Emma")  , "Income:Emma"  );
			expect($p->includes("Income:Bryce") , "Income:Bryce" );
			expect($p->includes("Expense:Bryce"), "Expense:Bryce");
		});

		it("returns a highlighted string when the string matches the inclusion pattern", sub {
			$p->parse("Inc & Da | Inc & Ka");
			expect($p->includes("Income:Dave")  , "\e[32mInc\e[0mome:\e[32mDa\e[0mve"  );
			expect($p->includes("Income:Karyn") , "\e[32mInc\e[0mome:\e[32mKa\e[0mryn" );
		});

		it("returns undef when the string does not match the inclusion pattern", sub {
			expect($p->includes("Income:Emma")  , undef);
			expect($p->includes("Income:Bryce") , undef);
			expect($p->includes("Expense:Bryce"), undef);
		});

	});

	describe(".matches", sub {

		$p = new Pattern();

		it("returns the string when no terms are defined", sub {
			expect($p->matches("Income:Dave")  , "Income:Dave"  );
			expect($p->matches("Income:Karyn") , "Income:Karyn" );
			expect($p->matches("Income:Bryce") , "Income:Bryce" );
			expect($p->matches("Income:Emma")  , "Income:Emma"  );
			expect($p->matches("Expense:Bryce"), "Expense:Bryce");
		});

		it("returns a highlighted string when the string matches the pattern", sub {
			$p->parse("Inc & !Ka & !Em");
			expect($p->matches("Income:Dave") , "\e[32mInc\e[0mome:Dave" );
			expect($p->matches("Income:Bryce"), "\e[32mInc\e[0mome:Bryce");
		});

		it("returns undef when the string does not match the pattern", sub {
			expect($p->matches("Income:Karyn") , undef);
			expect($p->matches("Income:Emma")  , undef);
			expect($p->matches("Expense:Bryce"), undef);
		});

	});

	describe(".terms", sub {

		it("returns false if the pattern has no terms", sub {
			$p = new Pattern();
			expect($p->terms(), undef);
		});

		it("returns true if the pattern has terms", sub {
			$p = new Pattern("test");
			expect($p->terms(), 1);
		});

	});

});

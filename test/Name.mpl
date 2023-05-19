use lib ("$ENV{TEXTBOOKS}/lib");
use Name();

describe("Name", sub {

	describe(".matches", sub {

		my $name = new Name('In:Da');

		it("returns a highlighted string when the string matches the pattern", sub {
			my $expected = "\e[32mIn\e[0mcome:\e[32mDa\e[0mve";
			expect($name->matches("Income:Dave"), $expected);
		});

		it("is case insensitive", sub {
			my $expected = "prefix:w\e[32min\e[0mning:ra\e[32mda\e[0mr:suffix";
			expect($name->matches("prefix:winning:radar:suffix"), $expected);
		});

		it("separates match sections with the colon", sub {
			my $expected = "prefixda:w\e[32min\e[0mwodam:ra\e[32mda\e[0mr:suffix";
			expect($name->matches("prefixda:winwodam:radar:suffix"), $expected);
		});

		it("returns undef when the string does not match the pattern", sub {
			expect($name->matches("Expense:Dave")  , undef);   # not present
			expect($name->matches("Dave:Income")   , undef);   # wrong order
			expect($name->matches("Noindacation")  , undef);   # no hierarchy
			expect($name->matches("inda:same:part"), undef);   # same level
		});

	});

	describe(".string", sub {

		it("returns the pattern", sub {
			my $pattern = "hello:world";
			my $name = new Name($pattern);
			expect($name->string, $pattern);
		});

	});

});

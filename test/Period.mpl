use lib ("$ENV{TEXTBOOKS}/lib");
use Period();

describe("Period", sub {

	describe("new", sub {

		it("expands a single year to be from Jan 1 to Dec 31", sub {
			$p = new Period("2019");
			expect($p->string,  "2019-01-01:2019-12-31");
		});

		it("expands a single month be from day 1 to day 31", sub {
			$p = new Period("2019-02");
			expect($p->string, "2019-02-01:2019-02-31");
		});

		it("expands a single day to be only the day", sub {
			$p = new Period("2019-02-25");
			expect($p->string, "2019-02-25:2019-02-25");
		});

		it("expands a the start and end date independently", sub {
			$p = new Period("2019:2020");
			expect($p->string, "2019-01-01:2020-12-31");
			$p = new Period("2019:2020-11");
			expect($p->string, "2019-01-01:2020-11-31");
			$p = new Period("2019:2020-11-14");
			expect($p->string, "2019-01-01:2020-11-14");

			$p = new Period("2019-03:2020");
			expect($p->string, "2019-03-01:2020-12-31");
			$p = new Period("2019-03:2020-11");
			expect($p->string, "2019-03-01:2020-11-31");
			$p = new Period("2019-03:2020-11-14");
			expect($p->string, "2019-03-01:2020-11-14");

			$p = new Period("2019-03-08:2020");
			expect($p->string, "2019-03-08:2020-12-31");
			$p = new Period("2019-03-08:2020-11");
			expect($p->string, "2019-03-08:2020-11-31");
			$p = new Period("2019-03-08:2020-11-14");
			expect($p->string, "2019-03-08:2020-11-14");
		});

	});

	describe(".contains", sub {

		$p = new Period("2020-05");

		it("returns false for any day before the period", sub {
			expect($p->contains("2019-05-15"), undef);
		});

		it("returns false for the day before the period", sub {
			expect($p->contains("2020-04-30"), undef);
		});

		it("returns true for the first day of the period", sub {
			expect($p->contains("2020-05-01"), 1);
		});

		it("returns true for any day in the period", sub {
			expect($p->contains("2020-05-15"), 1);
		});

		it("returns true for the last day of the period", sub {
			expect($p->contains("2020-05-31"), 1);
		});

		it("returns false for the day after the period", sub {
			expect($p->contains("2020-06-01"), undef);
		});

		it("returns false for any day after the period", sub {
			expect($p->contains("2021-05-15"), undef);
		});

	});

	describe(".overlaps", sub {

		$p = new Period("2020-05");

		it("returns false for a period completely before", sub {
			expect($p->overlaps(new Period("2019")), undef);
		});

		it("returns false for a period immediately before", sub {
			expect($p->overlaps(new Period("2020-04")), undef);
		});

		it("returns true when it is completely contained", sub {
			expect($p->overlaps(new Period("2020")), 1);
		});

		it("returns true when it has leading overlap", sub {
			expect($p->overlaps(new Period("2020-04-15:2020-05-01")), 1);
		});

		it("returns true when it completely contains", sub {
			expect($p->overlaps(new Period("2020-05-05:2020-05-25")), 1);
		});

		it("returns true when it has trailing overlap", sub {
			expect($p->overlaps(new Period("2020-05-31:2020-06-15")), 1);
		});

		it("returns false for a period immediately after", sub {
			expect($p->overlaps(new Period("2020-06")), undef);
		});

		it("returns false for a period complete after", sub {
			expect($p->overlaps(new Period("2021")), undef);
		});

	});

	describe(".string", sub {

		it("returns the Period in a readable & parsable format", sub {
			$p = new Period("2019");
			expect($p->string, "2019-01-01:2019-12-31");
			$q = new Period($p->string);
			expect($q->string, "2019-01-01:2019-12-31");
		});

	});

});

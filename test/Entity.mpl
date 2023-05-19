use lib ("$ENV{TEXTBOOKS}/lib");
use Allocation();
use Entity();
use Console();
use Name();
use Pattern();
use Period();

$Console::TESTING = 1;

sub expect_stdout {
	my $expected = shift;
	my $actual   = Console::stdout;
	return expect($actual, $expected) if defined $expected;
	print($actual);
}

sub expect_stderr {
	my $expected = shift;
	my $actual   = Console::stderr;
	return expect($actual, $expected) if defined $expected;
	print($actual);
}

sub xpect_stdout { diff(Console::stdout, shift); }
sub xpect_stderr { diff(Console::stderr, shift); }


# sub getBankRecordTestEntity {
# 	my $Entity = new Entity();
# 	my $JCHQ   = $Entity->createAccount('ASSET'    , 'JCHQ', undef, 'JCHQ');
# 	my $HLOC   = $Entity->createAccount('LIABILITY', 'HLOC', undef, 'HLOC');
# 	$Entity->createImportRule('JCHQ', '${ACCOUNTING}/assets/JCHQ/*2013*.csv'     );
# 	$Entity->createImportRule('HLOC', '${ACCOUNTING}/liabilities/HLOC/*2013*.csv');
# 	expect(scalar $JCHQ->Actions,   0);
# 	expect(scalar $HLOC->Actions,   0);
# 	$Entity->createRecords();
# 	expect(scalar $JCHQ->Actions, 592);
# 	expect(scalar $HLOC->Actions,  25);
# 	return ($Entity, $JCHQ, $HLOC);
# }

sub allocTestEntity {
	my $Entity  = new Entity();
	my %options = @_;

	my $Assets  = $Entity->createAccount('A', 10, undef   , 'Assets' );
	my $CHQ     = $Entity->createAccount('A', 11, $Assets , 'CHQ'    );
	my $Income  = $Entity->createAccount('I', 30, undef   , 'Income' );
	my $Dave    = $Entity->createAccount('I', 31, $Income , 'Dave'   );
	my $Expense = $Entity->createAccount('E', 40, undef   , 'Expense');
	my $Food    = $Entity->createAccount('E', 41, $Expense, 'Food'   );
	my $Fees    = $Entity->createAccount('E', 42, $Expense, 'Fees'   );

	$Entity->createImportRule('CHQ', '${ACCOUNTING}/assets/DCHQ/*2014*.csv');

	$Entity->createRecords() if $options{import};

	if ($options{rules}) {
		my $IncomeAlloc = new Allocation();

		$IncomeAlloc->item('PTS FRM')->to('Dave');

		$Entity->updateAllocationRule($IncomeAlloc);

		my $FoodAlloc = new Allocation();
		$FoodAlloc->item('TIM HORTON | MCDONALD | HARVEY | SHAWARMA HOUSE | MUCHO BURRITO | QUIZNOS | PANERA BREAD | A . W');
		$FoodAlloc->item('^PHO KAM LONG | SUKHOTHAI | LONE STAR | THE GREEN DOOR | MAPLE COURT');
		$FoodAlloc->item('^THE BARLEY MOW | ROYAL OAK | BLADES BAR | THE DRAFT');
		# $FoodAlloc->item('^METRO | FARM BOY');
		$FoodAlloc->to('Food');

		$Entity->updateAllocationRule($FoodAlloc);

		my $FeeAlloc = new Allocation();
		$FeeAlloc->item('FEE | OVERDRAFT')->to('Fees');

		$Entity->updateAllocationRule($FeeAlloc);
	}

	$Entity->createAllocations() if $options{allocate};

	Console::stdout;
	Console::stderr;

	return $Entity;
}


describe("Entity", sub {

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Persistence
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Persistence", sub {

		my $Entity      = new Entity();
		my $Assets      = $Entity->createAccount("A", 10000, undef   , "Assets"     );
	    my $Liabilities = $Entity->createAccount("L", 20000, undef   , "Liabilities");
		my $Income      = $Entity->createAccount("I", 30000, undef   , "Income"     );
		my $Pay         = $Entity->createAccount("I", 31000, $Income , "Pay"        );
		my $Expense     = $Entity->createAccount("E", 40000, undef   , "Expense"    );
		my $Food        = $Entity->createAccount("E", 41000, $Expense, "Food"       );
		my $Fees        = $Entity->createAccount("E", 42000, $Expense, "Fees"       );

		describe(".get", sub {

			it("can construct a memory resident Entity from a file", sub {
				$Entity->put(file => "test.gl");
				expect_stdout("");
				expect_stderr("** NOTE  : Writing test.gl\n");
				my $Read = get Entity "test.gl";
				expect($Read->put(string => 1), $Entity->put(string => 1));
				unlink "test.gl" if -e "test.gl";
			});

			it("can populate a memory resident Entity from the entity file", sub {
				my $Read = new Entity("test.gl");
				$Entity->put(file => "test.gl");
				expect_stdout("");
				expect_stderr("** NOTE  : Writing test.gl\n");
				$Read->get();
				expect($Read->put(string => 1), $Entity->put(string => 1));
				unlink "test.gl" if -e "test.gl";
			});

			it("can populate a memory resident Entity from a file", sub {
				my $Read = new Entity();
				$Entity->put(file => "test.gl");
				expect_stdout("");
				expect_stderr("** NOTE  : Writing test.gl\n");
				$Read->get(file => "test.gl");
				expect($Read->put(string => 1), $Entity->put(string => 1));
				unlink "test.gl" if -e "test.gl";
			});

			it("can populate a memory resident Entity from a string", sub {
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string => 1), $Entity->put(string => 1));
			});

			it("does nothing when there is no input", sub {
				my $Read = new Entity();
				$Read->get(string => "");
				expect($Read->put(string => 1), "");
				$Read->get();
				expect($Read->put(string => 1), "");
			});

		});

		describe(".put", sub {

			it("can output the memory resident Entity to STDOUT", sub {
				unlink "test.gl" if -e "test.gl";
				open(FILE, ">test.gl") or &fail("Can't open test.gl");
				select(FILE);
				$Entity->put();
				close(FILE);
				select(STDOUT);
				expect(-e "test.gl", 1);
				unlink "test.gl" if -e "test.gl";
			});

			it("can output the memory resident Entity to a file", sub {
				unlink "test.gl" if -e "test.gl";
				$Entity->put(file => "test.gl");
				expect_stdout("");
				expect_stderr("** NOTE  : Writing test.gl\n");
				unlink "test.gl" if -e "test.gl";
			});

			it("can output the memory resident Entity to the entity file", sub {
				unlink "test.gl" if -e "test.gl";
				$Entity->{file} = "test.gl";
				$Entity->put(commit => 1);
				expect(-e "test.gl", 1);
				$Entity->{file} = undef;
				unlink "test.gl" if -e "test.gl";
			});

			it("can output the memory resident Entity to a string", sub {
				expect($Entity->put(string => 1), <<"_"
ASSET        10000         Assets
────────────────────────────────────────────────────────────────────────────────────────────────────


LIABILITY    20000         Liabilities
────────────────────────────────────────────────────────────────────────────────────────────────────


INCOME       30000         Income
────────────────────────────────────────────────────────────────────────────────────────


INCOME       31000:30000   Income:Pay
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      40000         Expense
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      41000:40000   Expense:Food
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      42000:40000   Expense:Fees
────────────────────────────────────────────────────────────────────────────────────────


_
				);
			});

		});

	}); # Persistence

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Chart of Accounts
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Chart of Accounts", sub {

		describe(".getAccount", sub {

			it("returns an Account identified by number", sub {
				my $Entity  = new Entity();
				my $Sample  = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test    = $Entity->createAccount("I", 30000, undef, "Test"   );
				my $Account = $Entity->getAccount(20000);
				expect($Account, $Example);
			});

			it("returns an Account identified by Name", sub {
				my $Entity  = new Entity();
				my $Sample  = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test    = $Entity->createAccount("I", 30000, undef, "Test"   );
				my $Account = $Entity->getAccount(new Name("Test"));
				expect($Account, $Test);
			});

			it("returns an Account identified by name", sub {
				my $Entity  = new Entity();
				my $Sample  = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test    = $Entity->createAccount("I", 30000, undef, "Test"   );
				my $Account = $Entity->getAccount("test");
				expect($Account, $Test);
			});

			it("throws an error if no Accounts are identified", sub {
				my $Entity  = new Entity();
				my $Sample  = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test    = $Entity->createAccount("I", 30000, undef, "Test"   );
				Console::stderr;
				expect($Entity->getAccount(40000), undef);
				expect_stderr("\e[31m** ERROR : No accounts identified by '40000'\e[0m\n");
				expect($Entity->getAccount(new Name("Nothing")), undef);
				expect_stderr("\e[31m** ERROR : No accounts identified by 'Nothing'\e[0m\n");
			});

			it("throws an error if too many Accounts are identified", sub {
				my $Entity  = new Entity();
				my $Sample  = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test    = $Entity->createAccount("I", 30000, undef, "Test"   );
				expect($Entity->getAccount(new Name("ample")), undef);
				expect_stderr(<<"_"
\e[31m** ERROR : More than one account identified by 'ample':\e[0m
ASSET        10000         S\e[32mample\e[0m
LIABILITY    20000         Ex\e[32mample\e[0m\e[0m

_
				);
			});

		});

		describe(".getAccounts", sub {

			it("returns the list of Accounts", sub {
				my $Entity      = new Entity();
				my $Assets      = $Entity->createAccount("A", 10000, undef, "Assets"     );
			    my $Liabilities = $Entity->createAccount("L", 20000, undef, "Liabilities");
				my $Income      = $Entity->createAccount("I", 30000, undef, "Income"     );
				my $Expense     = $Entity->createAccount("E", 40000, undef, "Expense"    );
				my @Accounts    = $Entity->getAccounts();

				expect(scalar @Accounts, 4);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );
			});

			it("returns a list of Accounts identified by Name", sub {
				my $Entity   = new Entity();
				my $Sample   = $Entity->createAccount("A", 10000, undef, "Sample" );
				my $Example  = $Entity->createAccount("L", 20000, undef, "Example");
				my $Test     = $Entity->createAccount("I", 30000, undef, "Test"   );
				my @Accounts = $Entity->getAccounts(new Name("ample"));
				expect(scalar @Accounts, 2);
				expect($Accounts[0], $Sample );
				expect($Accounts[1], $Example);
			});

		});

		describe(".createAccount", sub {

			it("adds a new Account to the Entity and returns it", sub {
				my $Entity = new Entity();
				expect(scalar $Entity->getAccounts(), 0);

				my $Assets   = $Entity->createAccount("A", 10000, undef, "Assets");
				my @Accounts = $Entity->getAccounts();
				expect(scalar @Accounts, 1);
				expect($Accounts[0], $Assets);
			});

			it("adds the Account as the last child under it's parent", sub {
				my $Entity      = new Entity();
				my $Assets      = $Entity->createAccount("A", 10000, undef, "Assets"     );
			    my $Liabilities = $Entity->createAccount("L", 20000, undef, "Liabilities");
				my $Income      = $Entity->createAccount("I", 30000, undef, "Income"     );
				my $Expense     = $Entity->createAccount("E", 40000, undef, "Expense"    );
				my @Accounts    = $Entity->getAccounts();

				expect(scalar @Accounts, 4);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );

				my $Activities = $Entity->createAccount("E", 41000, $Expense, "Activities");
				@Accounts = $Entity->getAccounts();
				expect(scalar @Accounts, 5);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );
				expect($Accounts[4], $Activities );

				my $Food = $Entity->createAccount("E", 42000, $Expense, "Food");
				@Accounts = $Entity->getAccounts();
				expect(scalar @Accounts, 6);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );
				expect($Accounts[4], $Activities );
				expect($Accounts[5], $Food       );

				my $Hockey = $Entity->createAccount("E", 41100, $Activities, "Hockey");
				@Accounts = $Entity->getAccounts();
				expect(scalar @Accounts, 7);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );
				expect($Accounts[4], $Activities );
				expect($Accounts[5], $Hockey     );
				expect($Accounts[6], $Food       );

				my $Skiing = $Entity->createAccount("E", 41200, $Activities, "Skiing");
				@Accounts = $Entity->getAccounts();
				expect(scalar @Accounts, 8);
				expect($Accounts[0], $Assets     );
				expect($Accounts[1], $Liabilities);
				expect($Accounts[2], $Income     );
				expect($Accounts[3], $Expense    );
				expect($Accounts[4], $Activities );
				expect($Accounts[5], $Hockey     );
				expect($Accounts[6], $Skiing     );
				expect($Accounts[7], $Food       );
			});

		});

		describe(".readAccounts", sub {

			it("returns the list of Accounts as a multi-line string", sub {
				my $Entity = new Entity();
				$Entity->createAccount("A", 10000, undef, "Assets"     );
				$Entity->createAccount("L", 20000, undef, "Liabilities");
				$Entity->createAccount("I", 30000, undef, "Income"     );
				$Entity->createAccount("E", 40000, undef, "Expense"    );
				expect($Entity->readAccounts, <<"_"
ASSET        10000         Assets
LIABILITY    20000         Liabilities
INCOME       30000         Income
EXPENSE      40000         Expense
_
				);
			});

			it("returns a filtered list of Accounts as a multi-line string if a Name is supplied", sub {
				my $Entity = new Entity();
				$Entity->createAccount("A", 10000, undef, "Assets"     );
				$Entity->createAccount("L", 20000, undef, "Liabilities");
				$Entity->createAccount("I", 30000, undef, "Income"     );
				$Entity->createAccount("E", 40000, undef, "Expense"    );
				expect($Entity->readAccounts(Name => new Name("s")), <<"_"
ASSET        10000         A\e[32ms\e[0msets
LIABILITY    20000         Liabilitie\e[32ms\e[0m
EXPENSE      40000         Expen\e[32ms\e[0me
_
				);
			});

			it("returns a highlighted list of Accounts when passed a number", sub {
				my $Entity = new Entity();
				$Entity->createAccount("A", 10000, undef, "Assets"     );
				$Entity->createAccount("L", 20000, undef, "Liabilities");
				$Entity->createAccount("I", 30000, undef, "Income"     );
				$Entity->createAccount("E", 40000, undef, "Expense"    );
				expect($Entity->readAccounts(number => 20000), <<"_"
ASSET        10000         Assets
\e[32mLIABILITY    20000         Liabilities\e[0m
INCOME       30000         Income
EXPENSE      40000         Expense
_
				);
			});

		});

		describe(Console::cyan(".chart"), sub {

			my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";

			Console::stdout;
			Console::stderr;

			it("shows a chart of accounts", sub {
				$Entity->chart();
				expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Food
EXPENSE      42000:40000   Expense:Bank Fees
_
				);
				expect_stderr("");
			});

			it("shows a chart of accounts filtered by name", sub {
				$Entity->chart("Ex:F");
				expect_stdout(<<"_"
EXPENSE      41000:40000   \e[32mEx\e[0mpense:\e[32mF\e[0mood
EXPENSE      42000:40000   \e[32mEx\e[0mpense:Bank \e[32mF\e[0mees
_
				);
 				expect_stderr("");
			});

			it("can add asset accounts", sub {
				foreach my $type ("--asset", "-a") {
					my $parent = ($type =~ /^--/) ? "--parent" : "-p";
					my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
					
					$Entity->chart($type, $parent, 10000, 12000, "Savings Account");
					expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
\e[32mASSET        12000:10000   Assets:Savings Account\e[0m
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Food
EXPENSE      42000:40000   Expense:Bank Fees
_
					);
					expect_stderr("");
				}
			});

			it("can add liability accounts", sub {
				foreach my $type ("--liability", "-l") {
					my $parent = ($type =~ /^--/) ? "--parent" : "-p";
					my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
					
					$Entity->chart($type, $parent, 20000, 22000, "Business Loan");
					expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
\e[32mLIABILITY    22000:20000   Liabilities:Business Loan\e[0m
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Food
EXPENSE      42000:40000   Expense:Bank Fees
_
					);
					expect_stderr("");
				}
			});

			it("can add income accounts", sub {
				foreach my $type ("--income", "-i") {
					my $parent = ($type =~ /^--/) ? "--parent" : "-p";
					my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
					
					$Entity->chart($type, $parent, 30000, 32000, "Interest");
					expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
\e[32mINCOME       32000:30000   Income:Interest\e[0m
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Food
EXPENSE      42000:40000   Expense:Bank Fees
_
					);
					expect_stderr("");
				}
			});

			it("can add expense accounts", sub {
				foreach my $type ("--expense", "-e") {
					my $parent = ($type =~ /^--/) ? "--parent" : "-p";
					my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
					
					$Entity->chart($type, $parent, 40000, 43000, "Activities");
					expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Food
EXPENSE      42000:40000   Expense:Bank Fees
\e[32mEXPENSE      43000:40000   Expense:Activities\e[0m
_
					);
					expect_stderr("");
				}
			});

			it("throws an error if the parent is not uniquely identified", sub {
				$Entity->chart("--expense", "--parent", "Expense", 43000, "Activities");
				expect_stdout("");
				expect_stderr(<<"_"
\e[31m** ERROR : More than one account identified by 'Expense':\e[0m
EXPENSE      40000         \e[32mExpense\e[0m
EXPENSE      41000:40000   \e[32mExpense\e[0m:Food
EXPENSE      42000:40000   \e[32mExpense\e[0m:Bank Fees\e[0m

_
				);
			});

			it("throws an error if the account number is missing", sub {
				$Entity->chart("-i", "-p", 40000);
				expect_stdout("");
				expect_stderr("\e[31m** ERROR : Account number is missing.\e[0m\n");
			});

			it("throws an error if the account name is missing", sub {
				$Entity->chart("-i", "-p", 40000, 43000);
				expect_stdout("");
				expect_stderr("\e[31m** ERROR : Account name is missing.\e[0m\n");
			});

			it("throws an error if the account number is taken", sub {
				$Entity->chart("-i", "-p", 40000, 41000, "Activities");
				expect_stdout("");
				expect_stderr("\e[31m** ERROR : Account number 41000 is Expense:Food.\e[0m\n");
			});

		});

	}); # Chart of Accounts

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Bank Record Import
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Bank Record Import", sub {

		describe(".createImportRule", sub {

			it("adds an import rule to an Account by Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $import = "\${TEXTBOOKS}/test/data/records/*.csv";
				$Entity->createImportRule(new Name("Bank Account"), $import);
				expect($Entity->getAccount("Bank Account")->import, $import);
			});

			it("adds an import rule to an Account by name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $import = "\${TEXTBOOKS}/test/data/records/*.csv";
				$Entity->createImportRule("Loan", $import);
				expect($Entity->getAccount("Loan")->import, $import);
			});

			it("can be output to file", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $import = "\${TEXTBOOKS}/test/data/records/*.csv";
				$Entity->createImportRule(new Name("Bank Account"), $import);
				expect($Entity->put(string => 1), <<"_"
ASSET        10000         Assets
────────────────────────────────────────────────────────────────────────────────────────────────────


ASSET        11000:10000   Assets:Bank Account
────────────────────────────────────────────────────────────────────────────────────────────────────
* \${TEXTBOOKS}/test/data/records/*.csv
────────────────────────────────────────────────────────────────────────────────────────────────────


LIABILITY    20000         Liabilities
────────────────────────────────────────────────────────────────────────────────────────────────────


LIABILITY    21000:20000   Liabilities:Personal Loan
────────────────────────────────────────────────────────────────────────────────────────────────────


INCOME       30000         Income
────────────────────────────────────────────────────────────────────────────────────────


INCOME       31000:30000   Income:Pay
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      40000         Expense
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      41000:40000   Expense:Food
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      42000:40000   Expense:Bank Fees
────────────────────────────────────────────────────────────────────────────────────────


_
				);
			});

			it("can be read from a file", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $import = "\${TEXTBOOKS}/test/data/records/*.csv";
				$Entity->createImportRule(new Name("Bank Account"), $import);
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->readImportRules(rules => 1), <<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.csv
_
				);
			});

		});

		describe(".readImportRules", sub {

			it("returns the list of import rules as a string", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createImportRule("Personal Loan", "\${TEXTBOOKS}/test/data/loan/*.csv");
				expect($Entity->readImportRules(rules => 1), <<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.csv
IMPORT \${TEXTBOOKS}/test/data/loan/*.csv
_
				);
			});

			it("returns the list of import rules filtered by Pattern as a highlighted string", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createImportRule("Personal Loan", "\${TEXTBOOKS}/test/data/loan/*.csv");
				expect($Entity->readImportRules(rules => 1, Pattern => new Pattern("loan")), <<"_"
IMPORT \${TEXTBOOKS}/test/data/\e[32mloan\e[0m/*.csv
_
				);
			});

			it("returns the list of files to import as a string", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				expect($Entity->readImportRules(files => 1), <<"_"
IMPORT \${TEXTBOOKS}/test/data/records/2019-01.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-02.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-03.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-04.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-06.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-07.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-08.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-09.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-10.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-11.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-12.csv
_
				);
			});

			it("returns the list of files to import filtered by Pattern as a highlighted string", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				expect($Entity->readImportRules(files => 1, Pattern => new Pattern(9.1)), <<"_"
IMPORT \${TEXTBOOKS}/test/data/records/201\e[32m9-1\e[0m0.csv
IMPORT \${TEXTBOOKS}/test/data/records/201\e[32m9-1\e[0m1.csv
IMPORT \${TEXTBOOKS}/test/data/records/201\e[32m9-1\e[0m2.csv
_
				);
			});

			it("returns the list of files to import", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my @imports = $Entity->readImportRules;
				expect(scalar @imports, 12);
				expect($imports[0] , "\${TEXTBOOKS}/test/data/records/2019-01.csv");
				expect($imports[1] , "\${TEXTBOOKS}/test/data/records/2019-02.csv");
				expect($imports[2] , "\${TEXTBOOKS}/test/data/records/2019-03.csv");
				expect($imports[3] , "\${TEXTBOOKS}/test/data/records/2019-04.csv");
				expect($imports[4] , "\${TEXTBOOKS}/test/data/records/2019-05.csv");
				expect($imports[5] , "\${TEXTBOOKS}/test/data/records/2019-06.csv");
				expect($imports[6] , "\${TEXTBOOKS}/test/data/records/2019-07.csv");
				expect($imports[7] , "\${TEXTBOOKS}/test/data/records/2019-08.csv");
				expect($imports[8] , "\${TEXTBOOKS}/test/data/records/2019-09.csv");
				expect($imports[9] , "\${TEXTBOOKS}/test/data/records/2019-10.csv");
				expect($imports[10], "\${TEXTBOOKS}/test/data/records/2019-11.csv");
				expect($imports[11], "\${TEXTBOOKS}/test/data/records/2019-12.csv");
			});

			it("returns the list of files to import filtered by Pattern", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my @imports = $Entity->readImportRules(Pattern => new Pattern(9.1));
				expect(scalar @imports, 3);
				expect($imports[0], "\${TEXTBOOKS}/test/data/records/2019-10.csv");
				expect($imports[1], "\${TEXTBOOKS}/test/data/records/2019-11.csv");
				expect($imports[2], "\${TEXTBOOKS}/test/data/records/2019-12.csv");
			});

			it("can filter by account Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createImportRule("Personal Loan", "\${TEXTBOOKS}/test/data/loan/*.csv");
				my @imports = $Entity->readImportRules(Name => new Name("Bank"));
				expect(scalar @imports, 12);
				expect($imports[0] , "\${TEXTBOOKS}/test/data/records/2019-01.csv");
				expect($imports[1] , "\${TEXTBOOKS}/test/data/records/2019-02.csv");
				expect($imports[2] , "\${TEXTBOOKS}/test/data/records/2019-03.csv");
				expect($imports[3] , "\${TEXTBOOKS}/test/data/records/2019-04.csv");
				expect($imports[4] , "\${TEXTBOOKS}/test/data/records/2019-05.csv");
				expect($imports[5] , "\${TEXTBOOKS}/test/data/records/2019-06.csv");
				expect($imports[6] , "\${TEXTBOOKS}/test/data/records/2019-07.csv");
				expect($imports[7] , "\${TEXTBOOKS}/test/data/records/2019-08.csv");
				expect($imports[8] , "\${TEXTBOOKS}/test/data/records/2019-09.csv");
				expect($imports[9] , "\${TEXTBOOKS}/test/data/records/2019-10.csv");
				expect($imports[10], "\${TEXTBOOKS}/test/data/records/2019-11.csv");
				expect($imports[11], "\${TEXTBOOKS}/test/data/records/2019-12.csv");
			});

		});

		describe(".createRecords", sub {

			Console::stderr;
			Console::stdout;

			it("adds bank records as Actions to Accounts", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords();
				expect(scalar $Bank->Actions, 217);
				expect_stdout("");
				expect_stderr("\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m\n");
			});

			it("can filter by account Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				my $Loan   = $Entity->getAccount("Loan");
				$Entity->createImportRule("Loan", "\${TEXTBOOKS}/test/data/records/*.csv");
				expect(scalar $Bank->Actions, 0);
				expect(scalar $Loan->Actions, 0);
				$Entity->createRecords(Name => new Name("Loan"));
				expect(scalar $Bank->Actions, 0);
				expect(scalar $Loan->Actions, 217);
				expect_stdout("");
				expect_stderr("\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 21000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m\n");
			});

			it("can filter by source Pattern", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords(Pattern => new Pattern(9.11));
				expect(scalar $Bank->Actions, 20);
				expect_stdout("");
				expect_stderr("");
			});

			it("can filter by Period", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords(Period => new Period("2019-01:2019-03"));
				expect(scalar $Bank->Actions, 60);
				expect_stdout("");
				expect_stderr("");
			});
			
			it("adds records only once", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords(Period => new Period("2019-01:2019-10"));
				expect(scalar $Bank->Actions, 189);
				expect_stdout("");
				expect_stderr("");
				$Entity->createRecords(Period => new Period("2019-10:2019-12")); # 2013-10 imported again
				expect(scalar $Bank->Actions, 217);
				expect_stdout("");
				expect_stderr("\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m\n");
			});

			it("orders records by date and maintains the correct balance", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords(Period => new Period("2019-10:2019-12"));
				expect(scalar $Bank->Actions, 44);
				expect_stdout("");
				expect_stderr("\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m\n");
				$Entity->createRecords(Period => new Period("2019-01:2019-10"));
				expect(scalar $Bank->Actions, 217);
				expect_stdout("");
				expect_stderr("");

				$date    = undef;
				$balance = undef;
				for my $Action ($Bank->Actions) {
					assert(($Action->date cmp $date) >= 0) if defined $date;
					$date = $Action->date;
					expect(sprintf("%.2f", $balance + $Action->net), $Action->balance) if defined $balance;
					$balance = $Action->balance;
				}
			});

			it("adds records that can be saved to and restored from file", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Bank   = $Entity->getAccount("Bank Account");
				expect(scalar $Bank->Actions, 0);
				$Entity->createRecords();
				expect(scalar $Bank->Actions, 217);
				expect_stdout("");
				expect_stderr("\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m\n");

				my $Clone = new Entity(); $Clone->get(string => $Entity->put(string => 1)); 
				foreach my $Write ($Entity->getAccounts()) {
					my $Read   = $Clone->getAccount($Write->number);
					my @Reads  = $Read->Actions;
					my @Writes = $Write->Actions;
					expect(scalar @Reads, scalar @Writes);
					for(my $i=0; $i<$actions; $i++) {
						expect($Reads[$i]->put, $Writes[$i]->put);
					}
				}
			});

			xit("has multiple levels of verbosity", sub {
				my $Entity = new Entity();
				my $JCHQ   = $Entity->createAccount('ASSET'    , 'JCHQ', undef, 'JCHQ');
				my $HLOC   = $Entity->createAccount('LIABILITY', 'HLOC', undef, 'HLOC');
				$Entity->createImportRule('JCHQ', '${ACCOUNTING}/assets/JCHQ/*2013*.csv'     );
				$Entity->createImportRule('HLOC', '${ACCOUNTING}/liabilities/HLOC/*2013*.csv');
				expect(scalar $JCHQ->Actions,   0);
				expect(scalar $HLOC->Actions,   0);
				
				$Entity->createRecords(verbosity => 1);
				expect(pop @Console::STDERR,"** NOTE  : Importing...\n");
				expect(pop @Console::STDERR,"** NOTE  : Imported \e[32m617\e[0m new transactions\n");
				expect(pop @Console::STDERR, undef);
				expect(Console::stdout,"");

				$Entity->deleteRecords();
				Console::stderr;
				Console::stdout;

				$Entity->createRecords(
					verbosity => 4, 
					pattern   => "!2013.0", 
					name      => "jchq", 
					period    => "2013-10-15:2013-12-15"
				);
				expect_stderr(<<"_"
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m1.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m2.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m3.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m4.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m5.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m6.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m7.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m8.csv
** NOTE  : Skipping  \${ACCOUNTING}/assets/JCHQ/JCHQ_\e[31m2013-0\e[0m9.csv
\e[33m** WARN  : Importing  21 of  45 records into ACCOUNT JCHQ from \${ACCOUNTING}/assets/JCHQ/JCHQ_2013-10.csv.\e[0m
** NOTE  : Importing \e[32m 56\e[0m of  56 records into ACCOUNT JCHQ from \${ACCOUNTING}/assets/JCHQ/JCHQ_2013-11.csv.
\e[33m** WARN  : Importing  23 of  42 records into ACCOUNT JCHQ from \${ACCOUNTING}/assets/JCHQ/JCHQ_2013-12.csv.\e[0m
** NOTE  : Imported \e[32m100\e[0m new transactions
_
				);
				expect_stdout("");
			});

			xit("prompts for clarification when two records have the same date, debit, credit and balance but different items", sub {
				#
				# The underlying issue is how to uniquely identify an import record so it is not imported twice.
				#
				# It can not be by file coordintate because the same records sometimes end up in different files.
                #
				# e.g. In 2014 & 2015 the TD historical account queries returned dates that were not requested.
				#      For example a query for February returned 31 days of records, which results in records
				#      for the first days of March showing up in the February records.  The March query then 
				#      returned those same records so they appear in two files.
				#
				#      THERE ARE MANY INSTANCES OF THIS CASE AND THEY HAVE NOT BEEN FIXED IN THE RECORDS.
				#
				# So record identification must come purely from the content of the record.
				#
				# It can not include the item because the same records sometimes have different items.
				#
				# e.g. In May of 2017 TD account records switched from providing complete transfer codes to 
				#      masked transfer codes.  Records downloaded before the switch had complete codes, while
				#      records downloaded after had masked codes:
				#
                #      JCHQ_20151114_20170514.csv:01/20/2017,E TFR C0mmeTbg,70.00,,10807.67  // As of May 14, 2017
                #      JCHQ_2017.csv             :01/20/2017,E TFR C0***Tbg,70.00,,10807.67  // As of Dec 31, 2017
                #
                #      The "tally" script was also created in 2017.  Part of it's downfall was the inability
                #      to have one time allocations.  To get around this limitation, the records were "tagged"
                #      so they could be picked up by a pattern:
                # 
                #      JCHQ_20151114_20170514.csv:01/20/2017,E TFR C0mmeTbg         ,70.00,,10807.67  // As of May 14, 2017
                #      JCHQ_2017.csv             :01/20/2017,E TFR C0***Tbg :DAYCARE,70.00,,10807.67  // As of Dec 31, 2017
                #
                #      THESE HAVE NOW BEEN RESOLVED BY CHANGING THE RECORDS TO ALL HAVING A COMMON 
                #      ITEM WITH THE MOST DETAIL.
                #
                # So it must be date, debit, credit and balance, with the balance being an import element
                # since it quite forseable that the same change amount happens multiple times per day (e.g.
                # buy one item, opps, buy a second one.)
                #
                # However even this identification is not perfect:
                #
				# JCHQ_2009-10.csv:10/26/2009,UY520 TFR-TO 3228018,10725.00,        , 7288.58
				# JCHQ_2009-10.csv:10/26/2009,UY535 TFR-FR 3228018,        ,10725.00,18013.58
				# JCHQ_2009-10.csv:10/26/2009,LN PYMT    325385801,10725.00,        , 7288.58  <<< Collision!
				#
				# This loan payment was paid from the JCHQ account, but put through the ILOC account
				# first to record that it should now be tax deductable interest.
				#
				# In 8000 records, however, there are only two of these cases that are easily manually verified.
				#
				# The moral is that each of these cases requires manual intervention to resolve.
				#
				# The manual intervention has been tested manually.
				my $Entity = new Entity();
				my $JCHQ   = $Entity->createAccount('ASSET'    , 'JCHQ', undef, 'JCHQ');
				my $HLOC   = $Entity->createAccount('LIABILITY', 'HLOC', undef, 'HLOC');
				$Entity->createImportRule('JCHQ', '${ACCOUNTING}/assets/JCHQ/*.csv'     );
				$Entity->createImportRule('HLOC', '${ACCOUNTING}/liabilities/HLOC/*.csv');
				expect(scalar $JCHQ->Actions, 0);
				expect(scalar $HLOC->Actions, 0);

				# Scenario 1: Records bleed from one month to the next.  The warning for 2015-03
				#             comes from the fact that the first record is not imported because
				#             it was already imported at the end of 2015-02.
				$Entity->createRecords(name => 'HLOC', period => "2015-02:2015-05");
				expect_stderr(<<"_"
\e[33m** WARN  : Importing   2 of   3 records into ACCOUNT HLOC from \${ACCOUNTING}/liabilities/HLOC/HLOC_2015-03.csv.\e[0m
\e[33m** WARN  : Importing  12 of  13 records into ACCOUNT HLOC from \${ACCOUNTING}/liabilities/HLOC/HLOC_2015-04.csv.\e[0m
\e[33m** WARN  : Importing  10 of  11 records into ACCOUNT HLOC from \${ACCOUNTING}/liabilities/HLOC/HLOC_2015-05.csv.\e[0m
_
				);
				expect(Console::stdout,"");

				# Scenario 2: Is this the same record with different items or two different items
				#             with the same date, debit, credit and balance?  This instance is
				#             a case where two different records have the same date, debit
				#             credit and balance.
				Console::stdin("i");
				$Entity->createRecords(name=> 'JCHQ', period => "2009-10");
				expect_stderr(<<"_"
\e[33m** WARN  : The record on 2009-10-26 at <\${ACCOUNTING}/assets/JCHQ/JCHQ_2009-10.csv:43> has an item collision\e[0m
Existing : UY520 TFR-TO 3228018
Current  : LN PYMT 325385801
[\e[32mk\e[0m]eep existing / [\e[32mu\e[0m]pdate to current / [\e[32mi\e[0m]mport ?
>>>** NOTE  : \e[32mImporting LN PYMT 325385801\e[0m
_
				);
				expect(Console::stdout,"");

				# Scenario 3: Is this the same record with different items or two different items
				#             with the same date, debit, credit and balance.  This instance is
				#             a case where the same record has two different items.
				Console::stdin("k");
				$Entity->createRecords(name=> 'JCHQ', period => "2017-01");
				expect_stderr(<<"_"
\e[33m** WARN  : Importing  43 of 940 records into ACCOUNT JCHQ from \${ACCOUNTING}/assets/JCHQ/JCHQ_20151114_20170514.csv.\e[0m
\e[33m** WARN  : The record on 2017-01-20 at <\${ACCOUNTING}/assets/JCHQ/JCHQ_2017.csv:31> has an item collision\e[0m
Existing : E TFR C0mmeTbg :DAYCARE
Current  : E TFR C0***Tbg :DAYCARE
[\e[32mk\e[0m]eep existing / [\e[32mu\e[0m]pdate to current / [\e[32mi\e[0m]mport ?
>>>** NOTE  : \e[32mKeeping E TFR C0mmeTbg :DAYCARE\e[0m
_
				);
				expect(Console::stdout,"");

				# Thought - Scenario 2 & 3 can be sorted out by the records before (and after), which
				# is kind of like a diff.
			});

		});

		describe(".readRecords", sub {

			Console::stderr;
			Console::stdout;

			it("displays imported records", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createRecords(Period => new Period("2019-10"));

				$Entity->readRecords();
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-10-03 THAI                                             │            │      11.50 │
2019-10-06 GROCERY STORE                                    │            │       3.76 │
2019-10-06 BURGER JOINT                                     │            │       8.69 │
2019-10-06 COFFEE                                           │            │       5.10 │
2019-10-09 BIWEEKLY PAY                                     │     150.00 │            │
2019-10-10 SUB SANDWICH                                     │            │       9.13 │
2019-10-14 MEXICAN                                          │            │      12.15 │
2019-10-20 CHINESE                                          │            │      11.39 │
2019-10-21 GROCERY STORE                                    │            │      22.99 │
2019-10-23 BIWEEKLY PAY                                     │     150.00 │            │
2019-10-24 BAR AND GRILL                                    │            │      25.28 │
2019-10-28 GROCERY STORE                                    │            │      22.69 │
2019-10-30 LEBANESE                                         │            │       5.99 │
2019-10-31 WITHDRAWL                                        │            │       1.00 │
2019-10-31 MONTHLY ACCOUNT FEE                              │            │       3.95 │
2019-10-31 CHQ RETURN FEE                                   │            │       2.00 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │     300.00 │     145.62 │
                                                            ├────────────┼────────────┤
                                                            │     154.38 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("can filter by account Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createImportRule("Loan", "\${TEXTBOOKS}/test/data/records/*.csv");
				$Entity->createRecords(Period => new Period("2019-10"));

				$Entity->readRecords(Name => new Name('Loan'));
				expect_stdout(<<"_"
Liabilities:Personal Loan                                                              
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-10-03 THAI                                             │            │      11.50 │
2019-10-06 GROCERY STORE                                    │            │       3.76 │
2019-10-06 BURGER JOINT                                     │            │       8.69 │
2019-10-06 COFFEE                                           │            │       5.10 │
2019-10-09 BIWEEKLY PAY                                     │     150.00 │            │
2019-10-10 SUB SANDWICH                                     │            │       9.13 │
2019-10-14 MEXICAN                                          │            │      12.15 │
2019-10-20 CHINESE                                          │            │      11.39 │
2019-10-21 GROCERY STORE                                    │            │      22.99 │
2019-10-23 BIWEEKLY PAY                                     │     150.00 │            │
2019-10-24 BAR AND GRILL                                    │            │      25.28 │
2019-10-28 GROCERY STORE                                    │            │      22.69 │
2019-10-30 LEBANESE                                         │            │       5.99 │
2019-10-31 WITHDRAWL                                        │            │       1.00 │
2019-10-31 MONTHLY ACCOUNT FEE                              │            │       3.95 │
2019-10-31 CHQ RETURN FEE                                   │            │       2.00 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │     300.00 │     145.62 │
                                                            ├────────────┼────────────┤
                                                            │     154.38 │            │
                                                            ╘════════════╧════════════╛


_
				);
			});

			it("can filter by Period", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createRecords(Period => new Period("2019-10"));
				$Entity->readRecords(Period => new Period('2019-10-31'));
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-10-31 WITHDRAWL                                        │            │       1.00 │
2019-10-31 MONTHLY ACCOUNT FEE                              │            │       3.95 │
2019-10-31 CHQ RETURN FEE                                   │            │       2.00 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │            │       6.95 │
                                                            ├────────────┼────────────┤
                                                            │            │       6.95 │
                                                            ╘════════════╧════════════╛


_
				);
			});

			it("can filter by item Pattern", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				$Entity->createRecords(Period => new Period("2019-10"));
				$Entity->readRecords(Pattern => new Pattern("FEE"));
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-10-06 COF\e[32mFEE\e[0m                                           │            │       5.10 │
2019-10-31 MONTHLY ACCOUNT \e[32mFEE\e[0m                              │            │       3.95 │
2019-10-31 CHQ RETURN \e[32mFEE\e[0m                                   │            │       2.00 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │            │      11.05 │
                                                            ├────────────┼────────────┤
                                                            │            │      11.05 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

		});

		describe(".reconcileRecords", sub {

			my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";

			Console::stderr;
			Console::stdout;

			it("reports if imported balances match computed balances", sub {
				$Entity->reconcileRecords(verbosity => 1);
				expect_stdout("");
				expect_stderr(<<"_"
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 61.22 but recorded as 60.22.\e[0m
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 55.22 but recorded as 56.22.\e[0m
** NOTE  : Reconciled 217 records from account 11000 and found \e[33m2\e[0m issues.
** NOTE  : Reconciled \e[32m217\e[0m records from account 12000 and found no issues.
_
				);
			});

			it("can filter by account Name", sub {
				$Entity->reconcileRecords(verbosity => 1, Name => new Name("Chequing"));
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Reconciled \e[32m217\e[0m records from account 12000 and found no issues.
_
				);
			});

			it("can filter by Period or period", sub {
				$Entity->reconcileRecords(verbosity => 1, Period => new Period('2019-01:2019-06'));
				expect_stdout("");
				expect_stderr(<<"_"
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 61.22 but recorded as 60.22.\e[0m
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 55.22 but recorded as 56.22.\e[0m
** NOTE  : Reconciled 111 records from account 11000 and found \e[33m2\e[0m issues.
** NOTE  : Reconciled \e[32m111\e[0m records from account 12000 and found no issues.
_
				);
				$Entity->reconcileRecords(verbosity => 1, Period => new Period('2019-07:2019-12'));
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Reconciled \e[32m106\e[0m records from account 11000 and found no issues.
** NOTE  : Reconciled \e[32m106\e[0m records from account 12000 and found no issues.
_
				);
 			});

			it("has multiple levels of verbosity", sub {
				my $Savings = $Entity->getAccount("Savings");
				$Savings->{Actions}->[96]->{balance}++;

				$Entity->reconcileRecords();
				expect_stdout("");
				expect_stderr("");

				$Entity->reconcileRecords(verbosity => 1);
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Reconciled \e[32m217\e[0m records from account 11000 and found no issues.
** NOTE  : Reconciled \e[32m217\e[0m records from account 12000 and found no issues.
_
				);

				$Savings->{Actions}->[96]->{balance}--;
				$Entity->reconcileRecords(verbosity => 3, Name => new Name('Savings'), Period => new Period('2019-05-30'));
				expect_stdout(<<"_"
────────────────────────────────────────────────────────────────────────────────────────────────────
11000 2019-05-30      84.49 +       0.00 -      23.12 =      61.37  \e[32m==      61.37\e[0m
11000 2019-05-30      61.37 +       0.00 -       0.15 =      60.22  \e[33m!=      61.22\e[0m
11000 2019-05-30      60.22 +       0.00 -       5.00 =      56.22  \e[33m!=      55.22\e[0m
11000 2019-05-30      56.22 +       0.00 -       3.95 =      52.27  \e[32m==      52.27\e[0m
11000 2019-05-30      52.27 +       0.00 -       2.00 =      50.27  \e[32m==      50.27\e[0m
────────────────────────────────────────────────────────────────────────────────────────────────────


_
				);
				expect_stderr("** NOTE  : Reconciled 6 records from account 11000 and found \e[33m2\e[0m issues.\n");
			});

		});

		describe(".deleteRecords", sub {

			Console::stderr;
			Console::stdout;

			it("removes bank records from Accounts", sub {
				my $Entity   = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				my $Savings  = $Entity->getAccount("Savings");
				my $Chequing = $Entity->getAccount("Chequing");
				$Entity->deleteRecords();
				expect(scalar $Savings->Actions , 0);
				expect(scalar $Chequing->Actions, 0);
				expect_stderr("");
				expect_stdout("");
			});

			it("can filter by account Name", sub {
				my $Entity   = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				my $Savings  = $Entity->getAccount("Savings");
				my $Chequing = $Entity->getAccount("Chequing");
				$Entity->deleteRecords(Name => new Name("Savings"));
				expect(scalar $Savings->Actions , 0);
				expect(scalar $Chequing->Actions, 217);
				expect_stderr("");
				expect_stdout("");
			});

			it("can filter by Period", sub {
				my $Entity   = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				my $Savings  = $Entity->getAccount("Savings");
				my $Chequing = $Entity->getAccount("Chequing");
				$Entity->deleteRecords(Period => new Period("2019-01:2019-06"));
				expect(scalar $Savings->Actions , 106);
				expect(scalar $Chequing->Actions, 106);
				expect_stderr("");
				expect_stdout("");
			});

			it("has multiple levels of verbosity", sub {
				my $Entity   = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				my $Savings  = $Entity->getAccount("Savings");
				my $Chequing = $Entity->getAccount("Chequing");
				$Entity->deleteRecords(verbosity => 1);
				expect(scalar $Savings->Actions , 0);
				expect(scalar $Chequing->Actions, 0);
				expect_stderr("** NOTE  : Deported \e[32m434\e[0m records.\n");
				expect_stdout("");
			});

		});

		describe(Console::cyan(".import"), sub {

			my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";

			Console::stdout;
			Console::stderr;

			it("shows import rules", sub {
				foreach $op ("--rules", "-r") {
					$Entity->import($op);
					expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.*
IMPORT \${TEXTBOOKS}/test/data/records/*.csv
_
					);
					expect_stderr("");
				}
			});

			it("shows import rules by account name", sub {
				foreach $op ("--account", "-a") {
					$Entity->import("-r",$op, "Chequing");
					expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.csv
_
					);
					expect_stderr("");
				}
			});

			it("shows import rules by pattern", sub {
				$Entity->import("-r", "csv");
				expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.\e[32mcsv\e[0m
_
				);
				expect_stderr("");
			});

			it("shows import files", sub {
				foreach $op ("--files", "-f") {
					$Entity->import($op);
					expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/2019-01.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-02.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-03.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-04.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.txt
IMPORT \${TEXTBOOKS}/test/data/records/2019-06.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-07.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-08.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-09.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-10.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-11.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-12.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-01.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-02.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-03.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-04.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-06.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-07.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-08.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-09.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-10.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-11.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-12.csv
_
					);
					expect_stderr("");
				}
			});

			it("shows import files by account name", sub {
				$Entity->import("-f", "-a", "Savings");
				expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/2019-01.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-02.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-03.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-04.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.txt
IMPORT \${TEXTBOOKS}/test/data/records/2019-06.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-07.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-08.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-09.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-10.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-11.csv
IMPORT \${TEXTBOOKS}/test/data/records/2019-12.csv
_
				);
				expect_stderr("");
			});

			it("shows import files by pattern", sub {
				$Entity->import("-f", "txt");
				expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/2019-05.\e[32mtxt\e[0m
_
				);
				expect_stderr("");
			});

			it("creates an import rule", sub {
				foreach my $op ("--source", "-s") {
					$Entity->import("-a", "Savings", "--source", "\${TEXTBOOKS}/test/data/records/*.csv");
					expect_stdout(<<"_"
IMPORT \${TEXTBOOKS}/test/data/records/*.csv
_
					);
					expect_stderr("");
				}
				fail('does not show new import rule in list of rules');
			});

			it("imports files by period", sub {
				$Entity->deleteRecords();
				Console::stdout;
				Console::stderr;
				$Entity->import("--period", "2019-01:2019-06");
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Importing...
** NOTE  : Imported \e[32m222\e[0m new transactions
_
				);
				$Entity->import("-p", "2019-07:2019-12");
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Importing...
\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m
\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 12000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m
** NOTE  : Imported \e[32m212\e[0m new transactions
_
				);
				fail('verbosity is not controllable');
			});

		});

		describe(Console::cyan(".reconcile"), sub {

			my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";

			Console::stdout;
			Console::stderr;

			it("reconciles records", sub {
				$Entity->reconcile();
				expect_stdout("");
				expect_stderr(<<"_"
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 61.22 but recorded as 60.22.\e[0m
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 55.22 but recorded as 56.22.\e[0m
** NOTE  : Reconciled 217 records from account 11000 and found \e[33m2\e[0m issues.
** NOTE  : Reconciled \e[32m217\e[0m records from account 12000 and found no issues.
_
				);
 				fail('verbosity is not controllable');
			});

			it("reconciles records by account", sub {
				$Entity->reconcile("--account", "savings");
				expect_stdout("");
				expect_stderr(<<"_"
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 61.22 but recorded as 60.22.\e[0m
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 55.22 but recorded as 56.22.\e[0m
** NOTE  : Reconciled 217 records from account 11000 and found \e[33m2\e[0m issues.
_
				);

				$Entity->reconcile("-a", "chequing");
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Reconciled \e[32m217\e[0m records from account 12000 and found no issues.
_
				);
			});

			it("reconciles records by period", sub {

				$Entity->reconcile("--period", "2019-01:2019-06");
				expect_stdout("");
				expect_stderr(<<"_"
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 61.22 but recorded as 60.22.\e[0m
\e[33m** WARN  : 11000 balance on 2019-05-30 is calculated as 55.22 but recorded as 56.22.\e[0m
** NOTE  : Reconciled 111 records from account 11000 and found \e[33m2\e[0m issues.
** NOTE  : Reconciled \e[32m111\e[0m records from account 12000 and found no issues.
_
				);
				$Entity->reconcile("-p", "2019-07:2019-12");
				expect_stdout("");
				expect_stderr(<<"_"
** NOTE  : Reconciled \e[32m106\e[0m records from account 11000 and found no issues.
** NOTE  : Reconciled \e[32m106\e[0m records from account 12000 and found no issues.
_
				);
			});

		});

		describe(Console::cyan(".deport"), sub {

			it("deletes records", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				$Entity->deport();
				expect_stderr("** NOTE  : Deported \e[32m434\e[0m records.\n");
				expect_stdout("");
				fail('verbosity is not controllable');
			});

			it("deletes records by account", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";
				$Entity->deport("--account", "Savings");
				expect_stderr("** NOTE  : Deported \e[32m217\e[0m records.\n");
				expect_stdout("");
				$Entity->deport("-a", "Chequing");
				expect_stderr("** NOTE  : Deported \e[32m217\e[0m records.\n");
				expect_stdout("");
			});

			it("deletes records by period", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/import.gl";

				$Entity->deport("--period", "2019-01:2019-06");
				expect_stderr("** NOTE  : Deported \e[32m222\e[0m records.\n");
				expect_stdout("");

				$Entity->deport("-p", "2019-07:2019-12");
				expect_stderr("** NOTE  : Deported \e[32m212\e[0m records.\n");
				expect_stdout("");
			});

		});

	}); # Bank Record Import

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Bank Record Allocation
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("Bank Record Allocation", sub {

		describe(".createAllocationRule", sub {

			it("returns the connected Accounts", sub {
				my $Entity     = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				my $Allocation = new Allocation();
				$Allocation->item("BIWEEKLY")->to("Pay");
				my @Accounts = $Entity->createAllocationRule($Allocation);
				expect(scalar @Accounts, 1);
				expect($Accounts[0], $Entity->getAccount('Pay'));
			});

			it("throws an error if an Account can't be found", sub {
				my $Entity     = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				my $Allocation = new Allocation();
				$Allocation->item("BIWEEKLY")->to("Wages");

				$Entity->createAllocationRule($Allocation);
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | BIWEEKLY                                                                           ║
║ Wages                                                                     ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("\e[31m** ERROR : An account reference is invalid.\e[0m\n");
			});
		
		});

		describe(".readAllocationRules", sub {

			it("outputs a list of Allocation Rules", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				$Entity->readAllocationRules();
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | GROCERY                                                                            ║
║ | BAR                                                                                ║
║ | PUB                                                                                ║
║ | MEXICAN                                                                            ║
║ | CHINESE                                                                            ║
║ | LEBANESE                                                                           ║
║ | THAI                                                                               ║
║ | VEITNAMESE                                                                         ║
║ | TEXMEX                                                                             ║
║ | VEGITARIAN                                                                         ║
║ | FAST FOOD                                                                          ║
║ | SANDWICH                                                                           ║
║ | WATERING                                                                           ║
║ | BULK FOOD                                                                          ║
║ | BURGER                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FEE & !COFFEE                                                                      ║
║ | OVERDRAFT                                                                          ║
║ Fees                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | WITHDRAWL                                                                          ║
║ | DEPOSIT                                                                            ║
║ | ATM                                                                                ║
║ Cash                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | TOY                                                                                ║
║ Toys                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("");
			});

			it("can filter by account Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				$Entity->readAllocationRules(Name => new Name 'Fees');
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FEE & !COFFEE                                                                      ║
║ | OVERDRAFT                                                                          ║
║ Fees                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("");
			});

		});

		describe(".updateAllocationRule", sub {

			it("adds an Allocation rule for an Account", sub {
				my $Entity     = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Allocation = new Allocation();
				$Allocation->item('BIWEEKLY')->to('Pay');
				$Entity->updateAllocationRule($Allocation);
				expect($Entity->getAccount('Pay')->Allocation, $Allocation);
			});

			it("can be output to a file", sub {
				my $Entity     = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Allocation = new Allocation();
				$Allocation->item('BIWEEKLY')->to('Pay');
				$Entity->updateAllocationRule($Allocation);
				expect($Entity->getAccount('Pay')->Allocation, $Allocation);
				expect($Entity->put(string => 1), <<"_"
ASSET        10000         Assets
────────────────────────────────────────────────────────────────────────────────────────────────────


ASSET        11000:10000   Assets:Bank Account
────────────────────────────────────────────────────────────────────────────────────────────────────
* \${TEXTBOOKS}/test/data/records/*.csv
────────────────────────────────────────────────────────────────────────────────────────────────────


LIABILITY    20000         Liabilities
────────────────────────────────────────────────────────────────────────────────────────────────────


LIABILITY    21000:20000   Liabilities:Personal Loan
────────────────────────────────────────────────────────────────────────────────────────────────────


INCOME       30000         Income
────────────────────────────────────────────────────────────────────────────────────────


INCOME       31000:30000   Income:Pay
────────────────────────────────────────────────────────────────────────────────────────
| BIWEEKLY
@ Pay                                                                       ,           
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      40000         Expense
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      41000:40000   Expense:Food
────────────────────────────────────────────────────────────────────────────────────────


EXPENSE      42000:40000   Expense:Bank Fees
────────────────────────────────────────────────────────────────────────────────────────


_
				);
			});

			it("can be input from a file", sub {
				my $Entity     = get Entity "$ENV{TEXTBOOKS}/test/data/chart.gl";
				my $Allocation = new Allocation();
				$Allocation->item('BIWEEKLY')->to('Pay');
				$Entity->updateAllocationRule($Allocation);
				expect($Entity->getAccount('Pay')->Allocation, $Allocation);
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
			});

		});

		describe(".createAllocations", sub {

			it("creates a list of Entries from Allocation Rules", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				$Entity->createAllocations();
				Console::stdout;
				expect_stderr("** NOTE  : 159 allocated, 58 to go.\n");
				expect($Entity->{entry}, 158);
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 158);
			});

			it("can filter by account Name", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";

				$Entity->createAllocations(Name => new Name('Food'));
				Console::stdout;
				expect_stderr("** NOTE  : 111 allocated, 106 to go.\n");
				expect($Entity->{entry}, 110);
				$Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 110);

				$Entity->createAllocations(Name => new Name('Fees'));
				Console::stdout;
				expect_stderr("** NOTE  : 33 allocated, 73 to go.\n");
				expect($Entity->{entry}, 143);
				$Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 143);

				$Entity->createAllocations(Name => new Name('Cash'));
				Console::stdout;
				expect_stderr("** NOTE  : 13 allocated, 60 to go.\n");
				expect($Entity->{entry}, 156);
				$Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 156);

				$Entity->createAllocations(Name => new Name('Toys'));
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | TOY                                                                                ║
║ Toys                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mTOY\e[0m CHAIN                                               , 2019-02-18
────────────────────────────────────────────────────────────────────────────────────────
44000   Expense:\e[32mToys\e[0m                                            ,      43.98,           
11000   Assets:Bank Account                                     ,           ,      43.98


ENTRY               LOCAL \e[32mTOY\e[0m STORE                                         , 2019-03-03
────────────────────────────────────────────────────────────────────────────────────────
44000   Expense:\e[32mToys\e[0m                                            ,      18.62,           
11000   Assets:Bank Account                                     ,           ,      18.62


_
				);
				expect_stderr("** NOTE  : 2 allocated, 58 to go.\n");
				expect($Entity->{entry}, 158);
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 158);
			});

			it("can filter by Period", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";

				$Entity->createAllocations(Period => new Period('2019-07:2019-12'));
				Console::stdout;
				expect_stderr("** NOTE  : 77 allocated, 140 to go.\n");
				expect($Entity->{entry}, 76);
				my $Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 76);

				$Entity->createAllocations(Period => new Period('2019-01:2019-06'));
				Console::stdout;
				expect_stderr("** NOTE  : 82 allocated, 58 to go.\n");
				expect($Entity->{entry}, 158);
				$Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 158);
			});

			it("can do a one-off Allocation", sub {
				my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";
				
				$Entity->createAllocations();
				Console::stdout;
				Console::stderr;

				my $Allocate = new Allocation();
				$Allocate->item("BIWEEKLY")->to("Pay");

				$Entity->createAllocationRule($Allocate);

				$Entity->createAllocations(Allocation => $Allocate);
				# print(Console::stdout);
				Console::stdout;
				expect_stderr("** NOTE  : 26 allocated, 32 to go.\n");
				expect($Entity->{entry}, 184);
			});

		});

		describe(Console::cyan(".allocate"), sub {

			my $Entity = get Entity "$ENV{TEXTBOOKS}/test/data/alloc.gl";

			it("shows existing allocation rules", sub {
				foreach $op ("--rules", "-r") {
					$Entity->allocate($op);
					expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | GROCERY                                                                            ║
║ | BAR                                                                                ║
║ | PUB                                                                                ║
║ | MEXICAN                                                                            ║
║ | CHINESE                                                                            ║
║ | LEBANESE                                                                           ║
║ | THAI                                                                               ║
║ | VEITNAMESE                                                                         ║
║ | TEXMEX                                                                             ║
║ | VEGITARIAN                                                                         ║
║ | FAST FOOD                                                                          ║
║ | SANDWICH                                                                           ║
║ | WATERING                                                                           ║
║ | BULK FOOD                                                                          ║
║ | BURGER                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FEE & !COFFEE                                                                      ║
║ | OVERDRAFT                                                                          ║
║ Fees                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | WITHDRAWL                                                                          ║
║ | DEPOSIT                                                                            ║
║ | ATM                                                                                ║
║ Cash                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | TOY                                                                                ║
║ Toys                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
					);
					expect_stderr("");
				}
			});

			it("shows existing allocation rules by account name", sub {
				$Entity->allocate("-r", "toys");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | TOY                                                                                ║
║ Toys                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("");
			});

			it('creates a one-time allocation to override existing rules', sub {
				# Example: Suppose we went to a restaurant called OVERDRAFT
				# while travelling. This gets picked up by the Fees rule,
				# so we need to manually allocate it to Food before the
				# Fee rule picks it up.
				$Entity->allocate("--period", "2019-09-30", "OVERDRAFT", "--account", "Food");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | OVERDRAFT                                                                          ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mOVERDRAFT\e[0m INTEREST                                      , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       0.31,           
11000   Assets:Bank Account                                     ,           ,       0.31


_
				);
				expect_stderr("** NOTE  : 1 allocated, 216 to go.\n");
			});

			it("creates entries by period using existing rules", sub {
				$Entity->allocate("-p", "2019-01:2019-09");
				Console::stdout;
				expect_stderr("** NOTE  : 125 allocated, 91 to go.\n");
			});

			it("creates entries by account name using existing rules", sub {
				$Entity->allocate("Food");
				Console::stdout;
				expect_stderr("** NOTE  : 25 allocated, 66 to go.\n");
			});

			it("creates entries using existing rules until no more rules apply, then shows bank records", sub {
				$Entity->allocate();
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FEE & !COFFEE                                                                      ║
║ | OVERDRAFT                                                                          ║
║ Fees                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-12-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-12-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expense:Bank \e[32mFees\e[0m                                       ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | WITHDRAWL                                                                          ║
║ | DEPOSIT                                                                            ║
║ | ATM                                                                                ║
║ Cash                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
43000   Expense:\e[32mCash\e[0m                                            ,       1.00,           
11000   Assets:Bank Account                                     ,           ,       1.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
43000   Expense:\e[32mCash\e[0m                                            ,       3.00,           
11000   Assets:Bank Account                                     ,           ,       3.00


_
				);
				expect_stderr("** NOTE  : 8 allocated, 58 to go.\n");
				$Entity->allocate();
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-02 BIWEEKLY PAY                                     │     150.00 │            │
2019-01-13 HOCKEY GEAR                                      │            │     112.99 │
2019-01-16 BIWEEKLY PAY                                     │     150.00 │            │
2019-01-27 LOCAL SKI HILL                                   │            │      11.50 │
2019-01-30 BIWEEKLY PAY                                     │     150.00 │            │
2019-02-13 BIWEEKLY PAY                                     │     150.00 │            │
2019-02-13 PHARMACY                                         │            │      28.00 │
2019-02-18 HAIR SALON                                       │            │      28.25 │
2019-02-27 BIWEEKLY PAY                                     │     150.00 │            │
2019-03-10 SKI MOUNTAIN                                     │            │       4.99 │
2019-03-10 SKI MOUNTAIN                                     │            │       9.98 │
2019-03-10 CINEPLEX                                         │            │      16.44 │
2019-03-13 BIWEEKLY PAY                                     │     150.00 │            │
2019-03-27 BIWEEKLY PAY                                     │     150.00 │            │
2019-04-07 COFFEE                                           │            │       5.48 │
2019-04-10 BIWEEKLY PAY                                     │     150.00 │            │
2019-04-24 CREOLE                                           │            │      45.48 │
2019-04-24 BIWEEKLY PAY                                     │     150.00 │            │
2019-05-08 BIWEEKLY PAY                                     │     150.00 │            │
2019-05-08 HAIR SALON                                       │            │      28.25 │
2019-05-12 CHQ#00084                                        │            │     205.00 │
2019-05-16 PIT STOP                                         │            │       4.51 │
2019-05-22 BIWEEKLY PAY                                     │     150.00 │            │
2019-05-23 CHQ#00085                                        │            │     310.00 │
2019-05-26 BOOK STORE                                       │            │       4.46 │
2019-05-26 LOAN                                             │     200.00 │            │
2019-06-05 BIWEEKLY PAY                                     │     150.00 │            │
2019-06-10 SKATE REPAIR                                     │            │       7.00 │
2019-06-19 BIWEEKLY PAY                                     │     150.00 │            │
2019-07-03 BIWEEKLY PAY                                     │     150.00 │            │
2019-07-11 HAIR SALON                                       │            │      60.69 │
2019-07-11 THE BEER STORE                                   │            │      44.95 │
2019-07-14 SPECIALTY BUTCHER                                │            │      42.43 │
2019-07-17 BIWEEKLY PAY                                     │     150.00 │            │
2019-07-17 PHARMACY                                         │            │      14.56 │
2019-07-31 BIWEEKLY PAY                                     │     150.00 │            │
2019-08-05 LCBO/RAO                                         │            │      26.20 │
2019-08-14 BIWEEKLY PAY                                     │     150.00 │            │
2019-08-25 COFFEE                                           │            │       5.32 │
2019-08-28 BIWEEKLY PAY                                     │     150.00 │            │
2019-09-08 HAIR SALON                                       │            │      28.25 │
2019-09-11 BIWEEKLY PAY                                     │     150.00 │            │
2019-09-17 CHQ#00087                                        │            │     575.00 │
2019-09-22 BAKERY                                           │            │       5.63 │
2019-09-25 BIWEEKLY PAY                                     │     150.00 │            │
2019-09-25 LOAN                                             │     100.00 │            │
2019-09-30 DRUG STORE                                       │            │      16.28 │
2019-10-06 COFFEE                                           │            │       5.10 │
2019-10-09 BIWEEKLY PAY                                     │     150.00 │            │
2019-10-23 BIWEEKLY PAY                                     │     150.00 │            │
2019-11-06 BIWEEKLY PAY                                     │     150.00 │            │
2019-11-17 COFFEE                                           │            │       8.82 │
2019-11-17 COFFEE                                           │            │       3.14 │
2019-11-20 BIWEEKLY PAY                                     │     150.00 │            │
2019-12-01 HAIR SALON                                       │            │      28.25 │
2019-12-04 BIWEEKLY PAY                                     │     150.00 │            │
2019-12-05 SNACKS                                           │            │       8.48 │
2019-12-18 BIWEEKLY PAY                                     │     150.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    4200.00 │    1695.43 │
                                                            ├────────────┼────────────┤
                                                            │    2504.57 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("shows records by period", sub {
				$Entity->allocate("-p", "2019-12");
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-12-01 HAIR SALON                                       │            │      28.25 │
2019-12-04 BIWEEKLY PAY                                     │     150.00 │            │
2019-12-05 SNACKS                                           │            │       8.48 │
2019-12-18 BIWEEKLY PAY                                     │     150.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │     300.00 │      36.73 │
                                                            ├────────────┼────────────┤
                                                            │     263.27 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("shows records by pattern", sub {
				$Entity->allocate("COFFEE");
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-04-07 \e[32mCOFFEE\e[0m                                           │            │       5.48 │
2019-08-25 \e[32mCOFFEE\e[0m                                           │            │       5.32 │
2019-10-06 \e[32mCOFFEE\e[0m                                           │            │       5.10 │
2019-11-17 \e[32mCOFFEE\e[0m                                           │            │       8.82 │
2019-11-17 \e[32mCOFFEE\e[0m                                           │            │       3.14 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │            │      27.86 │
                                                            ├────────────┼────────────┤
                                                            │            │      27.86 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("shows entries by a new rule", sub {
				$Entity->allocate("COFFEE", "-a", "Food");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | COFFEE                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-04-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       5.48,           
11000   Assets:Bank Account                                     ,           ,       5.48


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-08-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       5.32,           
11000   Assets:Bank Account                                     ,           ,       5.32


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-10-06
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       5.10,           
11000   Assets:Bank Account                                     ,           ,       5.10


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-11-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       8.82,           
11000   Assets:Bank Account                                     ,           ,       8.82


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-11-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       3.14,           
11000   Assets:Bank Account                                     ,           ,       3.14


_
				);
				expect_stderr("** NOTE  : 5 allocated, 53 to go.\n");
			});

			it("can update the existing rule", sub {
				$Entity->allocate("-r", "Food");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | GROCERY                                                                            ║
║ | BAR                                                                                ║
║ | PUB                                                                                ║
║ | MEXICAN                                                                            ║
║ | CHINESE                                                                            ║
║ | LEBANESE                                                                           ║
║ | THAI                                                                               ║
║ | VEITNAMESE                                                                         ║
║ | TEXMEX                                                                             ║
║ | VEGITARIAN                                                                         ║
║ | FAST FOOD                                                                          ║
║ | SANDWICH                                                                           ║
║ | WATERING                                                                           ║
║ | BULK FOOD                                                                          ║
║ | BURGER                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("");

				$Entity->allocate("SNACK", "-a", "Food", "--keep");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | SNACK                                                                              ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mSNACK\e[0mS                                                  , 2019-12-05
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       8.48,           
11000   Assets:Bank Account                                     ,           ,       8.48


_
				);
				expect_stderr("** NOTE  : 1 allocated, 52 to go.\n");

				$Entity->allocate("BAKERY", "-a", "Food", "-k");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | BAKERY                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mBAKERY\e[0m                                                  , 2019-09-22
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:\e[32mFood\e[0m                                            ,       5.63,           
11000   Assets:Bank Account                                     ,           ,       5.63


_
				);
				expect_stderr("** NOTE  : 1 allocated, 51 to go.\n");

				$Entity->allocate("-r", "Food");
				expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | GROCERY                                                                            ║
║ | BAR                                                                                ║
║ | PUB                                                                                ║
║ | MEXICAN                                                                            ║
║ | CHINESE                                                                            ║
║ | LEBANESE                                                                           ║
║ | THAI                                                                               ║
║ | VEITNAMESE                                                                         ║
║ | TEXMEX                                                                             ║
║ | VEGITARIAN                                                                         ║
║ | FAST FOOD                                                                          ║
║ | SANDWICH                                                                           ║
║ | WATERING                                                                           ║
║ | BULK FOOD                                                                          ║
║ | BURGER                                                                             ║
║ | SNACK                                                                              ║
║ | BAKERY                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


_
				);
				expect_stderr("");
			});

			it("can save and restore the changes made", sub {
				$Read = new Entity();
				$Read->get(string => $Entity->put(string => 1));
				expect($Read->put(string =>1), $Entity->put(string => 1));
				expect($Read->{entry}, 165);
			});

		});

	}); # Bank Record Allocation

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Reporting
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("reporting", sub {

		my $entity = "$ENV{TEXTBOOKS}/test/data/report.gl"; 
		my $Entity = get Entity $entity;

		Console::stdout;
		Console::stderr;

		describe(".reportLedgers", sub {

			it("reports the actions of each Account", sub {
				$Entity->reportLedgers();
				Console::stdout; # Virtually the entity file...
				expect_stderr("");
			});

			it("can be filtered by account Name", sub {
				$Entity->reportLedgers(
					Name => new Name("Hockey"),
				);
				expect_stdout(<<"_"
Expenses:Activities:Hockey                                                             
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-13 HOCKEY GEAR                                      │     112.99 │            │
2019-05-12 CHQ#00084                                        │     205.00 │            │
2019-05-23 CHQ#00085                                        │     310.00 │            │
2019-06-10 SKATE REPAIR                                     │       7.00 │            │
2019-09-17 CHQ#00087                                        │     575.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    1209.99 │            │
                                                            ├────────────┼────────────┤
                                                            │    1209.99 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("can be filtered by Period", sub {
				$Entity->reportLedgers(
					Name    => new Name("Hockey"),
					Period  => new Period("2019-01:2019-06"),
				);
				expect_stdout(<<"_"
Expenses:Activities:Hockey                                        2019-01-01:2019-06-31
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-13 HOCKEY GEAR                                      │     112.99 │            │
2019-05-12 CHQ#00084                                        │     205.00 │            │
2019-05-23 CHQ#00085                                        │     310.00 │            │
2019-06-10 SKATE REPAIR                                     │       7.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │     634.99 │            │
                                                            ├────────────┼────────────┤
                                                            │     634.99 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("can be filtered by item Pattern", sub {
				$Entity->reportLedgers(
					Name    => new Name("Assets"),
					Period  => new Period("2019-01:2019-03"),
					Pattern => new Pattern("GROCERY")
				);
				expect_stdout(<<"_"
Assets:Bank Account                                               2019-01-01:2019-03-31
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-07 \e[32mGROCERY\e[0m STORE                                    │            │      28.32 │
2019-01-13 \e[32mGROCERY\e[0m STORE                                    │            │      24.28 │
2019-01-20 \e[32mGROCERY\e[0m STORE                                    │            │      22.09 │
2019-01-29 \e[32mGROCERY\e[0m STORE                                    │            │      22.87 │
2019-02-03 \e[32mGROCERY\e[0m STORE                                    │            │      22.09 │
2019-02-07 \e[32mGROCERY\e[0m STORE                                    │            │      23.08 │
2019-02-18 \e[32mGROCERY\e[0m STORE                                    │            │      24.99 │
2019-02-19 \e[32mGROCERY\e[0m STORE                                    │            │       8.87 │
2019-02-24 \e[32mGROCERY\e[0m STORE                                    │            │      22.09 │
2019-02-28 \e[32mGROCERY\e[0m STORE                                    │            │      97.75 │
2019-03-11 \e[32mGROCERY\e[0m STORE                                    │            │      20.99 │
2019-03-13 \e[32mGROCERY\e[0m STORE                                    │            │      20.99 │
2019-03-18 \e[32mGROCERY\e[0m STORE                                    │            │      22.87 │
2019-03-24 \e[32mGROCERY\e[0m STORE                                    │            │       8.23 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │            │     369.51 │
                                                            ├────────────┼────────────┤
                                                            │            │     369.51 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

		});

		describe(".reportTrialBalance", sub {

			it("reports the net change of each Account", sub {
				$Entity->reportTrialBalance();
				expect_stdout(<<"_"
TRIAL BALANCE                                                                          
────────────────────────────────────────────────────────────┬────────────┬────────────┐
Assets:Bank Account                                         │     346.77 │            │
Liabilities:Personal Loan                                   │            │     300.00 │
Income:Pay                                                  │            │    3900.00 │
Expenses:Food                                               │    1926.23 │            │
Expenses:Banking Fees                                       │     103.36 │            │
Expenses:Cash                                               │     200.00 │            │
Expenses:Activities:Hockey                                  │    1209.99 │            │
Expenses:Activities:Skiing                                  │      26.47 │            │
Expenses:Health Care                                        │     232.53 │            │
Expenses:Entertainment                                      │      20.90 │            │
Expenses:Toys                                               │      62.60 │            │
Expenses:Drink                                              │      71.15 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    4200.00 │    4200.00 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("can report total debits & credits for each Account", sub {
				$Entity->reportTrialBalance(
					totals => 1, 
				);
				expect_stdout(<<"_"
TRIAL BALANCE                                                                          
────────────────────────────────────────────────────────────┬────────────┬────────────┐
Assets:Bank Account                                         │    4275.00 │    3928.23 │
Liabilities:Personal Loan                                   │            │     300.00 │
Income:Pay                                                  │            │    3900.00 │
Expenses:Food                                               │    1926.23 │            │
Expenses:Banking Fees                                       │     103.36 │            │
Expenses:Cash                                               │     275.00 │      75.00 │
Expenses:Activities:Hockey                                  │    1209.99 │            │
Expenses:Activities:Skiing                                  │      26.47 │            │
Expenses:Health Care                                        │     232.53 │            │
Expenses:Entertainment                                      │      20.90 │            │
Expenses:Toys                                               │      62.60 │            │
Expenses:Drink                                              │      71.15 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    8203.23 │    8203.23 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

			it("can be filtered by Period", sub {
				$Entity->reportTrialBalance(
					Period => new Period("2019-01:2019-03")
				);
				expect_stdout(<<"_"
TRIAL BALANCE                                                     2019-01-01:2019-03-31
────────────────────────────────────────────────────────────┬────────────┬────────────┐
Assets:Bank Account                                         │     155.11 │            │
Income:Pay                                                  │            │    1050.00 │
Expenses:Food                                               │     624.29 │            │
Expenses:Banking Fees                                       │      17.85 │            │
Expenses:Cash                                               │            │      22.00 │
Expenses:Activities:Hockey                                  │     112.99 │            │
Expenses:Activities:Skiing                                  │      26.47 │            │
Expenses:Health Care                                        │      56.25 │            │
Expenses:Entertainment                                      │      16.44 │            │
Expenses:Toys                                               │      62.60 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    1072.00 │    1072.00 │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

		});

		describe(".reportIncomeExpense", sub {

			it("reports a rolled up implicit signed change of all Income & Expense Accounts", sub {
				$Entity->reportIncomeExpense();
				expect_stdout(<<"_"
INCOME & EXPENSE                                                                       
─────────────────────────────────────────────────────────────────────────┬────────────┐
Income                                                                   │ \e[36m   3900.00\e[0m │
  Pay                                                                    │    3900.00 │
Expenses                                                                 │ \e[36m   3853.23\e[0m │
  Food                                                                   │    1926.23 │
  Banking Fees                                                           │     103.36 │
  Cash                                                                   │     200.00 │
  Activities                                                             │ \e[36m   1236.46\e[0m │
    Hockey                                                               │    1209.99 │
    Skiing                                                               │      26.47 │
  Health Care                                                            │     232.53 │
  Entertainment                                                          │      20.90 │
  Toys                                                                   │      62.60 │
  Drink                                                                  │      71.15 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │      46.77 │
                                                                         ╘════════════╛


_
				);
				expect_stderr("");
			});

			it("can be filtered by Period", sub {
				$Entity->reportIncomeExpense(
					Period => new Period("2019-01:2019-03")
				);
				expect_stdout(<<"_"
INCOME & EXPENSE                                                  2019-01-01:2019-03-31
─────────────────────────────────────────────────────────────────────────┬────────────┐
Income                                                                   │ \e[36m   1050.00\e[0m │
  Pay                                                                    │    1050.00 │
Expenses                                                                 │ \e[36m    894.89\e[0m │
  Food                                                                   │     624.29 │
  Banking Fees                                                           │      17.85 │
  Cash                                                                   │ \e[31m    -22.00\e[0m │
  Activities                                                             │ \e[36m    139.46\e[0m │
    Hockey                                                               │     112.99 │
    Skiing                                                               │      26.47 │
  Health Care                                                            │      56.25 │
  Entertainment                                                          │      16.44 │
  Toys                                                                   │      62.60 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │     155.11 │
                                                                         ╘════════════╛


_
				);
				expect_stderr("");
			});


		});

		describe(".reportBalanceSheet", sub {

			it("reports the rolled up implicit signed state of all Asset & Liability Accounts", sub {
				$Entity->reportBalanceSheet();
				expect_stdout(<<"_"
BALANCE SHEET                                                                          
─────────────────────────────────────────────────────────────────────────┬────────────┐
Assets                                                                   │ \e[36m    501.49\e[0m │
  Bank Account                                                           │     501.49 │
Liabilities                                                              │ \e[36m    300.00\e[0m │
  Personal Loan                                                          │     300.00 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │     201.49 │
                                                                         ╘════════════╛


_
				);
				expect_stderr("");
			});

			it("can report by date", sub {
				$Entity->reportBalanceSheet(
					date => "2019-03-31",
				);
				expect_stdout(<<"_"
BALANCE SHEET                                                                2019-03-31
─────────────────────────────────────────────────────────────────────────┬────────────┐
Assets                                                                   │ \e[36m    309.83\e[0m │
  Bank Account                                                           │     309.83 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │     309.83 │
                                                                         ╘════════════╛


_
				);
				expect_stderr("");
			});

		});

		describe(Console::cyan(".report"), sub {

			it("reports the financial statements by default", sub {
				$Entity->report();
				expect_stdout(<<"_"
BALANCE SHEET                                                                          
─────────────────────────────────────────────────────────────────────────┬────────────┐
Assets                                                                   │ \e[36m    501.49\e[0m │
  Bank Account                                                           │     501.49 │
Liabilities                                                              │ \e[36m    300.00\e[0m │
  Personal Loan                                                          │     300.00 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │     201.49 │
                                                                         ╘════════════╛


INCOME & EXPENSE                                                                       
─────────────────────────────────────────────────────────────────────────┬────────────┐
Income                                                                   │ \e[36m   3900.00\e[0m │
  Pay                                                                    │    3900.00 │
Expenses                                                                 │ \e[36m   3853.23\e[0m │
  Food                                                                   │    1926.23 │
  Banking Fees                                                           │     103.36 │
  Cash                                                                   │     200.00 │
  Activities                                                             │ \e[36m   1236.46\e[0m │
    Hockey                                                               │    1209.99 │
    Skiing                                                               │      26.47 │
  Health Care                                                            │     232.53 │
  Entertainment                                                          │      20.90 │
  Toys                                                                   │      62.60 │
  Drink                                                                  │      71.15 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │      46.77 │
                                                                         ╘════════════╛


_
				);
				expect_stderr("");
			});

			it("reports the financial statements by period", sub {
				foreach my $op ("--period", "-p") {
					$Entity->report($op, "2019-01:2019-06");
					expect_stdout(<<"_"
BALANCE SHEET                                                                2019-06-31
─────────────────────────────────────────────────────────────────────────┬────────────┐
Assets                                                                   │ \e[36m    216.94\e[0m │
  Bank Account                                                           │     216.94 │
Liabilities                                                              │ \e[36m    200.00\e[0m │
  Personal Loan                                                          │     200.00 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │      16.94 │
                                                                         ╘════════════╛


INCOME & EXPENSE                                                  2019-01-01:2019-06-31
─────────────────────────────────────────────────────────────────────────┬────────────┐
Income                                                                   │ \e[36m   1950.00\e[0m │
  Pay                                                                    │    1950.00 │
Expenses                                                                 │ \e[36m   2087.78\e[0m │
  Food                                                                   │    1069.97 │
  Banking Fees                                                           │      42.35 │
  Cash                                                                   │     146.00 │
  Activities                                                             │ \e[36m    661.46\e[0m │
    Hockey                                                               │     634.99 │
    Skiing                                                               │      26.47 │
  Health Care                                                            │      84.50 │
  Entertainment                                                          │      20.90 │
  Toys                                                                   │      62.60 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │ \e[31m   -137.78\e[0m │
                                                                         ╘════════════╛


_
					);
					expect_stderr("");
				}
			});

			it("reports the trial balance of all Accounts", sub {
				foreach my $op ("--trial", "-t") {
					$Entity->report($op);
					expect_stdout(<<"_"
TRIAL BALANCE                                                                          
────────────────────────────────────────────────────────────┬────────────┬────────────┐
Assets:Bank Account                                         │     346.77 │            │
Liabilities:Personal Loan                                   │            │     300.00 │
Income:Pay                                                  │            │    3900.00 │
Expenses:Food                                               │    1926.23 │            │
Expenses:Banking Fees                                       │     103.36 │            │
Expenses:Cash                                               │     200.00 │            │
Expenses:Activities:Hockey                                  │    1209.99 │            │
Expenses:Activities:Skiing                                  │      26.47 │            │
Expenses:Health Care                                        │     232.53 │            │
Expenses:Entertainment                                      │      20.90 │            │
Expenses:Toys                                               │      62.60 │            │
Expenses:Drink                                              │      71.15 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    4200.00 │    4200.00 │
                                                            ╘════════════╧════════════╛


_
					);
					expect_stderr("");
				}
			});

			it("reports the actions of Accounts by name", sub {
				foreach my $op ("--account", "-a") {
					$Entity->report($op, "Cash");
					expect_stdout(<<"_"
Expenses:Cash                                                                          
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-31 WITHDRAWL                                        │       4.00 │            │
2019-02-28 WITHDRAWL                                        │       2.00 │            │
2019-03-21 DEPOSIT                                          │            │      75.00 │
2019-03-27 ATM W/D                                          │      40.00 │            │
2019-03-31 WITHDRAWL                                        │       7.00 │            │
2019-04-23 ATM W/D                                          │     162.00 │            │
2019-04-30 WITHDRAWL                                        │       1.00 │            │
2019-05-30 WITHDRAWL                                        │       5.00 │            │
2019-07-31 WITHDRAWL                                        │       2.00 │            │
2019-09-19 WITHDRAWL                                        │      40.00 │            │
2019-09-30 WITHDRAWL                                        │       8.00 │            │
2019-10-31 WITHDRAWL                                        │       1.00 │            │
2019-11-28 WITHDRAWL                                        │       3.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │     275.00 │      75.00 │
                                                            ├────────────┼────────────┤
                                                            │     200.00 │            │
                                                            ╘════════════╧════════════╛


_
					);
					expect_stderr("");
				}
			});

			it("filters the actions of each Account by pattern", sub {
				$Entity->report("TOY");
				expect_stdout(<<"_"
Assets:Bank Account                                                                    
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-02-18 \e[32mTOY\e[0m CHAIN                                        │            │      43.98 │
2019-03-03 LOCAL \e[32mTOY\e[0m STORE                                  │            │      18.62 │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │            │      62.60 │
                                                            ├────────────┼────────────┤
                                                            │            │      62.60 │
                                                            ╘════════════╧════════════╛


Expenses:Toys                                                                          
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-02-18 \e[32mTOY\e[0m CHAIN                                        │      43.98 │            │
2019-03-03 LOCAL \e[32mTOY\e[0m STORE                                  │      18.62 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │      62.60 │            │
                                                            ├────────────┼────────────┤
                                                            │      62.60 │            │
                                                            ╘════════════╧════════════╛


_
				);
				expect_stderr("");
			});

		});

	}); # Reporting

	#───────────────────────────────────────────────────────────────────────────────────────────────
	# Session
	#───────────────────────────────────────────────────────────────────────────────────────────────

	describe("::session", sub {

		my $entity = "$ENV{TEXTBOOKS}/test/data/report.gl"; 

		Console::stdout;
		Console::stderr;

		sub expect_session {
			expect(Entity::session(@_), 1);
		}

		#
		# The following demonstrates an end-to-end command line session
		# that starts from nothing, builds a chart of accounts, imports
		# bank records, allocates those records to income & expenses
		# accounts and reports the results.  
		#

		unlink $entity;

		it("can add an Assets Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-a", 10000, "Assets");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
\e[32mASSET        10000         Assets\e[0m
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});

		it("can add a Liabilities Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-l", 20000, "Liabilities");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
\e[32mLIABILITY    20000         Liabilities\e[0m
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});
		
		it("can add an Income Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-i", 30000, "Income");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
LIABILITY    20000         Liabilities
\e[32mINCOME       30000         Income\e[0m
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});
		
		it("can add an Expenses Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", 40000, "Expenses");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
LIABILITY    20000         Liabilities
INCOME       30000         Income
\e[32mEXPENSE      40000         Expenses\e[0m
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});
		
		it("can add a Bank Account Asset Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-a", "-p", 10000, 11000, "Bank Account");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
\e[32mASSET        11000:10000   Assets:Bank Account\e[0m
LIABILITY    20000         Liabilities
INCOME       30000         Income
EXPENSE      40000         Expenses
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});

		it("can add an import rules for the Bank Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "import", "-a", "Bank", "-s", "\${TEXTBOOKS}/test/data/records/*.csv");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout("IMPORT \${TEXTBOOKS}/test/data/records/*.csv\n");
			expect_stderr("** NOTE  : Writing $entity\n");

		});
		
		it("can import bank records into the Bank Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "import");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout("");
			expect_stderr(<<"_"
** NOTE  : Importing...
\e[33m** WARN  : Importing   8 of  10 records into ACCOUNT 11000 from \${TEXTBOOKS}/test/data/records/2019-12.csv.\e[0m
** NOTE  : Imported \e[32m217\e[0m new transactions
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Pay Income Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-i", "-p", 30000, 31000, "Pay");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
\e[32mINCOME       31000:30000   Income:Pay\e[0m
EXPENSE      40000         Expenses
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});

		it("can allocate biweekly pay to the Pay Income Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "BIWEEKLY PAY", "-a", "Pay");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | BIWEEKLY PAY                                                                       ║
║ Pay                                                                       ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-01-02
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-01-16
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-01-30
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-02-13
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-02-27
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-03-13
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-03-27
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-04-10
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-04-24
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-05-08
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-05-22
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-06-05
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-06-19
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-07-03
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-07-17
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-07-31
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-08-14
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-08-28
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-09-11
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-09-25
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-10-09
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-10-23
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-11-06
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-11-20
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-12-04
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


ENTRY               \e[32mBIWEEKLY PAY\e[0m                                            , 2019-12-18
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     150.00,           
31000   Income:\e[32mPay\e[0m                                              ,           ,     150.00


_
			);
			expect_stderr(<<"_"
** NOTE  : 26 allocated, 191 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 41000, "Food");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
\e[32mEXPENSE      41000:40000   Expenses:Food\e[0m
_
			);
			expect_stderr("** NOTE  : Writing $entity\n");
		});

		it("can allocate some purchases to the Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "GROCERY", "-a", "Food", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | GROCERY                                                                            ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-01-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      28.32,           
11000   Assets:Bank Account                                     ,           ,      28.32


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-01-13
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.28,           
11000   Assets:Bank Account                                     ,           ,      24.28


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-01-20
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.09,           
11000   Assets:Bank Account                                     ,           ,      22.09


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-01-29
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.87,           
11000   Assets:Bank Account                                     ,           ,      22.87


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.09,           
11000   Assets:Bank Account                                     ,           ,      22.09


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      23.08,           
11000   Assets:Bank Account                                     ,           ,      23.08


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-18
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.99,           
11000   Assets:Bank Account                                     ,           ,      24.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-19
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.87,           
11000   Assets:Bank Account                                     ,           ,       8.87


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.09,           
11000   Assets:Bank Account                                     ,           ,      22.09


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-02-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      97.75,           
11000   Assets:Bank Account                                     ,           ,      97.75


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-03-11
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      20.99,           
11000   Assets:Bank Account                                     ,           ,      20.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-03-13
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      20.99,           
11000   Assets:Bank Account                                     ,           ,      20.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-03-18
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.87,           
11000   Assets:Bank Account                                     ,           ,      22.87


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-03-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.23,           
11000   Assets:Bank Account                                     ,           ,       8.23


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-04-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.95,           
11000   Assets:Bank Account                                     ,           ,      22.95


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-04-15
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.11,           
11000   Assets:Bank Account                                     ,           ,      24.11


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-05-02
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      20.99,           
11000   Assets:Bank Account                                     ,           ,      20.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-05-12
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.19,           
11000   Assets:Bank Account                                     ,           ,      24.19


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-05-16
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       6.92,           
11000   Assets:Bank Account                                     ,           ,       6.92


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-05-20
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.48,           
11000   Assets:Bank Account                                     ,           ,       5.48


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-06-02
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.08,           
11000   Assets:Bank Account                                     ,           ,       3.08


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-06-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.28,           
11000   Assets:Bank Account                                     ,           ,      24.28


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-06-23
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.69,           
11000   Assets:Bank Account                                     ,           ,      22.69


ENTRY               \e[32mGROCERY\e[0m MARKET                                          , 2019-06-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.17,           
11000   Assets:Bank Account                                     ,           ,       9.17


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-07-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      25.98,           
11000   Assets:Bank Account                                     ,           ,      25.98


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-07-18
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.10,           
11000   Assets:Bank Account                                     ,           ,       7.10


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-08-05
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.10,           
11000   Assets:Bank Account                                     ,           ,       7.10


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-08-14
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       6.62,           
11000   Assets:Bank Account                                     ,           ,       6.62


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-02
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.49,           
11000   Assets:Bank Account                                     ,           ,       3.49


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.72,           
11000   Assets:Bank Account                                     ,           ,      22.72


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-08
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      26.37,           
11000   Assets:Bank Account                                     ,           ,      26.37


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.06,           
11000   Assets:Bank Account                                     ,           ,       5.06


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-12
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.95,           
11000   Assets:Bank Account                                     ,           ,      22.95


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-15
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.03,           
11000   Assets:Bank Account                                     ,           ,       3.03


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-09-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      23.00,           
11000   Assets:Bank Account                                     ,           ,      23.00


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-10-06
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.76,           
11000   Assets:Bank Account                                     ,           ,       3.76


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-10-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.99,           
11000   Assets:Bank Account                                     ,           ,      22.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-10-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.69,           
11000   Assets:Bank Account                                     ,           ,      22.69


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-11-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.33,           
11000   Assets:Bank Account                                     ,           ,       7.33


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-11-06
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      25.37,           
11000   Assets:Bank Account                                     ,           ,      25.37


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-11-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      23.99,           
11000   Assets:Bank Account                                     ,           ,      23.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-11-19
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      10.44,           
11000   Assets:Bank Account                                     ,           ,      10.44


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-12-01
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      27.93,           
11000   Assets:Bank Account                                     ,           ,      27.93


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-12-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      22.99,           
11000   Assets:Bank Account                                     ,           ,      22.99


ENTRY               \e[32mGROCERY\e[0m STORE                                           , 2019-12-09
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      27.56,           
11000   Assets:Bank Account                                     ,           ,      27.56


_
			);
			expect_stderr(<<"_"
** NOTE  : 45 allocated, 146 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate more purchases to the Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "BAR", "PUB", "-a", "Food", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | BAR                                                                                ║
║ | PUB                                                                                ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-01-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      24.60,           
11000   Assets:Bank Account                                     ,           ,      24.60


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-02-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      20.40,           
11000   Assets:Bank Account                                     ,           ,      20.40


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-02-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.48,           
11000   Assets:Bank Account                                     ,           ,       7.48


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-03-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      20.40,           
11000   Assets:Bank Account                                     ,           ,      20.40


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-03-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      28.88,           
11000   Assets:Bank Account                                     ,           ,      28.88


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-03-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.48,           
11000   Assets:Bank Account                                     ,           ,       7.48


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-03-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      28.88,           
11000   Assets:Bank Account                                     ,           ,      28.88


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-04-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      17.80,           
11000   Assets:Bank Account                                     ,           ,      17.80


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-04-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.48,           
11000   Assets:Bank Account                                     ,           ,       7.48


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-04-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      13.94,           
11000   Assets:Bank Account                                     ,           ,      13.94


ENTRY               LOCAL \e[32mBAR\e[0m                                               , 2019-05-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      18.30,           
11000   Assets:Bank Account                                     ,           ,      18.30


ENTRY               LOCAL \e[32mPUB\e[0m                                               , 2019-05-22
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      31.31,           
11000   Assets:Bank Account                                     ,           ,      31.31


ENTRY               LOCAL \e[32mBAR\e[0m                                               , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      16.85,           
11000   Assets:Bank Account                                     ,           ,      16.85


ENTRY               LOCAL \e[32mPUB\e[0m                                               , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      23.12,           
11000   Assets:Bank Account                                     ,           ,      23.12


ENTRY               LOCAL \e[32mBAR\e[0m                                               , 2019-06-05
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      33.28,           
11000   Assets:Bank Account                                     ,           ,      33.28


ENTRY               LOCAL \e[32mBAR\e[0m                                               , 2019-06-13
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      27.88,           
11000   Assets:Bank Account                                     ,           ,      27.88


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-09-12
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      27.88,           
11000   Assets:Bank Account                                     ,           ,      27.88


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-10-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      25.28,           
11000   Assets:Bank Account                                     ,           ,      25.28


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-11-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      28.88,           
11000   Assets:Bank Account                                     ,           ,      28.88


ENTRY               \e[32mBAR\e[0m AND GRILL                                           , 2019-11-14
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      17.80,           
11000   Assets:Bank Account                                     ,           ,      17.80


_
			);
			expect_stderr(<<"_"
** NOTE  : 20 allocated, 126 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate more purchases to the Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "MEXICAN", "CHINESE", "LEBANESE", "THAI", "VEITNAMESE", "TEXMEX", "VEGITARIAN", "-a", "Food", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | MEXICAN                                                                            ║
║ | CHINESE                                                                            ║
║ | LEBANESE                                                                           ║
║ | THAI                                                                               ║
║ | VEITNAMESE                                                                         ║
║ | TEXMEX                                                                             ║
║ | VEGITARIAN                                                                         ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-01-16
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.80,           
11000   Assets:Bank Account                                     ,           ,       5.80


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-01-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.80,           
11000   Assets:Bank Account                                     ,           ,       5.80


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-01-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.80,           
11000   Assets:Bank Account                                     ,           ,       5.80


ENTRY               \e[32mCHINESE\e[0m                                                 , 2019-02-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.00,           
11000   Assets:Bank Account                                     ,           ,      12.00


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-03-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.00,           
11000   Assets:Bank Account                                     ,           ,      12.00


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-03-27
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-04-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-04-29
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      11.50,           
11000   Assets:Bank Account                                     ,           ,      11.50


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-07-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-07-09
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.00,           
11000   Assets:Bank Account                                     ,           ,      12.00


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-07-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mMEXICAN\e[0m                                                 , 2019-08-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.71,           
11000   Assets:Bank Account                                     ,           ,      12.71


ENTRY               \e[32mVEITNAMESE\e[0m                                              , 2019-08-11
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.93,           
11000   Assets:Bank Account                                     ,           ,      12.93


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-08-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.00,           
11000   Assets:Bank Account                                     ,           ,      12.00


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-08-29
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mVEGITARIAN\e[0m                                              , 2019-09-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      17.60,           
11000   Assets:Bank Account                                     ,           ,      17.60


ENTRY               \e[32mTEXMEX\e[0m                                                  , 2019-09-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      35.37,           
11000   Assets:Bank Account                                     ,           ,      35.37


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-09-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      11.50,           
11000   Assets:Bank Account                                     ,           ,      11.50


ENTRY               \e[32mTHAI\e[0m                                                    , 2019-10-03
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      11.50,           
11000   Assets:Bank Account                                     ,           ,      11.50


ENTRY               \e[32mMEXICAN\e[0m                                                 , 2019-10-14
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      12.15,           
11000   Assets:Bank Account                                     ,           ,      12.15


ENTRY               \e[32mCHINESE\e[0m                                                 , 2019-10-20
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      11.39,           
11000   Assets:Bank Account                                     ,           ,      11.39


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-10-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


ENTRY               \e[32mLEBANESE\e[0m                                                , 2019-11-18
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.99,           
11000   Assets:Bank Account                                     ,           ,       5.99


_
			);
			expect_stderr(<<"_"
** NOTE  : 23 allocated, 103 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate more purchases to the Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "FAST FOOD", "SANDWICH", "WATERING", "BULK FOOD", "BURGER", "SNACK", "COFFEE", "BAKERY", "-a", "Food", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FAST FOOD                                                                          ║
║ | SANDWICH                                                                           ║
║ | WATERING                                                                           ║
║ | BULK FOOD                                                                          ║
║ | BURGER                                                                             ║
║ | SNACK                                                                              ║
║ | COFFEE                                                                             ║
║ | BAKERY                                                                             ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-01-13
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.44,           
11000   Assets:Bank Account                                     ,           ,       8.44


ENTRY               \e[32mWATERING\e[0m HOLE                                           , 2019-01-15
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      15.49,           
11000   Assets:Bank Account                                     ,           ,      15.49


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-01-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      13.42,           
11000   Assets:Bank Account                                     ,           ,      13.42


ENTRY               SUB \e[32mSANDWICH\e[0m                                            , 2019-01-30
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.13,           
11000   Assets:Bank Account                                     ,           ,       9.13


ENTRY               SUB \e[32mSANDWICH\e[0m                                            , 2019-03-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.79,           
11000   Assets:Bank Account                                     ,           ,       8.79


ENTRY               \e[32mWATERING\e[0m HOLE                                           , 2019-03-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      14.00,           
11000   Assets:Bank Account                                     ,           ,      14.00


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-04-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.48,           
11000   Assets:Bank Account                                     ,           ,       5.48


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-04-14
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.45,           
11000   Assets:Bank Account                                     ,           ,       3.45


ENTRY               \e[32mBULK FOOD\e[0m                                               , 2019-05-09
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       6.73,           
11000   Assets:Bank Account                                     ,           ,       6.73


ENTRY               \e[32mBULK FOOD\e[0m                                               , 2019-05-23
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.72,           
11000   Assets:Bank Account                                     ,           ,       8.72


ENTRY               \e[32mWATERING\e[0m HOLE                                           , 2019-07-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      29.05,           
11000   Assets:Bank Account                                     ,           ,      29.05


ENTRY               \e[32mBURGER\e[0m JOINT                                            , 2019-07-07
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.58,           
11000   Assets:Bank Account                                     ,           ,       8.58


ENTRY               \e[32mBURGER\e[0m PLACE                                            , 2019-07-11
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.89,           
11000   Assets:Bank Account                                     ,           ,       9.89


ENTRY               \e[32mBURGER\e[0m JOINT                                            , 2019-08-05
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.90,           
11000   Assets:Bank Account                                     ,           ,       7.90


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-08-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.40,           
11000   Assets:Bank Account                                     ,           ,       5.40


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-08-25
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.32,           
11000   Assets:Bank Account                                     ,           ,       5.32


ENTRY               \e[32mBAKERY\e[0m                                                  , 2019-09-22
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.63,           
11000   Assets:Bank Account                                     ,           ,       5.63


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-09-22
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.75,           
11000   Assets:Bank Account                                     ,           ,       5.75


ENTRY               SUB \e[32mSANDWICH\e[0m                                            , 2019-09-23
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.13,           
11000   Assets:Bank Account                                     ,           ,       9.13


ENTRY               \e[32mBURGER\e[0m JOINT                                            , 2019-10-06
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.69,           
11000   Assets:Bank Account                                     ,           ,       8.69


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-10-06
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.10,           
11000   Assets:Bank Account                                     ,           ,       5.10


ENTRY               SUB \e[32mSANDWICH\e[0m                                            , 2019-10-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.13,           
11000   Assets:Bank Account                                     ,           ,       9.13


ENTRY               \e[32mBURGER\e[0m JOINT                                            , 2019-11-04
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       5.64,           
11000   Assets:Bank Account                                     ,           ,       5.64


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-11-10
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      19.52,           
11000   Assets:Bank Account                                     ,           ,      19.52


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-11-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.82,           
11000   Assets:Bank Account                                     ,           ,       8.82


ENTRY               \e[32mCOFFEE\e[0m                                                  , 2019-11-17
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       3.14,           
11000   Assets:Bank Account                                     ,           ,       3.14


ENTRY               \e[32mFAST FOOD\e[0m                                               , 2019-11-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      14.55,           
11000   Assets:Bank Account                                     ,           ,      14.55


ENTRY               SUB \e[32mSANDWICH\e[0m                                            , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       7.67,           
11000   Assets:Bank Account                                     ,           ,       7.67


ENTRY               \e[32mSNACK\e[0mS                                                  , 2019-12-05
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       8.48,           
11000   Assets:Bank Account                                     ,           ,       8.48


ENTRY               \e[32mBURGER\e[0m JOINT                                            , 2019-12-15
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       9.03,           
11000   Assets:Bank Account                                     ,           ,       9.03


_
			);
			expect_stderr(<<"_"
** NOTE  : 30 allocated, 73 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate more purchases to the Food Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "CREOLE", "BUTCHER", "PIT STOP", "-a", "Food");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | CREOLE                                                                             ║
║ | BUTCHER                                                                            ║
║ | PIT STOP                                                                           ║
║ Food                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mCREOLE\e[0m                                                  , 2019-04-24
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      45.48,           
11000   Assets:Bank Account                                     ,           ,      45.48


ENTRY               \e[32mPIT STOP\e[0m                                                , 2019-05-16
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,       4.51,           
11000   Assets:Bank Account                                     ,           ,       4.51


ENTRY               SPECIALTY \e[32mBUTCHER\e[0m                                       , 2019-07-14
────────────────────────────────────────────────────────────────────────────────────────
41000   Expenses:\e[32mFood\e[0m                                           ,      42.43,           
11000   Assets:Bank Account                                     ,           ,      42.43


_
			);
			expect_stderr(<<"_"
** NOTE  : 3 allocated, 70 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Banking Fee Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 42000, "Banking Fees");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
\e[32mEXPENSE      42000:40000   Expenses:Banking Fees\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some fees to the Banking Fees Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "FEE", "OVERDRAFT", "-a", "Fees", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | FEE                                                                                ║
║ | OVERDRAFT                                                                          ║
║ Fees                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-01-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-01-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-02-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-02-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-03-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-03-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-04-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-04-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               OTHER BANK \e[32mFEE\e[0mS                                         , 2019-04-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       1.50,           
11000   Assets:Bank Account                                     ,           ,       1.50


ENTRY               PODP \e[32mFEE\e[0m MAY/23/2019                                    , 2019-05-27
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               \e[32mOVERDRAFT\e[0m INTEREST                                      , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       0.15,           
11000   Assets:Bank Account                                     ,           ,       0.15


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-06-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-06-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-07-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-07-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-08-29
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-08-29
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               PODP \e[32mFEE\e[0m SEP/17/2019                                    , 2019-09-19
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               PODP \e[32mFEE\e[0m SEP/19/2019                                    , 2019-09-23
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               PODP \e[32mFEE\e[0m SEP/22/2019                                    , 2019-09-24
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               PODP \e[32mFEE\e[0m SEP/23/2019                                    , 2019-09-25
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               PODP \e[32mFEE\e[0m SEP/24/2019                                    , 2019-09-26
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               \e[32mOVERDRAFT\e[0m INTEREST                                      , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       0.31,           
11000   Assets:Bank Account                                     ,           ,       0.31


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               MONTHLY ACCOUNT \e[32mFEE\e[0m                                     , 2019-12-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       3.95,           
11000   Assets:Bank Account                                     ,           ,       3.95


ENTRY               CHQ RETURN \e[32mFEE\e[0m                                          , 2019-12-31
────────────────────────────────────────────────────────────────────────────────────────
42000   Expenses:Banking \e[32mFees\e[0m                                   ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


_
			);
			expect_stderr(<<"_"
** NOTE  : 33 allocated, 37 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Cash Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 43000, "Cash");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
\e[32mEXPENSE      43000:40000   Expenses:Cash\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some activity to the Cash Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "WITHDRAWL", "DEPOSIT", "ATM", "-a", "Cash", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | WITHDRAWL                                                                          ║
║ | DEPOSIT                                                                            ║
║ | ATM                                                                                ║
║ Cash                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-01-31
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       4.00,           
11000   Assets:Bank Account                                     ,           ,       4.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-02-28
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               \e[32mDEPOSIT\e[0m                                                 , 2019-03-21
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,      75.00,           
43000   Expenses:\e[32mCash\e[0m                                           ,           ,      75.00


ENTRY               \e[32mATM\e[0m W/D                                                 , 2019-03-27
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,      40.00,           
11000   Assets:Bank Account                                     ,           ,      40.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-03-31
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       7.00,           
11000   Assets:Bank Account                                     ,           ,       7.00


ENTRY               \e[32mATM\e[0m W/D                                                 , 2019-04-23
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,     162.00,           
11000   Assets:Bank Account                                     ,           ,     162.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-04-30
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       1.00,           
11000   Assets:Bank Account                                     ,           ,       1.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-05-30
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       5.00,           
11000   Assets:Bank Account                                     ,           ,       5.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-07-31
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       2.00,           
11000   Assets:Bank Account                                     ,           ,       2.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-09-19
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,      40.00,           
11000   Assets:Bank Account                                     ,           ,      40.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       8.00,           
11000   Assets:Bank Account                                     ,           ,       8.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-10-31
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       1.00,           
11000   Assets:Bank Account                                     ,           ,       1.00


ENTRY               \e[32mWITHDRAWL\e[0m                                               , 2019-11-28
────────────────────────────────────────────────────────────────────────────────────────
43000   Expenses:\e[32mCash\e[0m                                           ,       3.00,           
11000   Assets:Bank Account                                     ,           ,       3.00


_
			);
			expect_stderr(<<"_"
** NOTE  : 13 allocated, 24 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add an Activities Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 44000, "Activities");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
\e[32mEXPENSE      44000:40000   Expenses:Activities\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can add an Hockey Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 44000, 44100, "Hockey");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
\e[32mEXPENSE      44100:44000   Expenses:Activities:Hockey\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can add an Skiing Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 44000, 44200, "Skiing");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
\e[32mEXPENSE      44200:44000   Expenses:Activities:Skiing\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some purchases to the Hockey Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "HOCKEY GEAR", "-a", "Hockey", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | HOCKEY GEAR                                                                        ║
║ Hockey                                                                    ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mHOCKEY GEAR\e[0m                                             , 2019-01-13
────────────────────────────────────────────────────────────────────────────────────────
44100   Expenses:Activities:\e[32mHockey\e[0m                              ,     112.99,           
11000   Assets:Bank Account                                     ,           ,     112.99


_
			);
			expect_stderr(<<"_"
** NOTE  : 1 allocated, 23 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate more purchases to the Hockey Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "SKATE REPAIR", "CHQ#00084", "CHQ#00085", "CHQ#00087", "-a", "Hockey");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | SKATE REPAIR                                                                       ║
║ | CHQ#00084                                                                          ║
║ | CHQ#00085                                                                          ║
║ | CHQ#00087                                                                          ║
║ Hockey                                                                    ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mCHQ#00084\e[0m                                               , 2019-05-12
────────────────────────────────────────────────────────────────────────────────────────
44100   Expenses:Activities:\e[32mHockey\e[0m                              ,     205.00,           
11000   Assets:Bank Account                                     ,           ,     205.00


ENTRY               \e[32mCHQ#00085\e[0m                                               , 2019-05-23
────────────────────────────────────────────────────────────────────────────────────────
44100   Expenses:Activities:\e[32mHockey\e[0m                              ,     310.00,           
11000   Assets:Bank Account                                     ,           ,     310.00


ENTRY               \e[32mSKATE REPAIR\e[0m                                            , 2019-06-10
────────────────────────────────────────────────────────────────────────────────────────
44100   Expenses:Activities:\e[32mHockey\e[0m                              ,       7.00,           
11000   Assets:Bank Account                                     ,           ,       7.00


ENTRY               \e[32mCHQ#00087\e[0m                                               , 2019-09-17
────────────────────────────────────────────────────────────────────────────────────────
44100   Expenses:Activities:\e[32mHockey\e[0m                              ,     575.00,           
11000   Assets:Bank Account                                     ,           ,     575.00


_
			);
			expect_stderr(<<"_"
** NOTE  : 4 allocated, 19 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some purchases to the Skiing Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "SKI", "-a", "Skiing", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | SKI                                                                                ║
║ Skiing                                                                    ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               LOCAL \e[32mSKI\e[0m HILL                                          , 2019-01-27
────────────────────────────────────────────────────────────────────────────────────────
44200   Expenses:Activities:\e[32mSkiing\e[0m                              ,      11.50,           
11000   Assets:Bank Account                                     ,           ,      11.50


ENTRY               \e[32mSKI\e[0m MOUNTAIN                                            , 2019-03-10
────────────────────────────────────────────────────────────────────────────────────────
44200   Expenses:Activities:\e[32mSkiing\e[0m                              ,       4.99,           
11000   Assets:Bank Account                                     ,           ,       4.99


ENTRY               \e[32mSKI\e[0m MOUNTAIN                                            , 2019-03-10
────────────────────────────────────────────────────────────────────────────────────────
44200   Expenses:Activities:\e[32mSkiing\e[0m                              ,       9.98,           
11000   Assets:Bank Account                                     ,           ,       9.98


_
			);
			expect_stderr(<<"_"
** NOTE  : 3 allocated, 16 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Personal Loan Liability Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-l", "-p", 20000, 21000, "Personal Loan");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
\e[32mLIABILITY    21000:20000   Liabilities:Personal Loan\e[0m
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
EXPENSE      44200:44000   Expenses:Activities:Skiing
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some borrowing to the Personal Loan Liability Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "LOAN", "-a", "Loan", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | LOAN                                                                               ║
║ Loan                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mLOAN\e[0m                                                    , 2019-05-26
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     200.00,           
21000   Liabilities:Personal \e[32mLoan\e[0m                               ,           ,     200.00


ENTRY               \e[32mLOAN\e[0m                                                    , 2019-09-25
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Bank Account                                     ,     100.00,           
21000   Liabilities:Personal \e[32mLoan\e[0m                               ,           ,     100.00


_
			);
			expect_stderr(<<"_"
** NOTE  : 2 allocated, 14 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Health Care Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 45000, "Health Care");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
EXPENSE      44200:44000   Expenses:Activities:Skiing
\e[32mEXPENSE      45000:40000   Expenses:Health Care\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some expenses to the Health Care Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "SALON", "PHARMACY", "DRUG STORE", "-a", "Health", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | SALON                                                                              ║
║ | PHARMACY                                                                           ║
║ | DRUG STORE                                                                         ║
║ Health                                                                    ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mPHARMACY\e[0m                                                , 2019-02-13
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      28.00,           
11000   Assets:Bank Account                                     ,           ,      28.00


ENTRY               HAIR \e[32mSALON\e[0m                                              , 2019-02-18
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      28.25,           
11000   Assets:Bank Account                                     ,           ,      28.25


ENTRY               HAIR \e[32mSALON\e[0m                                              , 2019-05-08
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      28.25,           
11000   Assets:Bank Account                                     ,           ,      28.25


ENTRY               HAIR \e[32mSALON\e[0m                                              , 2019-07-11
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      60.69,           
11000   Assets:Bank Account                                     ,           ,      60.69


ENTRY               \e[32mPHARMACY\e[0m                                                , 2019-07-17
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      14.56,           
11000   Assets:Bank Account                                     ,           ,      14.56


ENTRY               HAIR \e[32mSALON\e[0m                                              , 2019-09-08
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      28.25,           
11000   Assets:Bank Account                                     ,           ,      28.25


ENTRY               \e[32mDRUG STORE\e[0m                                              , 2019-09-30
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      16.28,           
11000   Assets:Bank Account                                     ,           ,      16.28


ENTRY               HAIR \e[32mSALON\e[0m                                              , 2019-12-01
────────────────────────────────────────────────────────────────────────────────────────
45000   Expenses:\e[32mHealth\e[0m Care                                    ,      28.25,           
11000   Assets:Bank Account                                     ,           ,      28.25


_
			);
			expect_stderr(<<"_"
** NOTE  : 8 allocated, 6 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Entertainment Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 46000, "Entertainment");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
EXPENSE      44200:44000   Expenses:Activities:Skiing
EXPENSE      45000:40000   Expenses:Health Care
\e[32mEXPENSE      46000:40000   Expenses:Entertainment\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some purchases to the Entertainment Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "CINEPLEX", "BOOK STORE", "-a", "Entertainment", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | CINEPLEX                                                                           ║
║ | BOOK STORE                                                                         ║
║ Entertainment                                                             ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mCINEPLEX\e[0m                                                , 2019-03-10
────────────────────────────────────────────────────────────────────────────────────────
46000   Expenses:\e[32mEntertainment\e[0m                                  ,      16.44,           
11000   Assets:Bank Account                                     ,           ,      16.44


ENTRY               \e[32mBOOK STORE\e[0m                                              , 2019-05-26
────────────────────────────────────────────────────────────────────────────────────────
46000   Expenses:\e[32mEntertainment\e[0m                                  ,       4.46,           
11000   Assets:Bank Account                                     ,           ,       4.46


_
			);
			expect_stderr(<<"_"
** NOTE  : 2 allocated, 4 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Toys Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 47000, "Toys");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
EXPENSE      44200:44000   Expenses:Activities:Skiing
EXPENSE      45000:40000   Expenses:Health Care
EXPENSE      46000:40000   Expenses:Entertainment
\e[32mEXPENSE      47000:40000   Expenses:Toys\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some purchases to the Toys Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "TOY", "-a", "Toys", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | TOY                                                                                ║
║ Toys                                                                      ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               \e[32mTOY\e[0m CHAIN                                               , 2019-02-18
────────────────────────────────────────────────────────────────────────────────────────
47000   Expenses:\e[32mToys\e[0m                                           ,      43.98,           
11000   Assets:Bank Account                                     ,           ,      43.98


ENTRY               LOCAL \e[32mTOY\e[0m STORE                                         , 2019-03-03
────────────────────────────────────────────────────────────────────────────────────────
47000   Expenses:\e[32mToys\e[0m                                           ,      18.62,           
11000   Assets:Bank Account                                     ,           ,      18.62


_
			);
			expect_stderr(<<"_"
** NOTE  : 2 allocated, 2 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can add a Drink Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "chart", "-e", "-p", 40000, 48000, "Drink");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
ASSET        10000         Assets
ASSET        11000:10000   Assets:Bank Account
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Personal Loan
INCOME       30000         Income
INCOME       31000:30000   Income:Pay
EXPENSE      40000         Expenses
EXPENSE      41000:40000   Expenses:Food
EXPENSE      42000:40000   Expenses:Banking Fees
EXPENSE      43000:40000   Expenses:Cash
EXPENSE      44000:40000   Expenses:Activities
EXPENSE      44100:44000   Expenses:Activities:Hockey
EXPENSE      44200:44000   Expenses:Activities:Skiing
EXPENSE      45000:40000   Expenses:Health Care
EXPENSE      46000:40000   Expenses:Entertainment
EXPENSE      47000:40000   Expenses:Toys
\e[32mEXPENSE      48000:40000   Expenses:Drink\e[0m
_
			);
			expect_stderr(<<"_"
** NOTE  : Writing $entity
_
			);
		});

		it("can allocate some purchases to the Drink Expense Account", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session("-c", $entity, "alloc", "LCBO", "BEER", "-a", "Drink", "-k");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
╔══════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                      ║
║ | LCBO                                                                               ║
║ | BEER                                                                               ║
║ Drink                                                                     ,          ║
║                                                                                      ║
╚══════════════════════════════════════════════════════════════════════════════════════╝


ENTRY               THE \e[32mBEER\e[0m STORE                                          , 2019-07-11
────────────────────────────────────────────────────────────────────────────────────────
48000   Expenses:\e[32mDrink\e[0m                                          ,      44.95,           
11000   Assets:Bank Account                                     ,           ,      44.95


ENTRY               \e[32mLCBO\e[0m/RAO                                                , 2019-08-05
────────────────────────────────────────────────────────────────────────────────────────
48000   Expenses:\e[32mDrink\e[0m                                          ,      26.20,           
11000   Assets:Bank Account                                     ,           ,      26.20


_
			);
			expect_stderr(<<"_"
** NOTE  : 2 allocated, 0 to go.
** NOTE  : Writing $entity
_
			);
		});

		it("can report a trial balance for a period", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session($entity, "report", "--trial", "--period", "2019-01:2019-03");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
TRIAL BALANCE                                                     2019-01-01:2019-03-31
────────────────────────────────────────────────────────────┬────────────┬────────────┐
Assets:Bank Account                                         │     155.11 │            │
Income:Pay                                                  │            │    1050.00 │
Expenses:Food                                               │     624.29 │            │
Expenses:Banking Fees                                       │      17.85 │            │
Expenses:Cash                                               │            │      22.00 │
Expenses:Activities:Hockey                                  │     112.99 │            │
Expenses:Activities:Skiing                                  │      26.47 │            │
Expenses:Health Care                                        │      56.25 │            │
Expenses:Entertainment                                      │      16.44 │            │
Expenses:Toys                                               │      62.60 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    1072.00 │    1072.00 │
                                                            ╘════════════╧════════════╛


_
			);
			expect_stderr("");
		});

		it("can report a balance sheet and income & expenses", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session($entity, "report");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
BALANCE SHEET                                                                          
─────────────────────────────────────────────────────────────────────────┬────────────┐
Assets                                                                   │ \e[36m    501.49\e[0m │
  Bank Account                                                           │     501.49 │
Liabilities                                                              │ \e[36m    300.00\e[0m │
  Personal Loan                                                          │     300.00 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │     201.49 │
                                                                         ╘════════════╛


INCOME & EXPENSE                                                                       
─────────────────────────────────────────────────────────────────────────┬────────────┐
Income                                                                   │ \e[36m   3900.00\e[0m │
  Pay                                                                    │    3900.00 │
Expenses                                                                 │ \e[36m   3853.23\e[0m │
  Food                                                                   │    1926.23 │
  Banking Fees                                                           │     103.36 │
  Cash                                                                   │     200.00 │
  Activities                                                             │ \e[36m   1236.46\e[0m │
    Hockey                                                               │    1209.99 │
    Skiing                                                               │      26.47 │
  Health Care                                                            │     232.53 │
  Entertainment                                                          │      20.90 │
  Toys                                                                   │      62.60 │
  Drink                                                                  │      71.15 │
─────────────────────────────────────────────────────────────────────────┼────────────┤
                                                                         │      46.77 │
                                                                         ╘════════════╛


_
			);
			expect_stderr("");
		});

		it("can report an account ledger", sub {
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_session($entity, "report", "--account", "Hockey");
			#───────────────────────────────────────────────────────────────────────────────────────
			expect_stdout(<<"_"
Expenses:Activities:Hockey                                                             
────────────────────────────────────────────────────────────┬────────────┬────────────┐
2019-01-13 HOCKEY GEAR                                      │     112.99 │            │
2019-05-12 CHQ#00084                                        │     205.00 │            │
2019-05-23 CHQ#00085                                        │     310.00 │            │
2019-06-10 SKATE REPAIR                                     │       7.00 │            │
2019-09-17 CHQ#00087                                        │     575.00 │            │
────────────────────────────────────────────────────────────┼────────────┼────────────┤
                                                            │    1209.99 │            │
                                                            ├────────────┼────────────┤
                                                            │    1209.99 │            │
                                                            ╘════════════╧════════════╛


_
			);
			expect_stderr("");
		});

	}); # ::session

}); # Entity

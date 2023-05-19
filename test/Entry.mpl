use lib ("$ENV{TEXTBOOKS}/lib");
use Account();
use Action();
use Allocation();
use Entity();
use Entry();


#$Console::TESTING = 1; # Capture errors instead of existing & don't actually output the messages

sub mock_Chart {

	# new Account(type, number, parent|Parent, label, Line);

	my $Assets      = new Account('A', 10000, undef       , 'Assets'             );
	my $Cash        = new Account('A', 11000, $Assets     , 'Cash'               );
	my $AR          = new Account('A', 12000, $Assets     , 'Accounts Receivable');
	my $CustomerA   = new Account('A', 12100, $AR         , 'Customer A'         );
	my $Liabilities = new Account('L', 20000, undef       , 'Liabilities'        );
	my $AP          = new Account('L', 21000, $Liabilities, 'Accounts Payable'   );
	my $ProviderX   = new Account('L', 21100, $AP         , 'Provider X'         );
	my $Income      = new Account('I', 30000, undef       , 'Income'             );
	my $WidgetJ     = new Account('I', 31000, $Income     , 'Widget J'           );
	my $WidgetK     = new Account('I', 32000, $Income     , 'Widget K'           );
	my $Expense     = new Account('E', 40000, undef       , 'Expense'            );
	my $ServiceY    = new Account('E', 41000, $Expense    , 'Service Y'          );

	my @Accounts   = (
		$Assets, $Cash, $AR, $CustomerA, 
		$Liabilities, $AP, $ProviderX,
		$Income, $WidgetJ, $WidgetK,
		$Expense, $ServiceY
	);

	return @Accounts;

}

my $INVOICE = <<'_';
ENTRY               Order                                                   , 2020-05-17
────────────────────────────────────────────────────────────────────────────────────────
12100   Assets:Accounts Receivable:Customer A                   ,     100.00,           
31000   Income:Widget J                                         ,           ,      75.00
32000   Income:Widget K                                         ,           ,      25.00


ACCOUNT 12100       Assets:Accounts Receivable:Customer A
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-17,       , Order                                       ,     100.00,           ,     100.00


ACCOUNT 31000       Income:Widget J
────────────────────────────────────────────────────────────────────────────────────────
2020-05-17,       , Order                                       ,           ,      75.00


ACCOUNT 32000       Income:Widget K
────────────────────────────────────────────────────────────────────────────────────────
2020-05-17,       , Order                                       ,           ,      25.00


_

my $CUSTOMERPAYMENT = <<'_';
ENTRY               Order Payment                                           , 2020-05-19
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Cash                                             ,     100.00,           
12100   Assets:Accounts Receivable:Customer A                   ,           ,     100.00


ACCOUNT 12100       Assets:Accounts Receivable:Customer A
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-17,       , Order                                       ,     100.00,           ,     100.00
2020-05-19,       , Order Payment                               ,           ,     100.00,       0.00


ACCOUNT 11000       Assets:Cash
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-19,       , Order Payment                               ,     100.00,           ,     100.00


_

my $BILL = <<'_';
ENTRY               Service Billing                                         , 2020-05-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:Service Y                                       ,      67.24,           
21100   Liabilities:Accounts Payable:Provider X                 ,           ,      67.24


ACCOUNT 41000       Expense:Service Y
────────────────────────────────────────────────────────────────────────────────────────
2020-05-21,       , Service Billing                             ,      67.24,           


ACCOUNT 21100       Liabilities:Accounts Payable:Provider X
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-21,       , Service Billing                             ,           ,      67.24,      67.24


_

my $VENDORPAYMENT = <<'_';
ENTRY               Bill Payment                                            , 2020-05-31
────────────────────────────────────────────────────────────────────────────────────────
21100   Liabilities:Accounts Payable:Provider X                 ,      67.24,           
11000   Assets:Cash                                             ,           ,      67.24


ACCOUNT 21100       Liabilities:Accounts Payable:Provider X
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-21,       , Service Billing                             ,           ,      67.24,      67.24
2020-05-31,       , Bill Payment                                ,      67.24,           ,       0.00


ACCOUNT 11000       Assets:Cash
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-19,       , Order Payment                               ,     100.00,           ,     100.00
2020-05-31,       , Bill Payment                                ,           ,      67.24,      32.76


_

my $ENTRIES = <<'_';
ENTRY   000020      Order                                                   , 2020-05-17
────────────────────────────────────────────────────────────────────────────────────────
12100   Assets:Accounts Receivable:Customer A                   ,     100.00,           
31000   Income:Widget J                                         ,           ,      75.00
32000   Income:Widget K                                         ,           ,      25.00


ENTRY   000021      Order Payment                                           , 2020-05-19
────────────────────────────────────────────────────────────────────────────────────────
11000   Assets:Cash                                             ,     100.00,           
12100   Assets:Accounts Receivable:Customer A                   ,           ,     100.00


ENTRY   000022      Service Billing                                         , 2020-05-21
────────────────────────────────────────────────────────────────────────────────────────
41000   Expense:Service Y                                       ,      67.24,           
21100   Liabilities:Accounts Payable:Provider X                 ,           ,      67.24


ENTRY   000023      Bill Payment                                            , 2020-05-31
────────────────────────────────────────────────────────────────────────────────────────
21100   Liabilities:Accounts Payable:Provider X                 ,      67.24,           
11000   Assets:Cash                                             ,           ,      67.24


_

my $LEDGERS = <<'_';
ACCOUNT 11000       Assets:Cash
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-19, 000021, Order Payment                               ,     100.00,           ,     100.00
2020-05-31, 000023, Bill Payment                                ,           ,      67.24,      32.76


ACCOUNT 12100       Assets:Accounts Receivable:Customer A
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-17, 000020, Order                                       ,     100.00,           ,     100.00
2020-05-19, 000021, Order Payment                               ,           ,     100.00,       0.00


ACCOUNT 21100       Liabilities:Accounts Payable:Provider X
────────────────────────────────────────────────────────────────────────────────────────────────────
2020-05-21, 000022, Service Billing                             ,           ,      67.24,      67.24
2020-05-31, 000023, Bill Payment                                ,      67.24,           ,       0.00


ACCOUNT 31000       Income:Widget J
────────────────────────────────────────────────────────────────────────────────────────
2020-05-17, 000020, Order                                       ,           ,      75.00


ACCOUNT 32000       Income:Widget K
────────────────────────────────────────────────────────────────────────────────────────
2020-05-17, 000020, Order                                       ,           ,      25.00


ACCOUNT 41000       Expense:Service Y
────────────────────────────────────────────────────────────────────────────────────────
2020-05-21, 000022, Service Billing                             ,      67.24,           


_


describe("Entry", sub {

	my @Accounts = mock_Chart();
	my ($Assets, $Cash, $AR, $CustomerA, 
		$Liabilities, $AP, $ProviderX,
		$Income, $WidgetJ, $WidgetK,
		$Expense, $ServiceY) = @Accounts;

	my ($Invoice, $CustomerPayment, $Bill, $VendorPayment);

	describe("new", sub {

		it("creates a numbered Entity", sub {
			my $Entry = new Entry(number=> 1, date=>'2020-05-19', item=>'Test Entry');
			expect($Entry->{number}, 1);
			expect($Entry->{date}  , '2020-05-19');
			expect($Entry->{item}  , 'Test Entry');
			expect(scalar @{$Entry->{debits}},  0);
			expect(scalar @{$Entry->{credits}}, 0);
		});

		it("creates an unnumbered Entity", sub {
			my $Entry = new Entry(date=>'2020-05-19', item=>'Test Entry');
			expect($Entry->{number}, undef);
			expect($Entry->{date}  , '2020-05-19');
			expect($Entry->{item}  , 'Test Entry');
			expect(scalar @{$Entry->{debits}},  0);
			expect(scalar @{$Entry->{credits}}, 0);
		});

	});

	describe(".number", sub {
		
		it("gets the Entry number", sub {
			my $Entry = new Entry(number=> 12);
			expect($Entry->number, 12);
		});

		it("sets the Entry number", sub {
			my $Entry = new Entry();
			expect($Entry->number, undef);
			expect($Entry->number(12), 12);
			expect($Entry->number, 12);
		});

	});

	describe(".date", sub {

		it("gets the Entry date", sub {
			my $Entry = new Entry(date => "2020-05-19");
			expect($Entry->date, "2020-05-19");
		});

	});

	describe(".item", sub {

		it("gets the Entry item", sub {
			my $Entry = new Entry(item => "Test Item");
			expect($Entry->item, "Test Item");
		});

	});

	describe(".debits", sub {

		it("gets the list of Entry debits", sub {
			my $Entry = new Entry();
			expect(scalar $Entry->debits, 0);
			push @{$Entry->{debits}}, "Test";
			expect(scalar $Entry->debits, 1);
			expect(($Entry->debits)[0], "Test");
		});

	});

	describe(".credits", sub {

		it("gets the list of Entry credits", sub {
			my $Entry = new Entry();
			expect(scalar $Entry->credits, 0);
			push @{$Entry->{credits}}, "Test";
			expect(scalar $Entry->credits, 1);
			expect(($Entry->credits)[0], "Test");
		});

	});

	describe(".debit", sub {

		it("adds a debit amount to the Entry and adds an Action to the Account", sub {
			my $Entry   = new Entry(date=>'2020-05-17', item=>'Test');
			my $Account = new Account('E', 0, undef, 'Test');

			expect(scalar $Entry->debits, 0);
			expect(scalar $Account->Actions, 0);
			$Entry->debit($Account, 100);
			expect(scalar $Entry->debits, 1);
			expect(($Entry->debits)[0]->{Account}, $Account);
			expect(($Entry->debits)[0]->{amount} , 100);
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->debit, 100);
			expect(($Account->Actions)[0]->Entry, $Entry);
		});

		it("adds a debit amount to the Entry and can omit the Action to the Account", sub {
			my $Account = new Account('I', 0, undef, 'Test');
			my $Action  = $Account->action(undef, date=>'2020-05-17', item=>'Test', debit=>100);

			# The Account has an unallocated Action
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->Entry , undef);
			expect(($Account->Actions)[0]->date  , '2020-05-17');
			expect(($Account->Actions)[0]->item  , 'Test');
			expect(($Account->Actions)[0]->debit , 100);
			expect(($Account->Actions)[0]->credit, 0);
			# Create an Entry for that Action
			my $Entry = new Entry(date=>$Action->date, item=>$Action->item);
			expect(scalar $Entry->debits, 0);
			# Add the debit to the Entry, but not the Account since it already has the Action
			$Entry->debit($Account, $Action->debit, $Action);
			expect(scalar $Entry->debits, 1);
			expect(($Entry->debits)[0]->{Account}, $Account);
			expect(($Entry->debits)[0]->{amount} , 100);
			# Check that the unallocated Action hasn't changed, but now has an Entry
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->Entry , $Entry);
			expect(($Account->Actions)[0]->date  , '2020-05-17');
			expect(($Account->Actions)[0]->item  , 'Test');
			expect(($Account->Actions)[0]->debit , 100);
			expect(($Account->Actions)[0]->credit, 0);
		});

	});

	describe(".credit", sub {

		it("adds a credit amount to the Entry and adds an Action to the Account", sub {
			my $Entry   = new Entry(date=>'2020-05-17', item=>'Test');
			my $Account = new Account('E', 0, undef, 'Test');

			expect(scalar $Entry->credits, 0);
			expect(scalar $Account->Actions, 0);
			$Entry->credit($Account, 100);
			expect(scalar $Entry->credits, 1);
			expect(($Entry->credits)[0]->{Account}, $Account);
			expect(($Entry->credits)[0]->{amount} , 100);
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->credit, 100);
			expect(($Account->Actions)[0]->Entry , $Entry);
		});

		it("adds a credit amount to the Entry and can omit the Action to the Account", sub {
			my $Account = new Account('I', 0, undef, 'Test');
			my $Action  = $Account->action(undef, date=>'2020-05-17', item=>'Test', credit=>100);

			# The Account has an unallocated Action
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->Entry , undef);
			expect(($Account->Actions)[0]->date  , '2020-05-17');
			expect(($Account->Actions)[0]->item  , 'Test');
			expect(($Account->Actions)[0]->debit , 0);
			expect(($Account->Actions)[0]->credit, 100);
			# Create an Entry for that Action
			my $Entry = new Entry(date=>$Action->date, item=>$Action->item);
			expect(scalar $Entry->credits, 0);
			# Add the credit to the Entry, but not the Account since it already has the Action
			$Entry->credit($Account, $Action->credit, $Action);
			expect(scalar $Entry->credits, 1);
			expect(($Entry->credits)[0]->{Account}, $Account);
			expect(($Entry->credits)[0]->{amount} , 100);
			# Check that the unallocated Action hasn't changed, but now has an Entry
			expect(scalar $Account->Actions, 1);
			expect(($Account->Actions)[0]->Entry , $Entry);
			expect(($Account->Actions)[0]->date  , '2020-05-17');
			expect(($Account->Actions)[0]->item  , 'Test');
			expect(($Account->Actions)[0]->debit , 0);
			expect(($Account->Actions)[0]->credit, 100);
		});

	});

	describe(".string", sub {

		it("outputs a draft Entry in a readable & parsable format", sub {
			my $Entry   = new Entry(date=>'2020-05-17', item=>'Test');
			my $Expense = new Account('E', 0, undef, 'Expense');
			my $Payable = new Account('L', 1, undef, 'Payable');

			$Entry->debit($Expense, 1283.34);
			$Entry->credit($Payable, 1283.34);
			expect($Entry->string, <<'_'
ENTRY               Test                                                    , 2020-05-17
────────────────────────────────────────────────────────────────────────────────────────
0       Expense                                                 ,    1283.34,           
1       Payable                                                 ,           ,    1283.34


_
			);
		});

		it("outputs a committed Entry in a readable & parsable format", sub {
			my $Entry   = new Entry(number=>0, date=>'2020-05-17', item=>'Test');
			my $Expense = new Account('E', 0, undef, 'Expense');
			my $Payable = new Account('L', 1, undef, 'Payable');

			$Entry->debit($Expense, 1283.34);
			$Entry->credit($Payable, 1283.34);
			expect($Entry->string, <<'_'
ENTRY   000000      Test                                                    , 2020-05-17
────────────────────────────────────────────────────────────────────────────────────────
0       Expense                                                 ,    1283.34,           
1       Payable                                                 ,           ,    1283.34


_
			);
		});

	});

	describe(".parse", sub {

		it("reconstructs a draft Entry from a series of lines", sub {
			my $Write    = new Entry(date=>'2020-05-17', item=>'Test Entry');
			my $ExpenseA = new Account('E', 0, undef, 'Expense A');
			my $ExpenseB = new Account('E', 1, undef, 'Expense B');
			my $ExpenseC = new Account('E', 2, undef, 'Expense C');
			my $Payable1 = new Account('L', 3, undef, 'Payable 1');
			my $Payable2 = new Account('L', 4, undef, 'Payable 2');

			$Write->debit($ExpenseA , 33.33);
			$Write->debit($ExpenseB , 33.33);
			$Write->debit($ExpenseC , 33.34);
			$Write->credit($Payable1, 50.01);
			$Write->credit($Payable2, 49.99);
			expect($Write->valid, 1);

			my $Read = new Entry();
			foreach $line (split /\n/, $Write->string) {
				$Read->parse($line);
			}

			expect($Read->number, $Write->number);
			expect($Read->date  , $Write->date);
			expect($Read->item  , $Write->item);
			for (my $i=0; $i < scalar $Read->debits; $i++) {
				expect(($Read->debits)[$i]->{Account}, ($Write->debits)[$i]->{Account}->number);
				expect(($Read->debits)[$i]->{amount} , ($Write->debits)[$i]->{amount});
			}
			for (my $i=0; $i < scalar $Read->credits; $i++) {
				expect(($Read->credits)[$i]->{Account}, ($Write->credits)[$i]->{Account}->number);
				expect(($Read->credits)[$i]->{amount} , ($Write->credits)[$i]->{amount});
			}
			expect($Read->valid, 1);
		});

		it("reconstructs a committed Entry from a string", sub {
			my $Write    = new Entry(number=>2048, date=>'2020-05-17', item=>'Test Entry');
			my $ExpenseA = new Account('E', 0, undef, 'Expense A');
			my $ExpenseB = new Account('E', 1, undef, 'Expense B');
			my $ExpenseC = new Account('E', 2, undef, 'Expense C');
			my $Payable1 = new Account('L', 3, undef, 'Payable 1');
			my $Payable2 = new Account('L', 4, undef, 'Payable 2');

			$Write->debit($ExpenseA , 33.33);
			$Write->debit($ExpenseB , 33.33);
			$Write->debit($ExpenseC , 33.34);
			$Write->credit($Payable1, 50.00);
			$Write->credit($Payable2, 50.00);
			expect($Write->valid, 1);

			my $Read = new Entry();
			$Read->parse($Write->string);

			expect($Read->number, $Write->number);
			expect($Read->date  , $Write->date);
			expect($Read->item  , $Write->item);
			for (my $i=0; $i < scalar $Read->debits; $i++) {
				expect(($Read->debits)[$i]->{Account}, ($Write->debits)[$i]->{Account}->number);
				expect(($Read->debits)[$i]->{amount} , ($Write->debits)[$i]->{amount});
			}
			for (my $i=0; $i < scalar $Read->credits; $i++) {
				expect(($Read->credits)[$i]->{Account}, ($Write->credits)[$i]->{Account}->number);
				expect(($Read->credits)[$i]->{amount} , ($Write->credits)[$i]->{amount});
			}
			expect($Read->valid, 1);
		});

	});

	describe(".valid", sub {

		it("returns false when the debits do not equal the credits", sub {
			my $Entry   = new Entry(date=>'2020-05-17', item=>'Test');
			my $Account = new Account('E', 0, undef, 'Test');

			$Entry->debit($Account, 100);
			expect($Entry->valid, undef);
		});

		it("returns true when the debits equal the credits", sub {
			my $Entry   = new Entry(date=>'2020-05-17', item=>'Test');
			my $Expense = new Account('E', 0, undef, 'Expense');
			my $Payable = new Account('L', 1, undef, 'Payable');

			$Entry->debit($Expense, 100);
			expect($Entry->valid, undef);
			$Entry->credit($Payable, 100);
			expect($Entry->valid, 1);
		});

	});
	
	describe("constuction", sub {

		# These entries do not get numbered yet.
		# This is because they can be collected into a file
		# and read in, as when an allocation rule is applied
		# (but not committed), redirected to a file, tweaked
		# and then loaded.

		it("can capture an Invoice", sub {
			$Invoice = new Entry(date=>'2020-05-17', item=>'Order');
			$Invoice->debit($CustomerA, 100);
			expect($Invoice->valid, undef);
			$Invoice->credit($WidgetJ , 75);
			expect($Invoice->valid, undef);
			$Invoice->credit($WidgetK , 25);
			expect($Invoice->valid, 1);

			expect($Invoice->number, undef);
			expect($Invoice->date, '2020-05-17');
			expect($Invoice->item, 'Order');
			expect(scalar $Invoice->debits, 1);
			expect(($Invoice->debits)[0]->{Account}, $CustomerA);
			expect(($Invoice->debits)[0]->{amount} , 100);
			expect(scalar $Invoice->credits, 2);
			expect(($Invoice->credits)[0]->{Account}, $WidgetJ);
			expect(($Invoice->credits)[0]->{amount} , 75);
			expect(($Invoice->credits)[1]->{Account}, $WidgetK);
			expect(($Invoice->credits)[1]->{amount} , 25);

			expect($Invoice->string   .
			       $CustomerA->ledger .
			       $WidgetJ->ledger   .
			       $WidgetK->ledger   , $INVOICE);
		});

		it("can capture a Customer Payment", sub {
			$CustomerPayment = new Entry(date=>'2020-05-19', item=>'Order Payment');
			$CustomerPayment->debit($Cash, 100);
			expect($CustomerPayment->valid, undef);
			$CustomerPayment->credit($CustomerA, 100); 
			expect($CustomerPayment->valid, 1);

			expect($CustomerPayment->string .
				   $CustomerA->ledger       .
				   $Cash->ledger            , $CUSTOMERPAYMENT);
		});

		it("can capture a Bill", sub {
			$Bill = new Entry(date=>'2020-05-21', item=>'Service Billing');
			$Bill->debit($ServiceY, 67.24);
			expect($Bill->valid, undef);
			$Bill->credit($ProviderX, 67.24);
			expect($Bill->valid, 1);

			expect($Bill->string     .
			       $ServiceY->ledger .
		           $ProviderX->ledger, $BILL);
		});

		it("can capture a Vendor Payment", sub {
			$VendorPayment = new Entry(date=>'2020-05-31', item=>'Bill Payment');
			$VendorPayment->debit($ProviderX, 67.24);
			expect($VendorPayment->valid, undef);
			$VendorPayment->credit($Cash, 67.24);
			expect($VendorPayment->valid, 1);

			expect($VendorPayment->string .
			       $ProviderX->ledger     .
				   $Cash->ledger          , $VENDORPAYMENT);
		});

	});

	describe("reconstruction", sub {

		it("requires identifying the entries", sub {
			my $entry   = 20;
			my $entries = "";
			foreach my $Entry ($Invoice, $CustomerPayment,	$Bill, $VendorPayment) {
				$Entry->number($entry++);
				$entries .= $Entry->string;
			}
			expect($entries, $ENTRIES);
		});

		it("can be done from account ledgers", sub {
	
			# 1) Replace each Entry with a number as if they had been committed to and then read from disk.
			my $Ledgers = ""; # Actions with Numbered Entries
			my $ledgers = ""; # Actions with entry numbers
			foreach my $Account (@Accounts) {
				$Ledgers .= $Account->ledger;
				foreach my $Action ($Account->Actions) {
					$Action->{Entry} = $Action->Entry->number;
				}
				$ledgers .= $Account->ledger;
			}
			expect($Ledgers, $LEDGERS);
			expect($ledgers, $LEDGERS);

			# 2) Reconstruct the set Entries by number.
			my %Entries = ();
			foreach my $Account (@Accounts) {
				foreach my $Action ($Account->Actions) {
					my $entry = $Action->Entry;
					$Entries{$entry} = new Entry(number => $entry, date=>$Action->date, item=>$Action->item) unless exists $Entries{$entry};
					my $Entry = $Entries{$entry};
					if ($Action->debit) {
						$Entry->debit($Account, $Action->debit, $Action);
					} else {
						$Entry->credit($Account, $Action->credit, $Action);
					}
				}
			}

			# 3) Show the reconstructed entries
			my $entries = "";
			foreach my $entry (sort keys %Entries) {
				$entries .= $Entries{$entry}->string;
			}
			expect($entries, $ENTRIES);

		});

	});

}); # Entry

use lib ("$ENV{TEXTBOOKS}/lib");
use Account();


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

	foreach my $Account (@Accounts) {
		push @{$Account->{Parent}->{Children}}, $Account if $Account->Parent;
	}

	return @Accounts;

}

my $CHART = <<"_";
ASSET        10000         Assets
ASSET        11000:10000   Assets:Cash
ASSET        12000:10000   Assets:Accounts Receivable
ASSET        12100:12000   Assets:Accounts Receivable:Customer A
LIABILITY    20000         Liabilities
LIABILITY    21000:20000   Liabilities:Accounts Payable
LIABILITY    21100:21000   Liabilities:Accounts Payable:Provider X
INCOME       30000         Income
INCOME       31000:30000   Income:Widget J
INCOME       32000:30000   Income:Widget K
EXPENSE      40000         Expense
EXPENSE      41000:40000   Expense:Service Y
_


describe("Account", sub {

	my @Accounts = mock_Chart();
	my ($Assets, $Cash, $AR, $CustomerA, 
		$Liabilities, $AP, $ProviderX,
		$Income, $WidgetJ, $WidgetK,
		$Expense, $ServiceY) = @Accounts;

	it("can be output in a chart", sub {
		my $chart = "";
		foreach my $Account (@Accounts) {
			$chart .= $Account->put;
		}
		expect($chart, $CHART);
	});

	describe("attributes", sub {

		describe(".type", sub {

			it("returns the Account type", sub {
				expect($Assets->type     , 'ASSET'    );
				expect($Cash->type       , 'ASSET'    );
				expect($AR->type         , 'ASSET'    );
				expect($CustomerA->type  , 'ASSET'    );
				expect($Liabilities->type, 'LIABILITY');
				expect($AP->type         , 'LIABILITY');
				expect($ProviderX->type  , 'LIABILITY');
				expect($Income->type     , 'INCOME'   );
				expect($WidgetJ->type    , 'INCOME'   );
				expect($WidgetK->type    , 'INCOME'   );
				expect($Expense->type    , 'EXPENSE'  );
				expect($ServiceY->type   , 'EXPENSE'  );
			});

		});

		describe(".number", sub {

			it("returns the Account number", sub {
				expect($Assets->number     , '10000');
				expect($Cash->number       , '11000');
				expect($AR->number         , '12000');
				expect($CustomerA->number  , '12100');
				expect($Liabilities->number, '20000');
				expect($AP->number         , '21000');
				expect($ProviderX->number  , '21100');
				expect($Income->number     , '30000');
				expect($WidgetJ->number    , '31000');
				expect($WidgetK->number    , '32000');
				expect($Expense->number    , '40000');
				expect($ServiceY->number   , '41000');
			});

		});

		describe(".Parent", sub {

			it("returns the Account Parent, if any", sub {
				expect($Assets->Parent     , undef       );
				expect($Cash->Parent       , $Assets     );
				expect($AR->Parent         , $Assets     );
				expect($CustomerA->Parent  , $AR         );
				expect($Liabilities->Parent, undef       );
				expect($AP->Parent         , $Liabilities);
				expect($ProviderX->Parent  , $AP         );
				expect($Income->Parent     , undef       );
				expect($WidgetJ->Parent    , $Income     );
				expect($WidgetK->Parent    , $Income     );
				expect($Expense->Parent    , undef       );
				expect($ServiceY->Parent   , $Expense    );
			});

		});

		describe(".name", sub {

			it("returns the Account name", sub {
				expect($Assets->name     , 'Assets'             );
				expect($Cash->name       , 'Cash'               );
				expect($AR->name         , 'Accounts Receivable');
				expect($CustomerA->name  , 'Customer A'         );
				expect($Liabilities->name, 'Liabilities'        );
				expect($AP->name         , 'Accounts Payable'   );
				expect($ProviderX->name  , 'Provider X'         );
				expect($Income->name     , 'Income'             );
				expect($WidgetJ->name    , 'Widget J'           );
				expect($WidgetK->name    , 'Widget K'           );
				expect($Expense->name    , 'Expense'            );
				expect($ServiceY->name   , 'Service Y'          );
			});

		});

		describe(".Line", sub {

			it("returns the Account Line, if any", sub {
				expect($Assets->Line, undef);
				$Assets->{Line} = 'Hello World';
				expect($Assets->Line, 'Hello World');
				$Assets->{Line} = undef;
				expect($Assets->Line, undef);
			});

		});

		describe(".Children", sub {

			it("returns the list of Children of the Account", sub {
				expect(scalar ($Assets->Children     ), 2);
				expect(scalar ($Cash->Children       ), 0);
				expect(scalar ($AR->Children         ), 1);
				expect(scalar ($CustomerA->Children  ), 0);
				expect(scalar ($Liabilities->Children), 1);
				expect(scalar ($AP->Children         ), 1);
				expect(scalar ($ProviderX->Children  ), 0);
				expect(scalar ($Income->Children     ), 2);
				expect(scalar ($WidgetJ->Children    ), 0);
				expect(scalar ($WidgetK->Children    ), 0);
				expect(scalar ($Expense->Children    ), 1);
				expect(scalar ($ServiceY->Children   ), 0);

				expect(($Assets->Children)[0]     , $Cash     );
				expect(($Assets->Children)[1]     , $AR       );
				expect(($AR->Children)[0]         , $CustomerA);
				expect(($Liabilities->Children)[0], $AP       );
				expect(($AP->Children)[0]         , $ProviderX);
				expect(($Income->Children)[0]     , $WidgetJ  );
				expect(($Income->Children)[1]     , $WidgetK  );
				expect(($Expense->Children)[0]    , $ServiceY );
			});

		});

		xdescribe(".Actions", sub {

			it("returns the list of Actions in the Account", sub {
				&fail;
			});

		});

	});

	describe("properties", sub {

		describe(".balanced", sub {

			it("returns 1 if the Account tracks a balance and 0 otherwise", sub {
				expect($Assets->balanced     , 1);
				expect($Cash->balanced       , 1);
				expect($AR->balanced         , 1);
				expect($CustomerA->balanced  , 1);
				expect($Liabilities->balanced, 1);
				expect($AP->balanced         , 1);
				expect($ProviderX->balanced  , 1);
				expect($Income->balanced     , 0);
				expect($WidgetJ->balanced    , 0);
				expect($WidgetK->balanced    , 0);
				expect($Expense->balanced    , 0);
				expect($ServiceY->balanced   , 0);
			});

		});

		describe(".generation", sub {

			it("returns the generation number of the Account", sub {
				expect($Assets->generation     , 0);
				expect($Cash->generation       , 1);
				expect($AR->generation         , 1);
				expect($CustomerA->generation  , 2);
				expect($Liabilities->generation, 0);
				expect($AP->generation         , 1);
				expect($ProviderX->generation  , 2);
				expect($Income->generation     , 0);
				expect($WidgetJ->generation    , 1);
				expect($WidgetK->generation    , 1);
				expect($Expense->generation    , 0);
				expect($ServiceY->generation   , 1);
			});

		});

		# describe(".sign", sub {

		# 	it("returns the normal sign of debits - credits", sub {
		# 		expect($Assets->sign     ,  1);
		# 		expect($Cash->sign       ,  1);
		# 		expect($AR->sign         ,  1);
		# 		expect($CustomerA->sign  ,  1);
		# 		expect($Liabilities->sign, -1);
		# 		expect($AP->sign         , -1);
		# 		expect($ProviderX->sign  , -1);
		# 		expect($Income->sign     , -1);
		# 		expect($WidgetJ->sign    , -1);
		# 		expect($WidgetK->sign    , -1);
		# 		expect($Expense->sign    ,  1);
		# 		expect($ServiceY->sign   ,  1);
		# 	});

		# });

	});

	describe("methods", sub {

		xdescribe(".action", sub {

			it("adds an Action to the Account via an Entry", sub {
				&fail;
			});

		});

		describe(".put", sub {

			it("returns the Account put as string", sub {
				expect($Assets->put     , "ASSET        10000         Assets\n"                                 );
				expect($Cash->put       , "ASSET        11000:10000   Assets:Cash\n"                            );
				expect($AR->put         , "ASSET        12000:10000   Assets:Accounts Receivable\n"             );
				expect($CustomerA->put  , "ASSET        12100:12000   Assets:Accounts Receivable:Customer A\n"  );
				expect($Liabilities->put, "LIABILITY    20000         Liabilities\n"                            );
				expect($AP->put         , "LIABILITY    21000:20000   Liabilities:Accounts Payable\n"           );
				expect($ProviderX->put  , "LIABILITY    21100:21000   Liabilities:Accounts Payable:Provider X\n");
				expect($Income->put     , "INCOME       30000         Income\n"                                 );
				expect($WidgetJ->put    , "INCOME       31000:30000   Income:Widget J\n"                        );
				expect($WidgetK->put    , "INCOME       32000:30000   Income:Widget K\n"                        );
				expect($Expense->put    , "EXPENSE      40000         Expense\n"                                );
				expect($ServiceY->put   , "EXPENSE      41000:40000   Expense:Service Y\n"                      );
			});

			it("can use implicit identifiers", sub {
				expect($Assets->put(implicit => 1)     , "ASSET        10000         Assets\n"               );
				expect($Cash->put(implicit => 1)       , "ASSET        11000:10000     Cash\n"               );
				expect($AR->put(implicit => 1)         , "ASSET        12000:10000     Accounts Receivable\n");
				expect($CustomerA->put(implicit => 1)  , "ASSET        12100:12000       Customer A\n"       );
				expect($Liabilities->put(implicit => 1), "LIABILITY    20000         Liabilities\n"          );
				expect($AP->put(implicit => 1)         , "LIABILITY    21000:20000     Accounts Payable\n"   );
				expect($ProviderX->put(implicit => 1)  , "LIABILITY    21100:21000       Provider X\n"       );
				expect($Income->put(implicit => 1)     , "INCOME       30000         Income\n"               );
				expect($WidgetJ->put(implicit => 1)    , "INCOME       31000:30000     Widget J\n"           );
				expect($WidgetK->put(implicit => 1)    , "INCOME       32000:30000     Widget K\n"           );
				expect($Expense->put(implicit => 1)    , "EXPENSE      40000         Expense\n"              );
				expect($ServiceY->put(implicit => 1)   , "EXPENSE      41000:40000     Service Y\n"          );
			});

		});

		describe(".family", sub {

			it("returns a list of all Accounts in the family", sub {
				my @Assets      = $Assets->family;
				my @Liabilities = $Liabilities->family;
				my @Income      = $Income->family;
				my @Expense     = $Expense->family;

				expect(scalar @Assets     , 4);
				expect(scalar @Liabilities, 3);
				expect(scalar @Income     , 3);
				expect(scalar @Expense    , 2);

				expect($Assets[0]     , $Assets     );
				expect($Assets[1]     , $Cash       );
				expect($Assets[2]     , $AR         );
				expect($Assets[3]     , $CustomerA  );
				expect($Liabilities[0], $Liabilities);
				expect($Liabilities[1], $AP         );
				expect($Liabilities[2], $ProviderX  );
				expect($Income[0]     , $Income     );
				expect($Income[1]     , $WidgetJ    );
				expect($Income[2]     , $WidgetK    );
				expect($Expense[0]    , $Expense    );
				expect($Expense[1]    , $ServiceY   );
			});

		});

		describe(".get", sub {

			it("constructs an Account from a Line", sub {
				my $Line    = new Line("mem", 0, $CustomerA->put);
				my $Account = get Account $Line;
				expect($Account->type           , $CustomerA->type  );
				expect($Account->number         , $CustomerA->number);
				expect($Account->Parent         , $CustomerA->Parent->number);
				expect($Account->name           , $CustomerA->name  );
				expect($Account->Line->coord    , $Line->coord      );
				expect(scalar $Account->Children, 0                 );
				expect(scalar $Account->Actions , 0                 );
			});

			it("can be called like a method", sub {
				my $Line    = new Line("mem", 0, $CustomerA->put);
				my $Account = new Account();
				$Account->get($Line);
				expect($Account->type           , $CustomerA->type  );
				expect($Account->number         , $CustomerA->number);
				expect($Account->Parent         , $CustomerA->Parent->number);
				expect($Account->name           , $CustomerA->name  );
				expect($Account->Line->coord    , $Line->coord      );
				expect(scalar $Account->Children, 0                 );
				expect(scalar $Account->Actions , 0                 );
			});

		});

		describe(".identifier", sub {

			it("returns the name of the Account qualified by Parent names", sub {
				expect($Assets->identifier     , "Assets"                                 );
				expect($Cash->identifier       , "Assets:Cash"                            );
				expect($AR->identifier         , "Assets:Accounts Receivable"             );
				expect($CustomerA->identifier  , "Assets:Accounts Receivable:Customer A"  );
				expect($Liabilities->identifier, "Liabilities"                            );
				expect($AP->identifier         , "Liabilities:Accounts Payable"           );
				expect($ProviderX->identifier  , "Liabilities:Accounts Payable:Provider X");
				expect($Income->identifier     , "Income"                                 );
				expect($WidgetJ->identifier    , "Income:Widget J"                        );
				expect($WidgetK->identifier    , "Income:Widget K"                        );
				expect($Expense->identifier    , "Expense"                                );
				expect($ServiceY->identifier   , "Expense:Service Y"                      );
			});

			it("can use implicit hierarchy", sub {
				expect($Assets->identifier(implicit => 1)     , "Assets"               );
				expect($Cash->identifier(implicit => 1)       , "  Cash"               );
				expect($AR->identifier(implicit => 1)         , "  Accounts Receivable");
				expect($CustomerA->identifier(implicit => 1)  , "    Customer A"       );
				expect($Liabilities->identifier(implicit => 1), "Liabilities"          );
				expect($AP->identifier(implicit => 1)         , "  Accounts Payable"   );
				expect($ProviderX->identifier(implicit => 1)  , "    Provider X"       );
				expect($Income->identifier(implicit => 1)     , "Income"               );
				expect($WidgetJ->identifier(implicit => 1)    , "  Widget J"           );
				expect($WidgetK->identifier(implicit => 1)    , "  Widget K"           );
				expect($Expense->identifier(implicit => 1)    , "Expense"              );
				expect($ServiceY->identifier(implicit => 1)   , "  Service Y"          );
			});

		});

		xdescribe(".ledger", sub {

			it("returns the Account Actions as a string", sub {
				&fail;
			});

		});

		xdescribe(".record", sub {

			it("adds the bank record to the Account as an (unallocated) Action", sub {
				&fail;
			});

		});

		xdescribe(".totals", sub {

			it("returns the total debits & credits from the Account family", sub {
				&fail;
			});

		});

	});

}); # Account


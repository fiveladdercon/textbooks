use lib ("$ENV{TEXTBOOKS}/lib");
use Action();
use Entry();
use Source();

my $STATEMENT = '04/14/2020,HYDRO OTTAWA U9Q9H3 ,80.18,,7077.53';
my $ACTION    = <<'_';
2020-04-14,       , HYDRO OTTAWA U9Q9H3                         ,           ,      80.18,    7077.53 *
_

describe("Action", sub {

	describe("new", sub {

		it("can create an Action from options", sub {
			my $Action = new Action(date=>'date', item=>'item', credit=>10.00);

			expect($Action->{date}   , 'date');
			expect($Action->{item}   , 'item');
			expect($Action->{debit}  , 0     );
			expect($Action->{credit} , 10.00 );
			expect($Action->{balance}, undef );
			expect($Action->{settled}, 0     );
			expect($Action->{Entry}  , undef );
			expect($Action->{Line}   , undef );
		});

		it("can create an Action from an Entry", sub {
			my $Entry  = new Entry(date => 'date', item => 'item');
			my $Action = new Action(Entry => $Entry, debit=>10.01);

			expect($Action->{date}   , 'date');
			expect($Action->{item}   , 'item');
			expect($Action->{debit}  , 10.01 );
			expect($Action->{credit} , 0     );
			expect($Action->{balance}, undef );
			expect($Action->{settled}, 0     );
			expect($Action->{Entry}  , $Entry);
			expect($Action->{Line}   , undef );
		});

	});

	describe(".date", sub {

		it("returns the Action date", sub {
			my $Action = new Action(date => 'date');
			expect($Action->date, 'date');
		});

	});

	describe(".item", sub {

		it("returns the Action item", sub {
			my $Action = new Action(item => 'item');
			expect($Action->item, 'item');
		});

	});

	describe(".debit", sub {

		it("returns the Action debit", sub {
			my $Action = new Action(debit => 'debit');
			expect($Action->debit, 'debit');
		});

	});

	describe(".credit", sub {

		it("returns the Action credit", sub {
			my $Action = new Action(credit => 'credit');
			expect($Action->credit, 'credit');
		});

	});

	describe(".balance", sub {

		it("returns the Action balance", sub {
			my $Action = new Action(balance => 'balance');
			expect($Action->balance, 'balance');
		});

	});

	describe(".settled", sub {

		it("returns the Action settled state", sub {
			my $Action = new Action(); $Action->{settled} = 'settled';
			expect($Action->settled, 'settled');
		});

	});

	describe(".Entry", sub {

		it("returns the Action Entry", sub {
			my $Entry  = new Entry(date => 'date', item => 'item');
			my $Action = new Action(Entry => $Entry);
			expect($Action->Entry, $Entry);
		});

	});

	describe(".Line", sub {

		it("returns the Action Line", sub {
			my $Action = new Action(); $Action->{Line} = 'Line';
			expect($Action->Line, 'Line');
		});

	});

	describe(".get", sub {

		it("parses a ledger line", sub {
			my $Line   = new Line('test.gl', 1, $ACTION);
			my $Action = new Action();
			$Action->get($Line);
			expect($Action->date       , '2020-04-14'         );
			expect($Action->item       , 'HYDRO OTTAWA U9Q9H3');
			expect($Action->debit      , 0                    );
			expect($Action->credit     , 80.18                );
			expect($Action->balance    , 7077.53              );
			expect($Action->settled    , 1                    );
			expect($Action->Entry      , undef                );
			expect($Action->Line->coord, '<test.gl:1>'        );
		});

		it("can be called like a constructor", sub {
			my $Line   = new Line('test.gl', 1, $ACTION);
			my $Action = get Action $Line;
			expect($Action->date       , '2020-04-14'         );
			expect($Action->item       , 'HYDRO OTTAWA U9Q9H3');
			expect($Action->debit      , 0                    );
			expect($Action->credit     , 80.18                );
			expect($Action->balance    , 7077.53              );
			expect($Action->settled    , 1                    );
			expect($Action->Entry      , undef                );
			expect($Action->Line->coord, '<test.gl:1>'        );
		});

	});

	describe(".identifier", sub {

		it("returns an identifying signature of the Action", sub {
			my $Action = new Action(date => '2020-05-26', debit => 11.1, balance => 123.4);
			expect($Action->identifier, '2020-05-26:11.10:0.00:123.40');
		});

	});

	describe(".import", sub {

		it("parses a bank record", sub {
			my $Line   = new Line('test.csv', 1, $STATEMENT);
			my $Action = new Action();
			$Action->import($Line);
			expect($Action->date       , '2020-04-14'         );
			expect($Action->item       , 'HYDRO OTTAWA U9Q9H3');
			expect($Action->debit      , 0                    );
			expect($Action->credit     , 80.18                );
			expect($Action->balance    , 7077.53              );
			expect($Action->settled    , 1                    );
			expect($Action->Entry      , undef                );
			expect($Action->Line->coord, '<test.csv:1>'       );
		});

		it("can be called like a constructor", sub {
			my $Line   = new Line('test.csv', 1, $STATEMENT);
			my $Action = import Action $Line;
			expect($Action->date       , '2020-04-14'         );
			expect($Action->item       , 'HYDRO OTTAWA U9Q9H3');
			expect($Action->debit      , 0                    );
			expect($Action->credit     , 80.18                );
			expect($Action->balance    , 7077.53              );
			expect($Action->settled    , 1                    );
			expect($Action->Entry      , undef                );
			expect($Action->Line->coord, '<test.csv:1>'       );
		});

	});

	describe(".net", sub {

		it("returns the net of debit - credit", sub {
			my $Debit = new Action (debit => 10.12);
			expect($Debit->net, 10.12);
			my $Credit = new Action(credit => 10.12);
			expect($Credit->net, -10.12);
		});

	});

	describe(".put", sub {

		it("outputs the Action as a string", sub {
			my $Line   = new Line('test.csv', 1, $STATEMENT);
			my $Action = import Action $Line;
			expect($Action->put, $ACTION);
		});

	});


});

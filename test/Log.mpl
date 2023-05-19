use lib ("$ENV{TEXTBOOKS}/lib");
use Console();

$Console::TESTING = 1; # Redirect STD I/O

describe("Console", sub {

	it("has methods to color strings", sub {
		expect(Console::red    ("Hello %s", "World"), "\e[31mHello World\e[0m");
		expect(Console::green  ("Hello %s", "World"), "\e[32mHello World\e[0m");
		expect(Console::yellow ("Hello %s", "World"), "\e[33mHello World\e[0m");
		expect(Console::blue   ("Hello %s", "World"), "\e[34mHello World\e[0m");
		expect(Console::magenta("Hello %s", "World"), "\e[35mHello World\e[0m");
		expect(Console::cyan   ("Hello %s", "World"), "\e[36mHello World\e[0m");
	});

	it("has methods for sending output to STDERR (that can be redirected for test)", sub {
		Console::note ("This is a %s" , "note"   );  expect( Console::stderr   , "** NOTE  : This is a note\n");  expect(Console::stderr, '');
		Console::warn ("This is a %s" , "warning");  expect($Console::STDERR[0], "\e[33m** WARN  : This is a warning\e[0m\n"); 
		Console::error("This is an %s", "error"  );  expect($Console::STDERR[0], "\e[31m** ERROR : This is an error\e[0m\n");  
	});

	it("has methods for sending output to STDOUT (that can be redirected for test)", sub {
		Console::stdout("This is %s line of output\n", "a");
		Console::stdout("This is %s line of output\n", "another");
		expect(Console::stdout, <<'_'
This is a line of output
This is another line of output
_
		);
		expect(Console::stdout, '');
	});

	it("has methods for collecting input from STDIN (that can be redirected for test)", sub {
		Console::stdin("World");
		expect(Console::stdin, "World");
	});

	it("has methods for peeking or poping the STDOUT and STDERR", sub {
		Console::stderr;
		Console::note("This is note 1");
		expect($Console::STDERR[0],"** NOTE  : This is note 1\n");
		expect($Console::STDERR[0],"** NOTE  : This is note 1\n");
		Console::note("This is note 2");
		expect($Console::STDERR[0],"** NOTE  : This is note 2\n");
		expect($Console::STDERR[0],"** NOTE  : This is note 2\n");
		expect($Console::STDERR[1],"** NOTE  : This is note 1\n");
		expect($Console::STDERR[1],"** NOTE  : This is note 1\n");
		expect(Console::stderr,"** NOTE  : This is note 1\n** NOTE  : This is note 2\n");
		expect(Console::stderr,"");

		Console::stdout;
		Console::stdout("This is output 1\n");
		expect($Console::STDOUT[0],"This is output 1\n");
		expect($Console::STDOUT[0],"This is output 1\n");
		Console::stdout("This is output 2\n");
		expect($Console::STDOUT[0],"This is output 2\n");
		expect($Console::STDOUT[0],"This is output 2\n");
		expect($Console::STDOUT[1],"This is output 1\n");
		expect($Console::STDOUT[1],"This is output 1\n");
		expect(Console::stdout, "This is output 1\nThis is output 2\n");
		expect(Console::stdout, "");
	});

});


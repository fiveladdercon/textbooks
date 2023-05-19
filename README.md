# Textbooks #

*Textbooks* is a text based command line accounting program for producing income 
& expense statements from CSV bank statements by using patterns to reconstruct a 
general ledger.  Patterns that recur year over year can be saved to quickly 
auto-allocate most records on subsequent years, which means that textbooks
effectively learns your patterns.

Textbooks has commands for the managing the following steps in report 
production:

1.  Setting up a Chart of Accounts
2.  Importing data from CSV statements
3.  Using patterns to reconstruct transactions (allocations & transfers)
4.  Added, updating or removing entries to refine details
5.  Reporting the Balance Sheet and Income & Expense Statement

Testbooks stores all data in a human readable text file.  Though there are 
commands that modify the text file, they are generally intended for querying or 
bulk editing. The file can and should be edited manually, because manual editing
is the best means to acheive certain basic outcomes. (For example: renaming or 
restructuring the Chart of Accounts; or updating or deleting an import rules.)



## Textbooks Session ##

$ textbooks ENTITY COMMAND [COMMAND OPTIONS] 
   [-C | --commit]
   [-M | --mute | -V | --verbose | -P | --profuse]
   [-N | --no-color]


Each invocation of Textbooks is a *session* that reads the data in the specified
ENTITY file and executes the given COMMAND.  

The ENTITY file is written back to disk unless the --commit option is specified. 
This allows for visual confirmation of the change on STDOUT before the data is 
changed on disk.

Session messages such as warnings are output to STDERR. The verbosity of session 
messages is set using the --mute, --verbose or --profuse options.

Output is generally colored, often to highlight the input that was supplied.  
Add the --no-color option to remove the color when piping the output to a file.

Note that session options can be specified anywhere on the command line, though 
are typically at the end (--commit in particular).  Note also that session short
form options are uppercase, while command options are lower case.



### Names ###

A *Name* is a shortcut string used to uniquely identify an account in the chart 
of accounts.  

The full name of the account could be typed, but the intent is to uniquely 
identify an account with as few key strokes as possible.

Names are prefixed with the @ symbol to signify that the following string is a 
Name, but the @ symbol is not part of the Name itself.

Levels in the chart can be identified by separating them with colon (:) 
characters:

   @exp:meals  identifies  *Exp*ense:Discretionary:Food & Drink:*Meals*

Each level can also include a glob:

   @ass:d\*td tfsa  identifies  *Ass*ets:Bank Accounts:*Dave's TD TFSA*

Since globs are interpretted on the command line, the . character has
the same effect.

   @ass:d.td tfsa  identifies  *Ass*ets:Bank Accounts:*Dave's TD TFSA*



### Patterns ###

A *Pattern* is a string used to identify transactions in bank records from their 
descriptions.  

Often may different transactions are allocated to the same account. For example, 
transactions at PETROCAN, ESSO, SHELL and MACEWAN'S are gas stations and are 
would all be allocated to the @Vehicle:Fuel expense.

The Pattern:

PETROCAN | ESSO | SHELL | MACEWAN'S

identifies transactions at any of the gas stations.

A Pattern is specified at the command line during allocation, but recurring 
patterns can be saved in the ENTITY file to aid with the automatic allocation of
common transactions.

Command Line  ENTITY file  Description
^             |            Terms are ORed together, i.e. A or B
+             &            Terms are ANDed together, i.e. C and D
-             !            Terms are negated, i.e. not E

A Pattern is strictly organized as a disjuction (ORs) of conjunctions (ANDs),
so that bracketting is not required.

TIM & HORTON | BRIDGEHEAD & COFFEE  

means (TIM & HORTON) | (BRIDGEHEAD & COFFEE)
not   TIM & (HORTON | BRIDGEHEAD) & COFFEE

Any of the special characters can be escaped to be a literal in the pattern:
e.g. TFR\-FR



### Periods ###

A *Period* is shortcut that specifies an interval of time, for example a year, a 
month, a day or two weeks etc.



## Textbooks Commands ##

## Chart of Accounts Management ##

$ textbooks ENTITY chart 

Shows all accounts.


$ textbooks ENTITY chart PATTERN+

Shows only accounts with PATTERN in name, highlighting the PATTERN.
Used to identify an account using a few keystrokes.
Space separated PATTERNs are a single PATTERN to save quoting.


$ textbooks ENTITY chart --asset     --parent PARENT NUMBER NAME+
$ textbooks ENTITY chart --liability --parent PARENT NUMBER NAME+
$ textbooks ENTITY chart --income    --parent PARENT NUMBER NAME+
$ textbooks ENTITY chart --expense   --parent PARENT NUMBER NAME+

Creates a new account of the given type.
PARENT is the unique account number of the parent account.
NUMBER must be unique number for the new account.
NAME is a string.  Space separated NAMES are a single NAME to save quoting.


The order of accounts in the ENTITY is retained for reporting purposes.
To reorder the accounts, hand modify the ENTITY file.


## Bank Statement Management ##


$ textbooks ENTITY import --rules [--account NAME] [PATTERN+]

Shows import rules.  Shows all import rules or otherwise filters
according to the account NAME or PATTERN provided.


$ textbooks ENTITY import --files [--account NAME] [PATTERN+]

Shows all import files.  Shows all files that match the import
rules or otherwise filters according to the account NAME or 
PATTERN provided.


$ textbooks ENTITY import --account NAME --source GLOB

Adds an import rule to the given account NAME


$ textbooks ENTITY import [--account NAME] [PATTERN+] [-p PERIOD]

Import transactions.  Imports all transactions or otherwise
filters according to the Account NAME or PATTERN provided.


$textbooks ENTITY reconcile

Checks the integrity of the balance of the imported transactions, 
verifying that the imported balance is the same as the computed
balance.  This catches "balance discontinuities" that may signify
an import issue.


$textbooks ENTITY deport


#### Import Scenarios ####

1. Import out of order. i.e. work backwards in time since last time.
   e.g. Did it in 2020, it's now 2022, so do 2022 first, then 2021
   rather than require 2021 before 2022.  It means 2021 will be inserted
   between 2020 and 2022 data.  Very common.

2. Raw data files have duplicate transactions.  Downloading one period sometimes
   includes data from the previous or next period (i.e. month/year).  
   Surprisingly common.

3. Raw data files have different transaction descriptions.  This happened
   when I downloaded the same period of transactions a couple of months apart
   and the bank had changed the decriptions from hiding transfer identifiers
   (e.g. AU****) to showing transfer identifiers (e.g. AU817X).  Rare.

4. Raw data files have non-sequential dates.  The last transaction on VISA 
   statement in month 1 "clears" after the first transaction on the VISA
   statement in month 2.  This happens if one vendor is quick to post the
   transaction while another vendor is slow.  The quick vendor posts on the 
   statement date and it "makes" the statement, while the slow vendor that 
   did the transaction the day before the statement date posts after 
   the statement date and it shows up on the next statement with a date 
   that is before the statement date.

5. Using a date/debit/credit/balance "signature" does not uniquely identify
   actions.  A scenario where an amount is transferred from one account to
   another, then back again, then to another account (i.e. because the first
   transfer was a mistake) results in the first and third action having the
   same signature.  I believe the signature scheme was added to address item 
   (4).  Adding the item to the signature fails under scenario 3.

I think the import has bounced back and forth between doing a merge based on
date (which can't handle scenario 4) and doing a signature based merge (which
fails under scenario 5)



## Allocation ##

$ textbooks ENTITY alloc -r | --rules [NAME]

Displays allocation rules, filtered by Account NAME if provided.


$ textbooks ENTITY alloc [-p | --period PERIO] [PATTERN ...]

Displays unallocated actions by account with totals, filtered
by the PERIOD and/or PATTERN(s) if provided.

This is intented to identify a PATTERN in the actions and
provide a quick peek at the total.


$ textbooks ENTITY alloc [-a | --account NAME] [-p | --period] [PATTERN ...]

Adding at least one account



### Selections ###

$ textbooks ENTITY select [@NAME]

$ textbooks ENTITY select [@NAME] PATTERN

$ textbooks ENTITY select [@NAME] PATTERN -- @NAME

$ textbooks ENTITY select [@NAME] PATTERN -- @NAME PATTERN

$ textbooks ENTITY select [@NAME] PATTERN -- @NAME PATTERN @NAME PATTERN



#### Allocation Scenarios ####

1.  A pattern applies accross multiple bank accounts and credit cards
    that allocates the amounts as expense or income.  The most common.
    e.g. MCDONALDS allocated to exp:meals

2.  The same pattern needs to be allocated to two different expense
    accounts.  e.g. Half of "TD Ins" actions are auto insurance, half
    are home insurance.  The difference is in the amount, so Limits
    were added.  Limits should probably not be storable, since they
    probably change from year to year.  An alternative is to allocate
    them all to one account, then add a "correction" transfer of half 
    the amount to the other account.

3.  Amounts include two different types of expenses.  e.g Condo Fees
    & water.  Condo fees happen every month, water every quarter but
    there is only one debit from the bank account.  Some work was done 
    on split patterns, but I'm not sure how they are recorded in the
    file. Perhaps they shouldn't be.  Splits could be a "fix" to the
    existing Entries.  A correction entry would fix this too.

4.  The same pattern needs to be allocated to two different accounts
    AND the amounts are the same (so Limits won't work).  e.g. RESP 
    investments alternate weeks between children.  Perhaps could be
    selected using a step size in the date.

### Adjustments ###


$ textbooks ENTITY entry @NAME ITEM [DEBIT: | :CREDIT] [@NAME [ITEM] [DEBIT: | :CREDIT] ...]






## Accounting 101 ##


### Accounts ###

An *Account* is like a file folder: it has a *name* that identifies a *ledger*,
which - like a bank statement - is a history of changes that list increases and 
decreases by date with short notes on the reason for the change.

A collection of accounts are organized into a hierarchy called the *Chart of 
Accounts*.

Some Accounts track a *state* and changes to that state, while other accounts 
only track *changes*.

Asset & Liability accounts track *state* and have a balance at any given *point 
in time*.  The balance is the state of the Account and the ledger is history of 
how that balance has changed over time.

Income & Expense accounts track *changes* and do not have a balance, though can 
be totaled over a *period of time*.  The ledger reflects the distribution of the
aggregate change over time.

Since states and changes are both measured with numbers, a number alone does not 
tell you whether it represents a state or a change and the context of the number
is relevant.


### Transactions ###

Every transaction affects at least two accounts.  That is why it is called
a _trans_ action.

For example:

If I get paid, my income increased AND my bank balance increased.

If I buy dinner, my expenses increased AND my bank balance decreased (or
my credit card balance increased).

If I pay off my credit card, the amount owing on the card decreased AND
my bank balance decreased.


So unless at least two ledgers are updated, a change has not been properly 
tracked.


### Debits & Credits ###

Though accounts track a typical flow of money, all accounts can be increased
or decreased.

Though normally my income increases each time I get paid, if I get overpaid 
and have pay back the overpayment, my income decreased (AND my bank balance 
decreased).

Though normally when I buy stuff my expenses increase, if I return something, 
my expenses decreased (AND my bank balance increased or my credit card balance
decreased).

Rather than using postive values to reflect increases and negative values to
reflect decreases, accountants use *debits* & *credits* which always postive
values.



ENTRY                                                                       , 2022-12-29
────────────────────────────────────────────────────────────────────────────────────────
@Expense:Discretionary:Home Decor
    DOLLARAMA # 886 OTTAWA                                      ,      11.30,
@Liabilities:TD VISA
    DOLLARAMA # 886 OTTAWA                                      ,           ,      11.30



GL File
-------

EXPENSE Expense:Discretionary:Home Decor
────────────────────────────────────────────────────────────────────────────────────────
| DOLLARAMA


Selection File / Output


Allocation
----------

$ DOLLARAMA -- @Exp:Other

| DOLLARAMA
--
@Exp:Other



$ MSP 303 -- @Exp:Condo

| MSP 303
--
@Exp:Condo Fees  // includes water payments

Then manually split off water?


Transfer

@JCHQ
| PYT TO: & 1234
--
@DCHQ
| PYT FRM: & 9876


1. Use *Selections* to pick-off transactions:
   - Allocation:       Pattern -> @Name          (e.g.        MCDONALDS  -> @Exp:Fast.Food             )
   - Transfer  :       Pattern -> @Name Pattern  (e.g.        PYT TO C/C -> @VISA           PAYMENT    )
                 @Name Pattern -> @Name Pattern  (e.g. @JCHQ  PYT TO 123 -> @DCHQ           PYT FRM 987)

2. Save common recurring transactions.  i.e. the "low hanging fruit".

3. Hammer out the unique transactions without saving.

4. Handle unusual scenarios:
   a) Separating home & auto insurance or D/K life insurance by amount
      > Use Limits
   b) Separating water utility from condo fees
      > Use i-iii below
   c) Alternating BRESP & ERESP payments by date
      > Use i-iii below

   i)   Dump uncommitted entries to a file, edit file then submit
   ii)  Commit then select entries to fix and dump to file, edit file & submit
   iii) Commit then use command line to select & fix entries.



Terminology

Entity <-> General Ledger (GL)
Chart
Journal Entry <-> Transaction
Account
Ledger
Action <-> Record
Debit
Credit
Amount
Balance
Item

Change, State

Period, Date
Name
Pattern
Limit
Import: import rule vs imported files vs imported actions
Selection: selection rule vs selected actions

Session
Source: path, expanded path


To Do
=====

1.  Update import rule reporting to highlight new rule (??)
2.  Refactor: 
    - @NAME convention in early commands.
    - Selection => Rule.  A Rule yields a Selection of Actions.
3.  - Organize input/output accross classes
      - composition?  i.e. does the account get/put/display the ledger?
      - get/put storage strings
      - display display strings
    - Remove Allocation
4.  Clean-up, standardize & comment code
    - Account - Done
5.  README documentation
6.  Create new repo & publisth






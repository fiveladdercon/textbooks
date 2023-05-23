# Textbooks #

**Textbooks** is a text based command line accounting program for producing 
income & expense statements from CSV bank statements by using patterns to 
reconstruct a general ledger (GL).  Patterns that recur year over year can be 
saved to quickly auto-allocate most records on subsequent years, which means 
that textbooks effectively learns your spending patterns over time.

Textbooks has commands for the managing the following steps in report 
production:

1.  Setting up a Chart of Accounts
2.  Importing data from CSV bank statements
3.  Using patterns to reconstruct transactions (allocations & transfers)
4.  Creating, reading, updating or deleting entries to refine details
5.  Reporting the Balance Sheet and Income & Expense Statement

Testbooks stores all data in a human readable text file.  Though there are 
commands that modify the text file, they are generally intended for querying or 
bulk editing. The file can and should be edited manually, because manual editing
is the best means to acheive certain basic outcomes. (For example: renaming or 
restructuring the Chart of Accounts; or updating or deleting an import rules.)



## Textbooks Session ##

```
$ textbooks GL [-h | --help] COMMAND [OPTIONS] 
   [-M | --mute | -V | --verbose | -P | --profuse]
   [-N | --no-color]
   [-C | --commit]
```

Each invocation of Textbooks is a **session** that reads the data in the 
specified general ledger (`GL`) file and executes the given `COMMAND`.  

The `GL` file is not written back to disk unless the `--commit` option is 
specified.  This allows for visual confirmation of changes on STDOUT before the 
data is changed on disk.

Session messages such as warnings are output to STDERR. The verbosity of session 
messages is set using the `--mute`, `--verbose` or `--profuse` options.

Session output is generally colored, often to highlight the input that was 
supplied.  Add the `--no-color` option to remove the color when piping the 
output to a file.

Note that session options can be specified anywhere on the command line, though 
are typically added at the end (the `--commit` option in particular).  Note also
that session short form options are uppercase, while command options are lower 
case.

Commands make use of **Names**, **Patterns**, **Dates** and **Periods**.



### Names ###

A **Name** is a shortcut string used to uniquely identify an account in the 
chart of accounts.  

The full hiearchical name of the account could be typed, but the intent is to 
uniquely identify an account with as few key strokes as possible.

Names are prefixed with the `@` symbol on the command line to signify that the 
remaining string is a Name, but the `@` symbol is not part of the Name itself.

Hierarchy in the chart of accounts can be identified by separating them with 
colon (`:`) characters:

`@exp:meals`  identifies  `**Exp**ense:Discretionary:Food & Drink:**Meals**`

Names are case insenstive.



### Patterns ###

A **Pattern** is a string used to identify transactions in bank records from 
their descriptions.  

Often may different transactions are allocated to the same account. For example, 
transactions at PETROCAN, ESSO, SHELL and MACEWAN'S are gas stations and would 
all be allocated to the @Vehicle:Fuel expense.

The Pattern:

```
PETROCAN | ESSO | SHELL | MACEWAN'S
```

identifies transactions at any of these gas stations.

A Pattern is specified at the command line during allocation, but recurring 
patterns can be saved in the GL file to aid with the automatic allocation of
common transactions in future periods.

Patterns use the following symbols to specify logical operations:

```
Command Line   GL file    Description
^              |          Terms are ORed together, i.e. A or B
+              &          Terms are ANDed together, i.e. C and D
-              !          Terms are negated, i.e. not E
```

A Pattern is strictly organized as a disjuction (ORs) of conjunctions (ANDs),
so that bracketting is not required.

```
TIM & HORTON | LOCAL & COFFEE & HOUSE
```
means 
```
(TIM & HORTON) | (LOCAL & COFFEE & HOUSE)
```
not
```
TIM & (HORTON | LOCAL) & COFFEE & HOUSE
```

Any of the special characters can be enclosed in square brackets (`[]`) to be a 
literal in the pattern:

```
TRANSFER[-]FROM
```

Patterns are case insensitive.



### Dates ###

A **Date** is a specific day of the year specified in `YYYY-MM-DD` format.

All dates are specified, reported and stored in this format.



### Periods ###

A **Period** is shortcut that specifies an interval of time, for example a year, 
a month, a day or two weeks etc.

A Period can be specified by specifying two dates separated by a colon (`:`):

```
2022-01-01:2022-12-31
```

The first date is the start date and the second date is the end date.

The start & end dates are inclusive, so that specifying the start and end
as the same day will result a period of that one day:

```
2022-03-17:2022-03-17
```

If you omit the day, the first day of the month is implied for the start date
and the last day of the month is implied for the end date:

```
2022-01:2022-03   #  == 2022-01-01:2022-03-31  (i.e. Q1)
```

If you omit the month, the first month of the year is implied for the start
date and the last day of the month is implied for the end date:

```
2021:2022   #  == 2021-01-01:2022-12-31  (i.e. two years)
```

If you omit the end date, it is implied by the start date, with inferred
days and months appropriate to the end date:

```
2022-01-01  #  == 2022-01-01:2022-01-01  (i.e. one day)
2022-01     #  == 2022-01-01:2022-01-31  (i.e. one month)
2022        #  == 2022-01-01:2022-12-31  (i.e. one year)
```


## Textbooks Commands ##



### Chart of Accounts Management ###

```
$ textbooks GL chart 
```

Shows all accounts with explicit hierarchical names.


```
$ textbooks GL chart @NAME
```

Shows only accounts with a matching NAME.  Used to uniquely identify an account 
using as few keystrokes as possible.


```
$ textbooks GL chart --asset     --parent PARENT NUMBER NAME+
$ textbooks GL chart --liability --parent PARENT NUMBER NAME+
$ textbooks GL chart --income    --parent PARENT NUMBER NAME+
$ textbooks GL chart --expense   --parent PARENT NUMBER NAME+
```

Creates a new account of the given type.
- PARENT is the unique account number of the parent account.
- NUMBER must be unique number for the new account.
- NAME is a string.  Space separated NAMES on the command line are joined into 
  a single NAME to save quoting.  This is a rare case where the `@` symbol is
  not used (i.e. because you are creating an Account Name rather than trying
  to find one that exists).

Account numbers are only used to uniquely identify an account for the purpose
of constructing the hierarchy of accounts in the chart.  Once the hierarchy
has been captured the in GL with account numbers, Names will be used to
uniquely identify accounts for the purposes of allocation and reporting.

For example, the following chart defines a Fuel account that sits next to the 
Insurance account in the hierarchy - they both have a unique number (4240 & 4220
respecively) but share a common parent number (4200), the Vehicle account, which
in turn has the Expense parent (4000).

```
ASSET     1000       Assets
ASSET     1100:1000  Chequing Account
LIABILITY 2000       Liabilities
LIABILITY 2100:2000  Line of Credit
INCOME    3000       Income
INCOME    3100:3000  Employment
EXPENSE   4000       Expense
EXPENSE   4100:4000  House
EXPENSE   4200:4000  Vehicle
EXPENSE   4210:4200  Payments
EXPENSE   4220:4200  Insurance
EXPENSE   4230:4200  Licensing
EXPENSE   4240:4200  Fuel
EXPENSE   4250:4200  Maintenance
```

Although there are commands to create accounts in the chart, it is in fact
far easier to just work on the chart by hand once you understand the pattern.  
Use the commands to get you started, but move to hand editing to more easily get 
the bulk of the work done.  Use the chart command (without arguments) to check 
your hierarchy.

Also, the order of accounts in the GL file is retained for reporting purposes.
So to reorder the accounts, hand modify the GL file to sort the accounts to your
liking (and you can renumber if you want, but it's not strictly necessary).



### Bank Statement Management ###


```
$ textbooks GL import --rules [--account NAME] [PATTERN+]
```

Shows import rules.  Shows all import rules or otherwise filters
according to the account NAME or PATTERN provided.


```
$ textbooks GL import --files [--account NAME] [PATTERN+]
```

Shows all import files.  Shows all files that match the import
rules or otherwise filters according to the account NAME or 
PATTERN provided.


```
$ textbooks GL import --account NAME --source GLOB
```

Adds an import rule to the given account NAME


```
$ textbooks GL import [--account NAME] [PATTERN+] [-p PERIOD]
```

Import transactions.  Imports all transactions or otherwise
filters according to the Account NAME or PATTERN provided.


```
$textbooks GL reconcile
```

Checks the integrity of the balance of the imported transactions, 
verifying that the imported balance is the same as the computed
balance.  This catches "balance discontinuities" that may signify
an import issue.


```
$textbooks CL deport
```


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



### Selections ###

```
$ textbooks GL select [@NAME]
$ textbooks GL select [@NAME] PATTERN
$ textbooks GL select [@NAME] PATTERN -- @NAME
$ textbooks GL select [@NAME] PATTERN -- @NAME PATTERN
```


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

### Fine Tuning with Entries ###

```
$ textbooks GL entry RANGE [RANGE ...] [-d | --delete]
```

```
$ textbooks GL enter @NAME DATE ITEM+     [DEBIT, | ,CREDIT] 
                     @NAME [DATE] [ITEM+] [DEBIT, | ,CREDIT]
                     [...]
```

### Reporting ###

=encoding ascii

=head1 NAME

perlvar - Perl predefined variables

=head1 DESCRIPTION

=head2 Predefined Names

The following names have special meaning to Perl.  Most 
punctuation names have reasonable mnemonics, or analogs in the
shells.  Nevertheless, if you wish to use long variable names,
you need only say

    use English;

at the top of your program.  This will alias all the short names to the
long names in the current package.  Some even have medium names,
generally borrowed from B<awk>.

If you don't mind the performance hit, variables that depend on the
currently selected filehandle may instead be set by calling an
appropriate object method on the IO::Handle object.  (Summary lines
below for this contain the word HANDLE.)  First you must say

    use IO::Handle;

after which you may use either

    method HANDLE EXPR

or more safely,

    HANDLE->method(EXPR)

Each method returns the old value of the IO::Handle attribute.
The methods each take an optional EXPR, which if supplied specifies the
new value for the IO::Handle attribute in question.  If not supplied,
most methods do nothing to the current value--except for
autoflush(), which will assume a 1 for you, just to be different.
Because loading in the IO::Handle class is an expensive operation, you should
learn how to use the regular built-in variables.

A few of these variables are considered "read-only".  This means that if
you try to assign to this variable, either directly or indirectly through
a reference, you'll raise a run-time exception.

The following list is ordered by scalar variables first, then the
arrays, then the hashes.

=over 8

=item $ARG

=item $_

The default input and pattern-searching space.  The following pairs are
equivalent:

    while (<>) {...}	# equivalent only in while!
    while (defined($_ = <>)) {...}

    /^Subject:/
    $_ =~ /^Subject:/

    tr/a-z/A-Z/
    $_ =~ tr/a-z/A-Z/

    chomp
    chomp($_)

Here are the places where Perl will assume $_ even if you
don't use it:

=over 3

=item *

Various unary functions, including functions like ord() and int(), as well
as the all file tests (C<-f>, C<-d>) except for C<-t>, which defaults to
STDIN.

=item *

Various list functions like print() and unlink().

=item *

The pattern matching operations C<m//>, C<s///>, and C<tr///> when used
without an C<=~> operator.

=item *

The default iterator variable in a C<foreach> loop if no other
variable is supplied.

=item *

The implicit iterator variable in the grep() and map() functions.

=item *

The default place to put an input record when a C<< <FH> >>
operation's result is tested by itself as the sole criterion of a C<while>
test.  Outside a C<while> test, this will not happen.

=back

(Mnemonic: underline is understood in certain operations.)

=back

=over 8

=item $<I<digits>>

Contains the subpattern from the corresponding set of capturing
parentheses from the last pattern match, not counting patterns
matched in nested blocks that have been exited already.  (Mnemonic:
like \digits.)  These variables are all read-only and dynamically
scoped to the current BLOCK.

=item $MATCH

=item $&

The string matched by the last successful pattern match (not counting
any matches hidden within a BLOCK or eval() enclosed by the current
BLOCK).  (Mnemonic: like & in some editors.)  This variable is read-only
and dynamically scoped to the current BLOCK.

The use of this variable anywhere in a program imposes a considerable
performance penalty on all regular expression matches.  See L<BUGS>.

=item $PREMATCH

=item $`

The string preceding whatever was matched by the last successful
pattern match (not counting any matches hidden within a BLOCK or eval
enclosed by the current BLOCK).  (Mnemonic: C<`> often precedes a quoted
string.)  This variable is read-only.

The use of this variable anywhere in a program imposes a considerable
performance penalty on all regular expression matches.  See L<BUGS>.

=item $POSTMATCH

=item $'

The string following whatever was matched by the last successful
pattern match (not counting any matches hidden within a BLOCK or eval()
enclosed by the current BLOCK).  (Mnemonic: C<'> often follows a quoted
string.)  Example:

    $_ = 'abcdefghi';
    /def/;
    print "$`:$&:$'\n";  	# prints abc:def:ghi

This variable is read-only and dynamically scoped to the current BLOCK.

The use of this variable anywhere in a program imposes a considerable
performance penalty on all regular expression matches.  See L<BUGS>.

=item $LAST_PAREN_MATCH

=item $+

The last bracket matched by the last search pattern.  This is useful if
you don't know which one of a set of alternative patterns matched.  For
example:

    /Version: (.*)|Revision: (.*)/ && ($rev = $+);

(Mnemonic: be positive and forward looking.)
This variable is read-only and dynamically scoped to the current BLOCK.

=item @LAST_MATCH_END

=item @+

This array holds the offsets of the ends of the last successful
submatches in the currently active dynamic scope.  C<$+[0]> is
the offset into the string of the end of the entire match.  This
is the same value as what the C<pos> function returns when called
on the variable that was matched against.  The I<n>th element
of this array holds the offset of the I<n>th submatch, so
C<$+[1]> is the offset past where $1 ends, C<$+[2]> the offset
past where $2 ends, and so on.  You can use C<$#+> to determine
how many subgroups were in the last successful match.  See the
examples given for the C<@-> variable.

=item $MULTILINE_MATCHING

=item $*

Set to a non-zero integer value to do multi-line matching within a
string, 0 (or undefined) to tell Perl that it can assume that strings
contain a single line, for the purpose of optimizing pattern matches.
Pattern matches on strings containing multiple newlines can produce
confusing results when C<$*> is 0 or undefined. Default is undefined.
(Mnemonic: * matches multiple things.) This variable influences the
interpretation of only C<^> and C<$>. A literal newline can be searched
for even when C<$* == 0>.

Use of C<$*> is deprecated in modern Perl, supplanted by 
the C</s> and C</m> modifiers on pattern matching.

Assigning a non-numerical value to C<$*> triggers a warning (and makes
C<$*> act if C<$* == 0>), while assigning a numerical value to C<$*>
makes that an implicit C<int> is applied on the value.

=item input_line_number HANDLE EXPR

=item $INPUT_LINE_NUMBER

=item $NR

=item $.

The current input record number for the last file handle from which
you just read() (or called a C<seek> or C<tell> on).  The value
may be different from the actual physical line number in the file,
depending on what notion of "line" is in effect--see C<$/> on how
to change that.  An explicit close on a filehandle resets the line
number.  Because C<< <> >> never does an explicit close, line
numbers increase across ARGV files (but see examples in L<perlfunc/eof>).
Consider this variable read-only: setting it does not reposition
the seek pointer; you'll have to do that on your own.  Localizing C<$.>
has the effect of also localizing Perl's notion of "the last read
filehandle".  (Mnemonic: many programs use "." to mean the current line
number.)

=item input_record_separator HANDLE EXPR

=item $INPUT_RECORD_SEPARATOR

=item $RS

=item $/

The input record separator, newline by default.  This 
influences Perl's idea of what a "line" is.  Works like B<awk>'s RS
variable, including treating empty lines as a terminator if set to
the null string.  (An empty line cannot contain any spaces
or tabs.)  You may set it to a multi-character string to match a
multi-character terminator, or to C<undef> to read through the end
of file.  Setting it to C<"\n\n"> means something slightly
different than setting to C<"">, if the file contains consecutive
empty lines.  Setting to C<""> will treat two or more consecutive
empty lines as a single empty line.  Setting to C<"\n\n"> will
blindly assume that the next input character belongs to the next
paragraph, even if it's a newline.  (Mnemonic: / delimits
line boundaries when quoting poetry.)

    undef $/;		# enable "slurp" mode
    $_ = <FH>;		# whole file now here
    s/\n[ \t]+/ /g;

Remember: the value of C<$/> is a string, not a regex.  B<awk> has to be
better for something. :-)

Setting C<$/> to a reference to an integer, scalar containing an integer, or
scalar that's convertible to an integer will attempt to read records
instead of lines, with the maximum record size being the referenced
integer.  So this:

    $/ = \32768; # or \"32768", or \$var_containing_32768
    open(FILE, $myfile);
    $_ = <FILE>;

will read a record of no more than 32768 bytes from FILE.  If you're
not reading from a record-oriented file (or your OS doesn't have
record-oriented files), then you'll likely get a full chunk of data
with every read.  If a record is larger than the record size you've
set, you'll get the record back in pieces.

On VMS, record reads are done with the equivalent of C<sysread>,
so it's best not to mix record and non-record reads on the same
file.  (This is unlikely to be a problem, because any file you'd
want to read in record mode is probably unusable in line mode.)
Non-VMS systems do normal I/O, so it's safe to mix record and
non-record reads of a file.

See also L<perlport/"Newlines">.  Also see C<$.>.

=item autoflush HANDLE EXPR

=item $OUTPUT_AUTOFLUSH

=item $|

If set to nonzero, forces a flush right away and after every write
or print on the currently selected output channel.  Default is 0
(regardless of whether the channel is really buffered by the
system or not; C<$|> tells you only whether you've asked Perl
explicitly to flush after each write).  STDOUT will
typically be line buffered if output is to the terminal and block
buffered otherwise.  Setting this variable is useful primarily when
you are outputting to a pipe or socket, such as when you are running
a Perl program under B<rsh> and want to see the output as it's
happening.  This has no effect on input buffering.  See L<perlfunc/getc>
for that.  (Mnemonic: when you want your pipes to be piping hot.)

=item output_field_separator HANDLE EXPR

=item $OUTPUT_FIELD_SEPARATOR

=item $OFS

=item $,

The output field separator for the print operator.  Ordinarily the
print operator simply prints out its arguments without further
adornment.  To get behavior more like B<awk>, set this variable as
you would set B<awk>'s OFS variable to specify what is printed
between fields.  (Mnemonic: what is printed when there is a "," in
your print statement.)

=item output_record_separator HANDLE EXPR

=item $OUTPUT_RECORD_SEPARATOR

=item $ORS

=item $\

The output record separator for the print operator.  Ordinarily the
print operator simply prints out its arguments as is, with no
trailing newline or other end-of-record string added.  To get
behavior more like B<awk>, set this variable as you would set
B<awk>'s ORS variable to specify what is printed at the end of the
print.  (Mnemonic: you set C<$\> instead of adding "\n" at the
end of the print.  Also, it's just like C<$/>, but it's what you
get "back" from Perl.)

=item $LIST_SEPARATOR

=item $"

This is like C<$,> except that it applies to array and slice values
interpolated into a double-quoted string (or similar interpreted
string).  Default is a space.  (Mnemonic: obvious, I think.)

=item $SUBSCRIPT_SEPARATOR

=item $SUBSEP

=item $;

The subscript separator for multidimensional array emulation.  If you
refer to a hash element as

    $foo{$a,$b,$c}

it really means

    $foo{join($;, $a, $b, $c)}

But don't put

    @foo{$a,$b,$c}	# a slice--note the @

which means

    ($foo{$a},$foo{$b},$foo{$c})

Default is "\034", the same as SUBSEP in B<awk>.  If your
keys contain binary data there might not be any safe value for C<$;>.
(Mnemonic: comma (the syntactic subscript separator) is a
semi-semicolon.  Yeah, I know, it's pretty lame, but C<$,> is already
taken for something more important.)

Consider using "real" multidimensional arrays as described
in L<perllol>.

=item $OFMT

=item $#

The output format for printed numbers.  This variable is a half-hearted
attempt to emulate B<awk>'s OFMT variable.  There are times, however,
when B<awk> and Perl have differing notions of what counts as 
numeric.  The initial value is "%.I<n>g", where I<n> is the value
of the macro DBL_DIG from your system's F<float.h>.  This is different from
B<awk>'s default OFMT setting of "%.6g", so you need to set C<$#>
explicitly to get B<awk>'s value.  (Mnemonic: # is the number sign.)

Use of C<$#> is deprecated.

=item format_page_number HANDLE EXPR

=item $FORMAT_PAGE_NUMBER

=item $%

The current page number of the currently selected output channel.
Used with formats.
(Mnemonic: % is page number in B<nroff>.)

=item format_lines_per_page HANDLE EXPR

=item $FORMAT_LINES_PER_PAGE

=item $=

The current page length (printable lines) of the currently selected
output channel.  Default is 60.  
Used with formats.
(Mnemonic: = has horizontal lines.)

=item format_lines_left HANDLE EXPR

=item $FORMAT_LINES_LEFT

=item $-

The number of lines left on the page of the currently selected output
channel.  
Used with formats.
(Mnemonic: lines_on_page - lines_printed.)

=item @LAST_MATCH_START

=item @-

$-[0] is the offset of the start of the last successful match.
C<$-[>I<n>C<]> is the offset of the start of the substring matched by
I<n>-th subpattern, or undef if the subpattern did not match.

Thus after a match against $_, $& coincides with C<substr $_, $-[0],
$+[0] - $-[0]>.  Similarly, C<$>I<n> coincides with C<substr $_, $-[>I<n>C<],
$+[>I<n>C<] - $-[>I<n>C<]> if C<$-[>I<n>C<]> is defined, and $+ coincides with
C<substr $_, $-[$#-], $+[$#-]>.  One can use C<$#-> to find the last
matched subgroup in the last successful match.  Contrast with
C<$#+>, the number of subgroups in the regular expression.  Compare
with C<@+>.

This array holds the offsets of the beginnings of the last
successful submatches in the currently active dynamic scope.
C<$-[0]> is the offset into the string of the beginning of the
entire match.  The I<n>th element of this array holds the offset
of the I<n>th submatch, so C<$+[1]> is the offset where $1
begins, C<$+[2]> the offset where $2 begins, and so on.
You can use C<$#-> to determine how many subgroups were in the
last successful match.  Compare with the C<@+> variable.

After a match against some variable $var:

=over 5

=item C<$`> is the same as C<substr($var, 0, $-[0])>

=item C<$&> is the same as C<substr($var, $-[0], $+[0] - $-[0])>

=item C<$'> is the same as C<substr($var, $+[0])>

=item C<$1> is the same as C<substr($var, $-[1], $+[1] - $-[1])>  

=item C<$2> is the same as C<substr($var, $-[2], $+[2] - $-[2])>

=item C<$3> is the same as C<substr $var, $-[3], $+[3] - $-[3])>

=back

=item format_name HANDLE EXPR

=item $FORMAT_NAME

=item $~

The name of the current report format for the currently selected output
channel.  Default is the name of the filehandle.  (Mnemonic: brother to
C<$^>.)

=item format_top_name HANDLE EXPR

=item $FORMAT_TOP_NAME

=item $^

The name of the current top-of-page format for the currently selected
output channel.  Default is the name of the filehandle with _TOP
appended.  (Mnemonic: points to top of page.)

=item format_line_break_characters HANDLE EXPR

=item $FORMAT_LINE_BREAK_CHARACTERS

=item $:

The current set of characters after which a string may be broken to
fill continuation fields (starting with ^) in a format.  Default is
S<" \n-">, to break on whitespace or hyphens.  (Mnemonic: a "colon" in
poetry is a part of a line.)

=item format_formfeed HANDLE EXPR

=item $FORMAT_FORMFEED

=item $^L

What formats output as a form feed.  Default is \f.

=item $ACCUMULATOR

=item $^A

The current value of the write() accumulator for format() lines.  A format
contains formline() calls that put their result into C<$^A>.  After
calling its format, write() prints out the contents of C<$^A> and empties.
So you never really see the contents of C<$^A> unless you call
formline() yourself and then look at it.  See L<perlform> and
L<perlfunc/formline()>.

=item $CHILD_ERROR

=item $?

The status returned by the last pipe close, backtick (C<``>) command,
successful call to wait() or waitpid(), or from the system()
operator.  This is just the 16-bit status word returned by the
wait() system call (or else is made up to look like it).  Thus, the
exit value of the subprocess is really (C<<< $? >> 8 >>>), and
C<$? & 127> gives which signal, if any, the process died from, and
C<$? & 128> reports whether there was a core dump.  (Mnemonic:
similar to B<sh> and B<ksh>.)

Additionally, if the C<h_errno> variable is supported in C, its value
is returned via $? if any C<gethost*()> function fails.

If you have installed a signal handler for C<SIGCHLD>, the
value of C<$?> will usually be wrong outside that handler.

Inside an C<END> subroutine C<$?> contains the value that is going to be
given to C<exit()>.  You can modify C<$?> in an C<END> subroutine to
change the exit status of your program.  For example:

    END {
	$? = 1 if $? == 255;  # die would make it 255
    } 

Under VMS, the pragma C<use vmsish 'status'> makes C<$?> reflect the
actual VMS exit status, instead of the default emulation of POSIX
status.

Also see L<Error Indicators>.

=item $OS_ERROR

=item $ERRNO

=item $!

If used numerically, yields the current value of the C C<errno>
variable, with all the usual caveats.  (This means that you shouldn't
depend on the value of C<$!> to be anything in particular unless
you've gotten a specific error return indicating a system error.)
If used an a string, yields the corresponding system error string.
You can assign a number to C<$!> to set I<errno> if, for instance,
you want C<"$!"> to return the string for error I<n>, or you want
to set the exit value for the die() operator.  (Mnemonic: What just
went bang?)

Also see L<Error Indicators>.

=item $EXTENDED_OS_ERROR

=item $^E

Error information specific to the current operating system.  At
the moment, this differs from C<$!> under only VMS, OS/2, and Win32
(and for MacPerl).  On all other platforms, C<$^E> is always just
the same as C<$!>.

Under VMS, C<$^E> provides the VMS status value from the last
system error.  This is more specific information about the last
system error than that provided by C<$!>.  This is particularly
important when C<$!> is set to B<EVMSERR>.

Under OS/2, C<$^E> is set to the error code of the last call to
OS/2 API either via CRT, or directly from perl.

Under Win32, C<$^E> always returns the last error information
reported by the Win32 call C<GetLastError()> which describes
the last error from within the Win32 API.  Most Win32-specific
code will report errors via C<$^E>.  ANSI C and Unix-like calls
set C<errno> and so most portable Perl code will report errors
via C<$!>. 

Caveats mentioned in the description of C<$!> generally apply to
C<$^E>, also.  (Mnemonic: Extra error explanation.)

Also see L<Error Indicators>.

=item $EVAL_ERROR

=item $@

The Perl syntax error message from the last eval() operator.  If null, the
last eval() parsed and executed correctly (although the operations you
invoked may have failed in the normal fashion).  (Mnemonic: Where was
the syntax error "at"?)

Warning messages are not collected in this variable.  You can,
however, set up a routine to process warnings by setting C<$SIG{__WARN__}>
as described below.

Also see L<Error Indicators>.

=item $PROCESS_ID

=item $PID

=item $$

The process number of the Perl running this script.  You should
consider this variable read-only, although it will be altered
across fork() calls.  (Mnemonic: same as shells.)

=item $REAL_USER_ID

=item $UID

=item $<

The real uid of this process.  (Mnemonic: it's the uid you came I<from>,
if you're running setuid.)

=item $EFFECTIVE_USER_ID

=item $EUID

=item $>

The effective uid of this process.  Example:

    $< = $>;		# set real to effective uid
    ($<,$>) = ($>,$<);	# swap real and effective uid

(Mnemonic: it's the uid you went I<to>, if you're running setuid.)
C<< $< >> and C<< $> >> can be swapped only on machines
supporting setreuid().

=item $REAL_GROUP_ID

=item $GID

=item $(

The real gid of this process.  If you are on a machine that supports
membership in multiple groups simultaneously, gives a space separated
list of groups you are in.  The first number is the one returned by
getgid(), and the subsequent ones by getgroups(), one of which may be
the same as the first number.

However, a value assigned to C<$(> must be a single number used to
set the real gid.  So the value given by C<$(> should I<not> be assigned
back to C<$(> without being forced numeric, such as by adding zero.

(Mnemonic: parentheses are used to I<group> things.  The real gid is the
group you I<left>, if you're running setgid.)

=item $EFFECTIVE_GROUP_ID

=item $EGID

=item $)

The effective gid of this process.  If you are on a machine that
supports membership in multiple groups simultaneously, gives a space
separated list of groups you are in.  The first number is the one
returned by getegid(), and the subsequent ones by getgroups(), one of
which may be the same as the first number.

Similarly, a value assigned to C<$)> must also be a space-separated
list of numbers.  The first number sets the effective gid, and
the rest (if any) are passed to setgroups().  To get the effect of an
empty list for setgroups(), just repeat the new effective gid; that is,
to force an effective gid of 5 and an effectively empty setgroups()
list, say C< $) = "5 5" >.

(Mnemonic: parentheses are used to I<group> things.  The effective gid
is the group that's I<right> for you, if you're running setgid.)

C<< $< >>, C<< $> >>, C<$(> and C<$)> can be set only on
machines that support the corresponding I<set[re][ug]id()> routine.  C<$(>
and C<$)> can be swapped only on machines supporting setregid().

=item $PROGRAM_NAME

=item $0

Contains the name of the program being executed.  On some operating
systems assigning to C<$0> modifies the argument area that the B<ps>
program sees.  This is more useful as a way of indicating the current
program state than it is for hiding the program you're running.
(Mnemonic: same as B<sh> and B<ksh>.)

Note for BSD users: setting C<$0> does not completely remove "perl"
from the ps(1) output.  For example, setting C<$0> to C<"foobar"> will
result in C<"perl: foobar (perl)">.  This is an operating system
feature.

=item $[

The index of the first element in an array, and of the first character
in a substring.  Default is 0, but you could theoretically set it
to 1 to make Perl behave more like B<awk> (or Fortran) when
subscripting and when evaluating the index() and substr() functions.
(Mnemonic: [ begins subscripts.)

As of release 5 of Perl, assignment to C<$[> is treated as a compiler
directive, and cannot influence the behavior of any other file.
Its use is highly discouraged.

=item $]

The version + patchlevel / 1000 of the Perl interpreter.  This variable
can be used to determine whether the Perl interpreter executing a
script is in the right range of versions.  (Mnemonic: Is this version
of perl in the right bracket?)  Example:

    warn "No checksumming!\n" if $] < 3.019;

See also the documentation of C<use VERSION> and C<require VERSION>
for a convenient way to fail if the running Perl interpreter is too old.

The use of this variable is deprecated.  The floating point representation
can sometimes lead to inaccurate numeric comparisons.  See C<$^V> for a
more modern representation of the Perl version that allows accurate string
comparisons.

=item $COMPILING

=item $^C

The current value of the flag associated with the B<-c> switch.
Mainly of use with B<-MO=...> to allow code to alter its behavior
when being compiled, such as for example to AUTOLOAD at compile
time rather than normal, deferred loading.  See L<perlcc>.  Setting
C<$^C = 1> is similar to calling C<B::minus_c>.

=item $DEBUGGING

=item $^D

The current value of the debugging flags.  (Mnemonic: value of B<-D>
switch.)

=item $SYSTEM_FD_MAX

=item $^F

The maximum system file descriptor, ordinarily 2.  System file
descriptors are passed to exec()ed processes, while higher file
descriptors are not.  Also, during an open(), system file descriptors are
preserved even if the open() fails.  (Ordinary file descriptors are
closed before the open() is attempted.)  The close-on-exec
status of a file descriptor will be decided according to the value of
C<$^F> when the corresponding file, pipe, or socket was opened, not the
time of the exec().

=item $^H

WARNING: This variable is strictly for internal use only.  Its availability,
behavior, and contents are subject to change without notice.

This variable contains compile-time hints for the Perl interpreter.  At the
end of compilation of a BLOCK the value of this variable is restored to the
value when the interpreter started to compile the BLOCK.

When perl begins to parse any block construct that provides a lexical scope
(e.g., eval body, required file, subroutine body, loop body, or conditional
block), the existing value of $^H is saved, but its value is left unchanged.
When the compilation of the block is completed, it regains the saved value.
Between the points where its value is saved and restored, code that
executes within BEGIN blocks is free to change the value of $^H.

This behavior provides the semantic of lexical scoping, and is used in,
for instance, the C<use strict> pragma.

The contents should be an integer; different bits of it are used for
different pragmatic flags.  Here's an example:

    sub add_100 { $^H |= 0x100 }

    sub foo {
	BEGIN { add_100() }
	bar->baz($boon);
    }

Consider what happens during execution of the BEGIN block.  At this point
the BEGIN block has already been compiled, but the body of foo() is still
being compiled.  The new value of $^H will therefore be visible only while
the body of foo() is being compiled.

Substitution of the above BEGIN block with:

    BEGIN { require strict; strict->import('vars') }

demonstrates how C<use strict 'vars'> is implemented.  Here's a conditional
version of the same lexical pragma:

    BEGIN { require strict; strict->import('vars') if $condition }

=item %^H

WARNING: This variable is strictly for internal use only.  Its availability,
behavior, and contents are subject to change without notice.

The %^H hash provides the same scoping semantic as $^H.  This makes it
useful for implementation of lexically scoped pragmas.

=item $INPLACE_EDIT

=item $^I

The current value of the inplace-edit extension.  Use C<undef> to disable
inplace editing.  (Mnemonic: value of B<-i> switch.)

=item $^M

By default, running out of memory is an untrappable, fatal error.
However, if suitably built, Perl can use the contents of C<$^M>
as an emergency memory pool after die()ing.  Suppose that your Perl
were compiled with -DPERL_EMERGENCY_SBRK and used Perl's malloc.
Then

    $^M = 'a' x (1 << 16);

would allocate a 64K buffer for use in an emergency.  See the
F<INSTALL> file in the Perl distribution for information on how to
enable this option.  To discourage casual use of this advanced
feature, there is no L<English|English> long name for this variable.

=item $OSNAME

=item $^O

The name of the operating system under which this copy of Perl was
built, as determined during the configuration process.  The value
is identical to C<$Config{'osname'}>.  See also L<Config> and the 
B<-V> command-line switch documented in L<perlrun>.

=item $PERLDB

=item $^P

The internal variable for debugging support.  The meanings of the
various bits are subject to change, but currently indicate:

=over 6

=item 0x01

Debug subroutine enter/exit.

=item 0x02

Line-by-line debugging.

=item 0x04

Switch off optimizations.

=item 0x08

Preserve more data for future interactive inspections.

=item 0x10

Keep info about source lines on which a subroutine is defined.

=item 0x20

Start with single-step on.

=item 0x40

Use subroutine address instead of name when reporting.

=item 0x80

Report C<goto &subroutine> as well.

=item 0x100

Provide informative "file" names for evals based on the place they were compiled.

=item 0x200

Provide informative names to anonymous subroutines based on the place they
were compiled.

=back

Some bits may be relevant at compile-time only, some at
run-time only.  This is a new mechanism and the details may change.

=item $LAST_REGEXP_CODE_RESULT

=item $^R

The result of evaluation of the last successful C<(?{ code })>
regular expression assertion (see L<perlre>).  May be written to.

=item $EXCEPTIONS_BEING_CAUGHT

=item $^S

Current state of the interpreter.  Undefined if parsing of the current
module/eval is not finished (may happen in $SIG{__DIE__} and
$SIG{__WARN__} handlers).  True if inside an eval(), otherwise false.

=item $BASETIME

=item $^T

The time at which the program began running, in seconds since the
epoch (beginning of 1970).  The values returned by the B<-M>, B<-A>,
and B<-C> filetests are based on this value.

=item $PERL_VERSION

=item $^V

The revision, version, and subversion of the Perl interpreter, represented
as a string composed of characters with those ordinals.  Thus in Perl v5.6.0
it equals C<chr(5) . chr(6) . chr(0)> and will return true for
C<$^V eq v5.6.0>.  Note that the characters in this string value can
potentially be in Unicode range.

This can be used to determine whether the Perl interpreter executing a
script is in the right range of versions.  (Mnemonic: use ^V for Version
Control.)  Example:

    warn "No \"our\" declarations!\n" if $^V and $^V lt v5.6.0;

See the documentation of C<use VERSION> and C<require VERSION>
for a convenient way to fail if the running Perl interpreter is too old.

See also C<$]> for an older representation of the Perl version.

=item $WARNING

=item $^W

The current value of the warning switch, initially true if B<-w>
was used, false otherwise, but directly modifiable.  (Mnemonic:
related to the B<-w> switch.)  See also L<warnings>.

=item ${^WARNING_BITS}

The current set of warning checks enabled by the C<use warnings> pragma.
See the documentation of C<warnings> for more details.

=item ${^WIDE_SYSTEM_CALLS}

Global flag that enables system calls made by Perl to use wide character
APIs native to the system, if available.  This is currently only implemented
on the Windows platform.

This can also be enabled from the command line using the C<-C> switch.

The initial value is typically C<0> for compatibility with Perl versions
earlier than 5.6, but may be automatically set to C<1> by Perl if the system
provides a user-settable default (e.g., C<$ENV{LC_CTYPE}>).

The C<bytes> pragma always overrides the effect of this flag in the current
lexical scope.  See L<bytes>.

=item $EXECUTABLE_NAME

=item $^X

The name that the Perl binary itself was executed as, from C's C<argv[0]>.
This may not be a full pathname, nor even necessarily in your path.

=item $ARGV

contains the name of the current file when reading from <>.

=item @ARGV

The array @ARGV contains the command-line arguments intended for
the script.  C<$#ARGV> is generally the number of arguments minus
one, because C<$ARGV[0]> is the first argument, I<not> the program's
command name itself.  See C<$0> for the command name.

=item @INC

The array @INC contains the list of places that the C<do EXPR>,
C<require>, or C<use> constructs look for their library files.  It
initially consists of the arguments to any B<-I> command-line
switches, followed by the default Perl library, probably
F</usr/local/lib/perl>, followed by ".", to represent the current
directory.  If you need to modify this at runtime, you should use
the C<use lib> pragma to get the machine-dependent library properly
loaded also:

    use lib '/mypath/libdir/';
    use SomeMod;

=item @_

Within a subroutine the array @_ contains the parameters passed to that
subroutine.  See L<perlsub>.

=item %INC

The hash %INC contains entries for each filename included via the
C<do>, C<require>, or C<use> operators.  The key is the filename
you specified (with module names converted to pathnames), and the
value is the location of the file found.  The C<require>
operator uses this hash to determine whether a particular file has
already been included.

=item %ENV

=item $ENV{expr}

The hash %ENV contains your current environment.  Setting a
value in C<ENV> changes the environment for any child processes
you subsequently fork() off.

=item %SIG

=item $SIG{expr}

The hash %SIG contains signal handlers for signals.  For example:

    sub handler {	# 1st argument is signal name
	my($sig) = @_;
	print "Caught a SIG$sig--shutting down\n";
	close(LOG);
	exit(0);
    }

    $SIG{'INT'}  = \&handler;
    $SIG{'QUIT'} = \&handler;
    ...
    $SIG{'INT'}  = 'DEFAULT';	# restore default action
    $SIG{'QUIT'} = 'IGNORE';	# ignore SIGQUIT

Using a value of C<'IGNORE'> usually has the effect of ignoring the
signal, except for the C<CHLD> signal.  See L<perlipc> for more about
this special case.

Here are some other examples:

    $SIG{"PIPE"} = "Plumber";   # assumes main::Plumber (not recommended)
    $SIG{"PIPE"} = \&Plumber;   # just fine; assume current Plumber
    $SIG{"PIPE"} = *Plumber;    # somewhat esoteric
    $SIG{"PIPE"} = Plumber();   # oops, what did Plumber() return??

Be sure not to use a bareword as the name of a signal handler,
lest you inadvertently call it. 

If your system has the sigaction() function then signal handlers are
installed using it.  This means you get reliable signal handling.  If
your system has the SA_RESTART flag it is used when signals handlers are
installed.  This means that system calls for which restarting is supported
continue rather than returning when a signal arrives.  If you want your
system calls to be interrupted by signal delivery then do something like
this:

    use POSIX ':signal_h';

    my $alarm = 0;
    sigaction SIGALRM, new POSIX::SigAction sub { $alarm = 1 }
    	or die "Error setting SIGALRM handler: $!\n";

See L<POSIX>.

Certain internal hooks can be also set using the %SIG hash.  The
routine indicated by C<$SIG{__WARN__}> is called when a warning message is
about to be printed.  The warning message is passed as the first
argument.  The presence of a __WARN__ hook causes the ordinary printing
of warnings to STDERR to be suppressed.  You can use this to save warnings
in a variable, or turn warnings into fatal errors, like this:

    local $SIG{__WARN__} = sub { die $_[0] };
    eval $proggie;

The routine indicated by C<$SIG{__DIE__}> is called when a fatal exception
is about to be thrown.  The error message is passed as the first
argument.  When a __DIE__ hook routine returns, the exception
processing continues as it would have in the absence of the hook,
unless the hook routine itself exits via a C<goto>, a loop exit, or a die().
The C<__DIE__> handler is explicitly disabled during the call, so that you
can die from a C<__DIE__> handler.  Similarly for C<__WARN__>.

Due to an implementation glitch, the C<$SIG{__DIE__}> hook is called
even inside an eval().  Do not use this to rewrite a pending exception
in C<$@>, or as a bizarre substitute for overriding CORE::GLOBAL::die().
This strange action at a distance may be fixed in a future release
so that C<$SIG{__DIE__}> is only called if your program is about
to exit, as was the original intent.  Any other use is deprecated.

C<__DIE__>/C<__WARN__> handlers are very special in one respect:
they may be called to report (probable) errors found by the parser.
In such a case the parser may be in inconsistent state, so any
attempt to evaluate Perl code from such a handler will probably
result in a segfault.  This means that warnings or errors that
result from parsing Perl should be used with extreme caution, like
this:

    require Carp if defined $^S;
    Carp::confess("Something wrong") if defined &Carp::confess;
    die "Something wrong, but could not load Carp to give backtrace...
         To see backtrace try starting Perl with -MCarp switch";

Here the first line will load Carp I<unless> it is the parser who
called the handler.  The second line will print backtrace and die if
Carp was available.  The third line will be executed only if Carp was
not available.

See L<perlfunc/die>, L<perlfunc/warn>, L<perlfunc/eval>, and
L<warnings> for additional information.

=back

=head2 Error Indicators

The variables C<$@>, C<$!>, C<$^E>, and C<$?> contain information
about different types of error conditions that may appear during
execution of a Perl program.  The variables are shown ordered by
the "distance" between the subsystem which reported the error and
the Perl process.  They correspond to errors detected by the Perl
interpreter, C library, operating system, or an external program,
respectively.

To illustrate the differences between these variables, consider the 
following Perl expression, which uses a single-quoted string:

    eval q{
	open PIPE, "/cdrom/install |";
	@res = <PIPE>;
	close PIPE or die "bad pipe: $?, $!";
    };

After execution of this statement all 4 variables may have been set.  

C<$@> is set if the string to be C<eval>-ed did not compile (this
may happen if C<open> or C<close> were imported with bad prototypes),
or if Perl code executed during evaluation die()d .  In these cases
the value of $@ is the compile error, or the argument to C<die>
(which will interpolate C<$!> and C<$?>!).  (See also L<Fatal>,
though.)

When the eval() expression above is executed, open(), C<< <PIPE> >>,
and C<close> are translated to calls in the C run-time library and
thence to the operating system kernel.  C<$!> is set to the C library's
C<errno> if one of these calls fails. 

Under a few operating systems, C<$^E> may contain a more verbose
error indicator, such as in this case, "CDROM tray not closed."
Systems that do not support extended error messages leave C<$^E>
the same as C<$!>.

Finally, C<$?> may be set to non-0 value if the external program
F</cdrom/install> fails.  The upper eight bits reflect specific
error conditions encountered by the program (the program's exit()
value).   The lower eight bits reflect mode of failure, like signal
death and core dump information  See wait(2) for details.  In
contrast to C<$!> and C<$^E>, which are set only if error condition
is detected, the variable C<$?> is set on each C<wait> or pipe
C<close>, overwriting the old value.  This is more like C<$@>, which
on every eval() is always set on failure and cleared on success.

For more details, see the individual descriptions at C<$@>, C<$!>, C<$^E>,
and C<$?>.

=head2 Technical Note on the Syntax of Variable Names

Variable names in Perl can have several formats.  Usually, they
must begin with a letter or underscore, in which case they can be
arbitrarily long (up to an internal limit of 251 characters) and
may contain letters, digits, underscores, or the special sequence
C<::> or C<'>.  In this case, the part before the last C<::> or
C<'> is taken to be a I<package qualifier>; see L<perlmod>.

Perl variable names may also be a sequence of digits or a single
punctuation or control character.  These names are all reserved for
special uses by Perl; for example, the all-digits names are used
to hold data captured by backreferences after a regular expression
match.  Perl has a special syntax for the single-control-character
names: It understands C<^X> (caret C<X>) to mean the control-C<X>
character.  For example, the notation C<$^W> (dollar-sign caret
C<W>) is the scalar variable whose name is the single character
control-C<W>.  This is better than typing a literal control-C<W>
into your program.

Finally, new in Perl 5.6, Perl variable names may be alphanumeric
strings that begin with control characters (or better yet, a caret).
These variables must be written in the form C<${^Foo}>; the braces
are not optional.  C<${^Foo}> denotes the scalar variable whose
name is a control-C<F> followed by two C<o>'s.  These variables are
reserved for future special uses by Perl, except for the ones that
begin with C<^_> (control-underscore or caret-underscore).  No
control-character name that begins with C<^_> will acquire a special
meaning in any future version of Perl; such names may therefore be
used safely in programs.  C<$^_> itself, however, I<is> reserved.

Perl identifiers that begin with digits, control characters, or
punctuation characters are exempt from the effects of the C<package>
declaration and are always forced to be in package C<main>.  A few
other names are also exempt:

	ENV		STDIN
	INC		STDOUT
	ARGV		STDERR
	ARGVOUT
	SIG

In particular, the new special C<${^_XYZ}> variables are always taken
to be in package C<main>, regardless of any C<package> declarations
presently in scope.

=head1 BUGS

Due to an unfortunate accident of Perl's implementation, C<use
English> imposes a considerable performance penalty on all regular
expression matches in a program, regardless of whether they occur
in the scope of C<use English>.  For that reason, saying C<use
English> in libraries is strongly discouraged.  See the
Devel::SawAmpersand module documentation from CPAN
(http://www.perl.com/CPAN/modules/by-module/Devel/)
for more information.

Having to even think about the C<$^S> variable in your exception
handlers is simply wrong.  C<$SIG{__DIE__}> as currently implemented
invites grievous and difficult to track down errors.  Avoid it
and use an C<END{}> or CORE::GLOBAL::die override instead.

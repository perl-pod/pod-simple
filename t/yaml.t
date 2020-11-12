# Testing YAML

BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;
use Test::More tests => 202;
use Pod::Simple::YAML;

my $level = 0;
sub z
{
  my $s = ' ' x ( $level * 4 );
  my $ret;
  $level++;
  if ( ref($_[0]) eq 'HASH') {
    $ret = '{' . join("\n", map { "$s$_:".z($_[0]->{$_})} sort keys %{$_[0]}) . '}';
  } elsif ( ref($_[0]) eq 'ARRAY') {
    $ret = '['.join("\n", map { $s . z($_) } @{$_[0]} ).']';
  } elsif (defined($_[0])) {
    $ret = $_[0];
  } else {
    $ret = '<undef>';
  }
  $level--;
  return $ret;
}

sub Y($$$) {
  my $yaml   = Pod::Simple::YAML->new( array_allowed => 1 );
  my $parsed = z($yaml->parse($_[2]));
  my $s      = z($_[1]);
  if ( $s eq $parsed ) {
    ok(1, $_[0]); 
  } else {
    is($parsed, $s, $_[0]);
    diag( $yaml->error . " on line " . $yaml->line);
  }
}

sub N($) {
  my $yaml   = Pod::Simple::YAML->new( array_allowed => 1 );
  my $parsed = $yaml->parse($_[0]);
  if ( !defined $parsed ) {
    ok(1, $yaml->error);
  } else {
    is(z($parsed), undef, "wrongly passed");
  }
}

# document
Y "doc 1", {}, '{}';
Y "doc 2", {}, "---\n{}";
Y "doc 3", {}, "---\n{}\n...";
Y "doc 4", {}, "{}\n...\n";
Y "doc 5", {}, "{}\n...\nfoo";
N "...\n---";
N "---\n---";
N "---\na:1\n---";
N "a:1\n---";

# basics
N '';
N ' ';
N "\n";
N '#  ';
N "\n#comment\n\n\n#comment\n\n";
N "foo";
Y "basic 1", {foo => 42}, "foo: 42";
N "foo:42";
N "\tfoo: 42";
Y "basic 2", {foo => 42}, "foo: 42 # comment";
Y "basic 3", {foo => 42}, " 'foo' : 42";
Y "basic 4", {foo => 42}, ' "foo" : 42';
Y "basic 5", {foo => 42}, "foo : 42 \t";
Y "hash 2", {foo => 42, bar => 43}, "foo: 42\nbar: 43";
Y "hash 3", {foo => 42, bar => 43, baz => 'qaz'}, "foo: 42\nbar: 43 # foo\nbaz: qaz";
Y "null 1", {foo => ''}, "foo:";
Y 'null 2', { foo => '' }, "foo: ~";
Y 'null 3', { foo => '' }, 'foo: !!null null';

# comments
Y 'comments 1', {}, '{} #';
N '{}#';
Y 'comments 2', [1], "[1, #\n]";
N "[1,#\n]";

# unquoted
Y 'unquoted 1', { '-foo' => 42 }, "-foo: 42";
Y 'unquoted 2', { ':foo' => 42 }, ":foo: 42";
Y 'unquoted 3', { '?foo' => 42 }, "?foo: 42";
Y 'unquoted 4', { 'f#oo' => 42 }, "f#oo: 42";
N "f #oo: 42";
Y 'unquoted 5', { 'a' => 'not#a comment' }, "a: not#a comment";
Y 'unquoted 6', { 'a' => 'yes' }, "a: yes # comment";

# strings
Y 'str 1', {str => 'str'}, "str: str";
Y 'str 2', {str => "str\\'"}, "str: str\\'";
Y 'str 3', {str => "str'"}, "str: str'";
N "str:'str";
N "str:'s'tr";
N "str:'s'tr'";
Y 'qstr 1', {str => 'str'}, "str: 'str'";
Y 'qstr 2', {str => "s'tr"}, "str: 's''tr'";
Y 'qqstr 1', {str => 'str'}, 'str: "str"';
N 'str:"str';
N 'str:"s"tr';
N 'str:"s"tr"';
Y 'qqstr 2', {str => 'str'}, 'str: "str"';
Y 'qqstr 3', {str => 'str"'}, 'str: "str\\""';
Y 'qqstr 4', {str => 'str"x'}, 'str: "str\\u0022x"';
Y 'qqstr 5', {str => 'str"x'}, 'str: "str\\U00000022x"';
Y 'qq-end 1', { str => 'ab' }, "str: \"a\\\n b\"";
Y 'qq-end 2', { str => "a\nb" }, "str: \"a\\n\\\n b\"";

# multilines (see examples at https://yaml-multiline.info/)
Y 'plain 1', {str => "a b"}, "str: a\n b";
Y 'plain 2', {str => "a b"}, "str: a\n  b";
Y 'plain 3', {str => "a b c"}, "str: a\n b\n c";
Y 'plain 4', {str => "a b c"}, "str: a\n b\n                     c";
Y 'plain 5', {str => "a b", x => 1}, "str: a\n b\nx: 1";
Y 'plain 6', {str => "a\nb"}, "str: a\n \n b";
Y 'plain 7', {str => "a\nb", x => 1}, "str: a\n \n b\nx: 1";
Y 'plain 8/leading space', {str => "a\nb", x => 1}, "str: a\n \n  b\nx: 1";
Y 'plain 9', {str => "a"}, "str: \n a";
N "- foo: 42\n { bar: 43, baz: 44 }";
Y 'tricky plain 1', { str => "a b:c" }, "str: a\n b:c";
Y 'tricky plain 2', { str => "a b#c" }, "str: a\n b#c";
Y 'tricky plain 3', { str => "val" }, "str: #comment\n             #comment\n val";

Y 'q 1',                { str => "a b"}, "str: 'a\n b'";
Y 'q 2',                { str => "a b c"}, "str: 'a\n b\n c'";
Y 'q 3',                { str => "a b", x => 1}, "str: 'a\n b'\nx: 1";
Y 'q 4/single CR',      { str => "a\nb"}, "str: 'a\n \n b'";
Y 'q 5/comment',        { str => "a b"}, "str: 'a\n b' # muahaha";
Y 'q 6/single CR2',     { str => "a\nb", x => 1}, "str: 'a\n \n b'\nx: 1";
Y 'q 7/leading space',  { str => "a\nb", x => 1}, "str: 'a\n \n  b'\nx: 1";
Y 'q 8/dangling quote', { str => "a\nb", x => 1}, "str: 'a\n \n  b\n '\nx: 1";
N "str: 'a";
N "str: 'a\n";
N "str: 'a\nb''";

Y 'qq 1',                { str => "a b"}, "str: \"a\n b\"";
Y 'qq 2',                { str => "a b c"}, "str: \"a\n b\n c\"";
Y 'qq 3',                { str => "a b", x => 1}, "str: \"a\n b\"\nx: 1";
Y 'qq 4/single CR',      { str => "a\nb"}, "str: \"a\n \n b\"";
Y 'qq 5/comment',        { str => "a b"}, "str: \"a\n b\" # muahaha";
Y 'qq 6/single CR2',     { str => "a\nb", x => 1}, "str: \"a\n \n b\"\nx: 1";
Y 'qq 7/leading space',  { str => "a\nb", x => 1}, "str: \"a\n \n  b\"\nx: 1";
Y 'qq 8/dangling quote', { str => "a\nb", x => 1}, "str: \"a\n \n  b\n \"\nx: 1";
N "str: \"a";
N "str: \"a\n";
N "str: \"a\nb\\\"";

Y 'block null 1', {str => ""}, "str: >";
Y 'block null 2', {str => ""}, "str: |";
Y 'block null 3', {str => "", x => 1}, "str: >-\nx: 1";
Y 'block null 4', {str => "", x => 1}, "str: >-\n \nx: 1";
Y 'block null 5', {str => "b", x => 1}, "str: >-\n b\nx: 1";

Y 'block folded/clip 1', {str => "_a b\nc\n"}, "str: >\n _a\n b\n \n c\n \n \n";
Y 'block folded/clip 2', {str => " a b\nc\n"}, "str: >1\n  a\n b\n \n c\n \n \n";
Y 'block folded/clip 3', {str => " a b\n c\n"}, "str: >1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:>1 bad comment\n  a\n b\n \n c\n \n \n";
Y 'block literal/clip 1', {str => "_a\nb\n\nc\n"}, "str: |\n _a\n b\n \n c\n \n \n";
Y 'block literal/clip 2', {str => " a\nb\n\nc\n"}, "str: |1\n  a\n b\n \n c\n \n \n";
Y 'block literal/clip 3', {str => " a\nb\n\n c\n"}, "str: |1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:|1 bad comment\n  a\n b\n \n c\n \n \n";

Y 'block folded/strip 1', {str => "_a b\nc"}, "str: >-\n _a\n b\n \n c\n \n \n";
Y 'block folded/strip 2', {str => " a b\nc"}, "str: >1-\n  a\n b\n \n c\n \n \n";
Y 'block folded/strip 3', {str => " a b\n c"}, "str: >-1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:|-1 bad comment\n  a\n b\n \n c\n \n \n";
Y 'block literal/strip 1', {str => "_a\nb\n\nc"}, "str: |-\n _a\n b\n \n c\n \n \n";
Y 'block literal/strip 2', {str => " a\nb\n\nc"}, "str: |1-\n  a\n b\n \n c\n \n \n";
Y 'block literal/strip 3', {str => " a\nb\n\n c"}, "str: |-1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:|-1 bad comment\n  a\n b\n \n c\n \n \n";

Y 'block folded/keep 1', {str => "_a b\nc\n\n\n"}, "str: >+\n _a\n b\n \n c\n \n \n";
Y 'block folded/keep 2', {str => " a b\nc\n\n\n"}, "str: >1+\n  a\n b\n \n c\n \n \n";
Y 'block folded/keep 3', {str => " a b\n c\n\n\n"}, "str: >+1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:|+1 bad comment\n  a\n b\n \n c\n \n \n";
Y 'block literal/keep 1', {str => "_a\nb\n\nc\n\n\n"}, "str: |+\n _a\n b\n \n c\n \n \n";
Y 'block literal/keep 2', {str => " a\nb\n\nc\n\n\n"}, "str: |1+\n  a\n b\n \n c\n \n \n";
Y 'block literal/keep 3', {str => " a\nb\n\n c\n\n\n"}, "str: |+1 # comment\n  a\n b\n \n  c\n \n \n";
N "str:|+1 bad comment\n  a\n b\n \n c\n \n \n";

N "str:|@";

# arrays
Y 'array 1', [1, 2, 3], "- 1\n- 2\n- 3";
Y 'array 2', ['str'], "- str";
Y 'array 3', ['str'], "- str # comment";
Y 'array 4', ['str"'], "- \"str\\\"\"";
Y 'array 5', ['a b', 'c d'], "- a\n b\n- c\n d\n";

# complex data
Y 'hash of hashes 1', { a => { b => 1, c => 2 }, d => 3}, "a:\n b: 1\n c: 2\nd: 3";
Y 'hash of hashes 2', { a => { b => { c => 2 }}, d => 3}, "a:\n b: \n  c: 2\nd: 3";
Y 'hash of hashes 3', { a => { b => 2 }, c => {d => 3} }, "a:\n b: 2\nc:\n               d: 3";
Y 'hash of arrays 1', { a => [ 1, 'true', 'str' ], d => 3}, "a:\n - 1\n - true # or false\n - str\nd: 3";
Y 'hash of arrays 2', { a => [ 'str"' ], d => 3}, "a:\n - \"str\\\"\"\nd: 3";
Y 'anon array 1', [], '-';
Y 'anon array 2', [{a=>1}], "-\n a: 1";
Y 'anon array 3', [[4]], "-\n - 4";
Y 'anon array 4', [['']], "-\n -";
Y 'anon array 5', [{a=>1,b=>2},{c=>3}], "-\n a: 1\n b: 2\n-\n c: 3";
Y 'anon array 6', [[1,2],3], "- - 1\n  - 2\n- 3";
Y 'anon array 7', [1,2], "[1,2]";
Y 'anon array 8', [{foo=>'bar'},1], "[foo: bar,1]";
Y 'anon array 9', [1,{foo=> 'bar'}], "[1,foo: bar]";
Y 'anon array 10', [{foo=>'bar'},1], "[\"foo\":bar,1]";
Y 'inline array', {a=>[1.03, 'b', 'foo bar', 'qq qq']}, "a: [1.03, b ,'foo bar' ,\"qq\\x20qq\"]";
Y 'inline array with arrays', {a=>[[1, 'b'], ['foo bar', 'qq qq']]}, "a: [[1, b] ,['foo bar' ,\"qq\\x20qq\"]]";
Y 'inline multiline array', {a=>[1,2,3]}, "a: [1,\n2\n,\n\n      3]";
Y 'inline hash 1',  {a=>{1.03 => 'b', 'foo bar' => 'qq qq'}}, "a: {1.03: b ,'foo bar': \"qq\\x20qq\"}";
Y 'inline hash 2',  {a=>{x => {1 => 'b'}, y => {'foo bar' => 'qq qq'}}}, "a: {x:{1: b} ,y:{'foo bar': \"qq\\x20qq\"}}";
Y 'inline multiline hash', {a => {x=>1,y=>2,z=>3}}, "a: {x: 1\n,y:\n2,\nz\n\n:\n\n3\n\n       }";
Y 'anon hash 1', {1,2}, "{1:'2'}";
Y 'anon hash 2', {1,':2'}, "{1::2}";
N 'a: [1] 2';
N 'a: {} 2';
Y 'hash as array', [{1,2}], "[1: 2,]";
Y 'hash with commas 1', {1,'',2,3}, "{'1',\"2\":3}";
Y 'hash with commas 2', {1,''}, "{'1'}";
Y 'hash with null', {1,''}, "{'1':}";
Y 'subarray on same level', {a=>[1,2],b=>3}, "a:\n- 1\n- 2\nb: 3";

# tags
Y 'tag 1', { foo => 42 },  'foo: !special 42';
Y 'tag 2', { foo => 42 },  'foo: !!str 42';
Y 'tag 3', { foo => 42 },  'foo: !foo!str 42';
Y 'tag 4', { foo => 42 },  'foo: !<foo bar> 42';
Y 'tag 5', { foo => 42 },  "!!str foo:\n !<foo bar>\n 42";
Y 'tag 6', { foo => 42 },  "foo: ! 42";
Y 'tag 7', { '' => '' },  "!!foo: !!str";

N 'foo: |@bar';
N 'foo: >`bar';
N 'foo: `bar';
N 'foo: @bar';

#escapes
Y 'esc 1', { foo => "\a" }, 'foo: "\a"';
Y 'esc 2', { foo => "\b" }, 'foo: "\b"';
Y 'esc 3', { foo => "\f" }, 'foo: "\f"';
Y 'esc 4', { foo => "\e" }, 'foo: "\e"';
Y 'esc 5', { foo => "\n" }, 'foo: "\n"';
Y 'esc 6', { foo => "\r" }, 'foo: "\r"';
Y 'esc 7', { foo => "\x{b}" }, 'foo: "\v"';
Y 'esc 8', { foo => "\x{a0}" }, 'foo: "\_"';
Y 'esc 9', { foo => "\x{85}" }, 'foo: "\N"';
Y 'esc 10', { foo => "\x{2028}" }, 'foo: "\L"';
Y 'esc 11', { foo => "\x{2029}" }, 'foo: "\P"';
Y 'esc 12', { foo => "\x{99}" }, 'foo: "\x99"';
Y 'esc 13', { foo => "\x{9999}" }, 'foo: "\u9999"';
Y 'esc 14', { foo => "\x{00019999}" }, 'foo: "\U00019999"';
Y 'esc 15', { foo => "\n" }, 'foo: "\\n"';
Y 'esc 16', { foo => "\r" }, 'foo: "\\r"';
Y 'esc 17', { foo => "\t" }, 'foo: "\\t"';
Y 'esc 18', { foo => "'" }, 'foo: "\'"';
Y 'esc 19', { foo => '"' }, 'foo: "\\""';

# anchors & aliases
N "foo: !!bool &A1 true\nbar: *A1";

# types
Y 'bool 1', { foo => 1 }, 'foo: !!bool true';
Y 'bool 2', { foo => 0 }, 'foo: !!bool false';
N 'foo: !!bool wtfalse';

# sets
Y 'set 1', [{ foo => 42 }], '- foo: 42';
Y 'set 2', [{ bar => "4 3" }], "- bar: 4\n  3";
Y 'set 3', [{ foo => 42 }, { bar => "4 3" }, { baz => 44 } ], "- foo: 42\n- bar: 4\n  3\n- baz: 44";
Y 'set 4', [{ foo => 42, bar => "4 3", baz => 44 } ], "- foo: 42\n bar: 4\n  3\n baz: 44";
Y 'set 5', {a => ['foo' ]}, "a:\n - foo";
Y 'set 6', {a => [{'foo' => 42} ]}, "a:\n - foo: 42";
N "a:b\n - foo:4\n  2";
Y 'set 7', {a => [{'foo' => "4 2"} ]}, "a:\n - foo: 4\n  2";
# bar and baz must be on 2 spaces
N "a:\n - foo: 42\n bar: 43\n baz: 44";
Y 'set 8', {a => [{ foo => 42, bar => 43, baz => 44 } ]}, "a:\n - foo: 42\n  bar: 43\n  baz: 44";
Y 'set 9', {a => [{ foo => 42, bar => "4 3", baz => 44 } ]}, "a:\n - foo: 42\n  bar: 4\n   3\n  baz: 44";
# this one is tricky: multiline on foo is 2 spaces, which is because -foo itself on level #2.
# however bar is also on 2 spaces due to 'set' syntax that passed on set 7 and 8, - and thus 
# multiline eats bar and barfs
N "a:\n - foo: 4\n   2\n  bar: 4\n   3\n  baz: 44";


#!/usr/bin/perl -w

# t/strip_verbatim_indent.t.t - check verbatim indent stripping feature

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
#use Test::More tests => 87;
use Test::More 'no_plan';

use_ok 'Pod::Simple::Text' or die;

my ($p, $str, $re);

$p = Pod::Simple::Text->new();

$str = q{'};
is $p->is_ending_mlstr($str, undef), undef;

$str = q{my $var =<<"A1SDF" ; };
$re = $p->is_starting_mlstr($str);
is $re, "^A1SDF";
$str = q{A1SDF};
is $p->is_ending_mlstr($str, $re), 1;
$str = q{ A1SDF  };
is $p->is_ending_mlstr($str, $re), 0;
$str = q{"A1SDF";  };
is $p->is_ending_mlstr($str, $re), 0;


$str = q{my $var =<<" ASDF";};
$re = $p->is_starting_mlstr($str);
is $re, "^ ASDF";
$str = q{ASDF};
is $p->is_ending_mlstr($str, $re), 0;
$str = q{ ASDF  };
is $p->is_ending_mlstr($str, $re), 1;
$str = q{"ASDF";  };
is $p->is_ending_mlstr($str, $re), 0;

$str = q{my $var =<<ASDF;};
$re = $p->is_starting_mlstr($str);
is $re, "^ASDF";

$str = q{my $var =<<ASDF};
$re = $p->is_starting_mlstr($str);
is $re, "^ASDF";

$str = q {my $var = "<<asdf";};
$re = $p->is_starting_mlstr($str);
is $re, undef;

$str = q{ my $var = "asdf"; };
$re = $p->is_starting_mlstr($str);
is $re, undef;

$str = q{ my $var = 'Don\'t jump'; };
$re = $p->is_starting_mlstr($str);
is $re, undef;

$str = q{my $var = 'asdf};
$re = $p->is_starting_mlstr($str);

is $re, "'";
$str = q{'};
is $p->is_ending_mlstr($str, $re), 1;
$str = q{end of string';};
is $p->is_ending_mlstr($str, $re), 1;
$str = q{end of string\';};
is $p->is_ending_mlstr($str, $re), 0;
$str = q{end of string'.'starting again};
is $p->is_ending_mlstr($str, $re), 0;
$str = q{end of string'.'again';};
is $p->is_ending_mlstr($str, $re), 1;

$str = q{my $var = $str . "asdf};
$re = $p->is_starting_mlstr($str);
is $re, '"';

$str = q{my $var = "asdf"};
$re = $p->is_starting_mlstr($str);
is $re, undef;

$str = q{my $var = "asdf"."Try };
$re = $p->is_starting_mlstr($str);
is $re, '"';

$str = q{my $var = "asdf".'Try };
$re = $p->is_starting_mlstr($str);
is $re, "'";

$str = q(my $var = q{asdf);
$re = $p->is_starting_mlstr($str);
is $re, "}";

$str = q{my $var = q(asdf)};
$re = $p->is_starting_mlstr($str);
is $re, undef;

$str = q{#Doesn't actually use any of the utf8 bytes.};
$re = $p->is_starting_mlstr($str);
is $re, undef;


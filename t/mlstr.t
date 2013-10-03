#!/usr/bin/perl -w

# t/mlstr.t - check that multi-line strings are handled properly

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
#use Test::More tests => 87;
use Test::More 'no_plan';

use_ok 'Pod::Simple::Text' or die;

my ($p, $str, $re, $in, $out, $txt);

$p = Pod::Simple::Text->new();


# Test the methods that check for the start and end of multi-line strings:
#   is_ending_mlstr and is_ending_mlstr

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


# Test that POD markup inside multi-line strings is ignored

$txt = q{NAME

    Tricky

SYNOPSIS

    Tricky file to test proper POD parsing. POD sections should be
    extracted, but POD hidden into variables should not.

};

$in = q{
#! /usr/bin/env perl

use strict;
use warnings;

=head1 NAME

Tricky

=cut

print "Starting...\n--------\n";

my $var =<<EOS;

=head1 FAKE_POD_SECTION_HERE

This section should not be extracted as POD since it is the content of a
variable, not a POD section

=cut

EOS

print $var;
print "--------\nDone!\n";
exit;

__END__

=head1 SYNOPSIS

Tricky file to test proper POD parsing. POD sections should be extracted, but
POD hidden into variables should not.
};
$p->output_string( \$out );
$p->parse_string_document( $in );
is $out, $txt;


$in = q{
#! /usr/bin/env perl

use strict;
use warnings;

=head1 NAME

Tricky

=cut

print "Starting...\n--------\n";

my $var ="

=head1 FAKE_POD_SECTION_HERE

This section should not be extracted as POD since it is the content of a
variable, not a POD section

=cut

";

print $var;
print "--------\nDone!\n";
exit;

__END__

=head1 SYNOPSIS

Tricky file to test proper POD parsing. POD sections should be extracted, but
POD hidden into variables should not.
};
$p->output_string( \$out );
$p->parse_string_document( $in );
is $out, $txt;


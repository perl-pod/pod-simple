BEGIN {
    chdir 't' if -d 't';
    if($ENV{PERL_CORE}) {
        @INC = '../lib';
    }
}

use strict;
use Test;
BEGIN { plan tests => 5 };

sub source_path {
    my $file = shift;
    if ($ENV{PERL_CORE}) {
        require File::Spec;
        my $updir = File::Spec->updir;
        my $dir = File::Spec->catdir ($updir, 'lib', 'Pod', 'Simple', 't');
        return File::Spec->catfile ($dir, $file);
    } else {
        return $file;
    }
}

use Pod::Simple::HTML;

my $parser  = Pod::Simple::HTML->new();
 
foreach my $file (
  "junk1.pod",
  "junk2.pod",
  "perlcyg.pod",
  "perlfaq3.pod",
  "perlvar.pod",
) {

  unless(-e source_path($file)) {
    ok 0;
    print "# But $file doesn't exist!!\n";
    next;
  }

    my $outfile = $file;
    $outfile =~ s<\.pod><_out.html>s;
    $parser->reinit;
    $parser->parse_from_file( $file, $outfile );
    ok 1;
  }

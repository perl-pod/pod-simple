  
#use Pod::Simple::Debug (10);
use Test;
use File::Spec;
use utf8;
use strict;
#use Pod::Simple::Debug (10);

BEGIN { plan tests => 6 }

use Pod::Simple;
use Pod::Simple::DumpAsXML;

my $thefile;

BEGIN { 

  my $testdir = File::Spec::->catdir( File::Spec::->curdir, 't' );
  if(-e $testdir) {
    chdir $testdir or die "Can't chdir to $testdir : $!";
  }

  my $corpusdir = File::Spec::->catdir( File::Spec::->curdir, 'corpus' );
  if(-e $corpusdir) {
    chdir $corpusdir or die "Can't chdir to $corpusdir : $!";
  }
  $thefile = File::Spec::->catfile( File::Spec::->curdir, 'nonesuch.txt');
  die "Where is nonesuch.txt?!" unless -e $thefile;
}

print "# Testing that nonesuch.txt parses right.\n";
my $outstring;
{
  my $p = Pod::Simple::DumpAsXML->new;
  $p->output_string( \$outstring );
  $p->parse_file( $thefile );
  undef $p;
}
ok 1 ; # make sure it parsed at all
ok( $outstring && length($outstring) ); # make sure it parsed to something.
#print $outstring;
ok( $outstring =~ m/Blorp/ );
ok( $outstring =~ m/errata/ );
ok( $outstring =~ m/unsupported/ );
ok 1;


#use Pod::Simple::Debug (10);
use Test;
use File::Spec;
use utf8;
use strict;
my(@testfiles, %xmlfiles, %wouldxml);
#use Pod::Simple::Debug (10);
BEGIN { 

  my $testdir = File::Spec::->catdir( File::Spec::->curdir, 't' );
  if(-e $testdir) {
    chdir $testdir or die "Can't chdir to $testdir : $!";
  }

  my $corpusdir = File::Spec::->catdir( File::Spec::->curdir, 'corpus' );
  if(-e $corpusdir) {
    chdir $corpusdir or die "Can't chdir to $corpusdir : $!";
  }


  my $thisdir = File::Spec::->curdir;
  opendir(INDIR, $thisdir) or die "Can't opendir $thisdir : $!";
  my @f = map File::Spec::->catfile($thisdir, $_), readdir(INDIR);
  closedir(INDIR);
  my %f;
  @f{@f} = ();
  foreach my $maybetest (sort @f) {
    my $xml = $maybetest;
    $xml =~ s/\.(txt|pod)$/\.xml/is  or  next;
    $wouldxml{$maybetest} = $xml;
    push @testfiles, $maybetest;
    foreach my $x ($xml, uc($xml), lc($xml)) {
      next unless exists $f{$x};
      $xmlfiles{$maybetest} = $x;
      last;
    }
  }
  @testfiles = @ARGV if @ARGV and !grep !m/\.txt/, @ARGV;

  plan tests => (2 + 2*@testfiles - 1);
}

my $HACK = 1;
#@testfiles = ('nonesuch.txt');

ok 1;
{
  my @x = @testfiles;
  print "# Files to test:\n";
  while(@x) {  print "#  ", join(' ', splice @x,0,3), "\n" }
}

require Pod::Simple::DumpAsXML;

foreach my $f (@testfiles) {
  my $xml = $xmlfiles{$f};
  if($xml) {
    print "#\n#To test $f against $xml\n";
  } else {
    print "#\n# $f has no xml to test it against\n";
  }

  my $outstring;
  eval {
    my $p = Pod::Simple::DumpAsXML->new;
    $p->output_string( \$outstring );
    $p->parse_file( $f );
    undef $p;
  };
  
  if($@) {
    my $x = "#** Couldn't parse $f:\n $@";
    $x =~ s/([\n\r]+)/\n#** /g;
    print $x, "\n";
    ok 0;
    ok 0;
    next;
  } else {
    print "# OK, parsing $f generated ", length($outstring), " bytes\n";
    ok 1;
  }
  
  die "Null outstring?" unless $outstring;
  
  next if $f =~ /nonesuch/;

  my $outfilename = ($HACK > 1) ? $wouldxml{$f} : "$wouldxml{$f}\.out";
  if($HACK) {
    open OUT, ">$outfilename" or die "Can't write-open $outfilename: $!\n";
    binmode(OUT);
    print OUT $outstring;
    close(OUT);
  }
  unless($xml) {
    print "#  (no comparison done)\n";
    ok 1;
    next;
  }
  
  open(IN, "<$xml") or die "Can't read-open $xml: $!";
  #binmode(IN);
  local $/;
  my $xmlsource = <IN>;
  close(IN);
  
  print "# There's errata!\n" if $outstring =~ m/start_line="-321"/;
  
  if(
    $xmlsource eq $outstring
    or do {
      $xmlsource =~ s/[\n\r]+/\n/g;
      $outstring =~ s/[\n\r]+/\n/g;
      $xmlsource eq $outstring;
    }
  ) {
    print "#  (Perfect match to $xml)\n";
    unlink $outfilename unless $outfilename =~ m/\.xml$/is;
    ok 1;
    next;
  }
  
  print "#  $outfilename and $xml don't match!\n";
  ok 0;

}


print "#\n# I've been using Encode v", $Encode::VERSION || "(NONE)", "\n";
print "# Byebye\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";


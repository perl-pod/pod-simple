# Testing Pod::Simple::Pod against corpus/*.pod
use strict;

BEGIN {
  if($ENV{PERL_CORE}) {
    chdir 't';
    @INC = '../lib';
  }

  use Config;
  if ($Config::Config{'extensions'} !~ /\bEncode\b/) {
    print "1..0 # Skip: Encode was not built\n";
    exit 0;
  }
}

use File::Find;
use File::Spec;
use Test qw(plan ok skip);

use Pod::Simple::Pod;

my @test_files;

BEGIN {
  sub source_path {
    my $file = shift;
    if ($ENV{PERL_CORE}) {
      require File::Spec;
      my $updir = File::Spec->updir;
      my $dir   = File::Spec->catdir($updir, 'lib', 'Pod', 'Simple', 't');
      return File::Spec->catdir($dir, $file);
    }
    else {
      return $file;
    }
  }

  my @test_dirs = (
    File::Spec->catdir( source_path('t') ) ,
    File::Spec->catdir( File::Spec->updir, 't') ,
  );

  my $test_dir;
  foreach( @test_dirs ) {
    $test_dir = $_ and last if -e;
  }

  die "Can't find the test dir" unless $test_dir;
  print "# TESTDIR: $test_dir\n";

  sub wanted {
    push @test_files, $File::Find::name
      if $File::Find::name =~ /\.pod$/;
  }
  find(\&wanted , $test_dir );

  plan tests => scalar @test_files;
}

foreach my $file (@test_files) {
  my $parser = Pod::Simple::Pod->new();

  my $input;
  open( IN , '<' , $file ) or die "$file: $!";
  $input .= $_ while (<IN>);
  close( IN );

  my $output;
  $parser->output_string( \$output );
  $parser->parse_string_document( $input );

  $input =~ s/^[^=]*(.*)$/$1/mgs;
  $input =~ s/\s*$/\n/s;

  $input = "=pod\n\n$input"
    unless $input =~ /^\s*=pod/mgs;
  $input = "$input\n=cut\n"
    unless $input =~ /=cut\s*$/mgs;

  if ( $output eq $input ) {
    ok 1
  }
  else {
     use Text::Diff;
     print diff \$output , \$input , { STYLE => 'Unified' };

    print "# $file\n";
     ok 0;
#o     exit;

  }
}

BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    } else {
        push @INC, '../lib';
    }
}

use strict;
use Test;
BEGIN { plan tests => 15 };
use Pod::Simple::Select;

BEGIN {
  *mytime = defined(&Win32::GetTickCount)
    ? sub () {Win32::GetTickCount() / 1000}
    : sub () {time()}
}


chdir 't' unless $ENV{PERL_CORE};

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


ok my $p = Pod::Simple::Select->new;
ok defined $p->can('select');
ok defined $p->can('podselect');


my $outfile = '10000';


# Extract entire Pod using object-oriented and functional interface

for my $style ( qw(method function) ) {
  for my $file ( qw(perlcyg.pl perlfaq.pm perlvar.pm) ) {

    unless(-e source_path($file)) {
      ok 0;
      print "# But $file doesn't exist!!\n";
      exit 1;
    }

    my @out;
    my $precooked = source_path($file);
    $precooked =~ s<\.p.$><.pod>s;
    unless(-e $precooked) {
      ok 0;
      print "# But $precooked doesn't exist!!\n";
      exit 1;
    }
  
    print "#\n#\n#\n###################\n# $file\n";
    push @out, '';
    my $t = mytime();

    if ($style eq 'method') {
      $p = Pod::Simple::Select->new;
      $p->output_string(\$out[-1]);
      $p->parse_file(source_path($file));
    } elsif ($style eq 'function') {
      ++$outfile;
      my $out = $outfile.'tmp';
      podselect({-output => $out}, $file);
      $out[-1] = slurp_file($out);
      unlink $out;
    }

    printf "# %s %s %s %sb, %.03fs\n",
     ref($p), $style, source_path($file), length($out[-1]), mytime() - $t ;
    ok 1;

    print "# Reading $precooked...\n";
    push @out, slurp_file($precooked);
    print "#   ", length($out[-1]), " bytes pulled in.\n";

    #for (@out) { s/\s+/ /g; s/^\s+//s; s/\s+$//s; }

    print "#\n# Now comparing 1 and 2...\n";
    if (not is_identical($out[0], $out[1])) {
      ++$outfile;
      write_files(@out);
    }
  }
}


print "# --- Done with ", __FILE__, " --- \n";
exit;


sub is_identical {
  my @out = @_;
  if ($out[0] eq $out[1]) {
    ok 1;
    return 0;
  } else {
    #ok $out[0], $out[1];
    
    my $x = $out[0] ^ $out[1];
    $x =~ m/^(\x00*)/s or die;
    my $at = length($1);
    print "# Difference at byte $at...\n";
    if($at > 10) {
      $at -= 5;
    }
    {
      print "# ", substr($out[0],$at,20), "\n";
      print "# ", substr($out[1],$at,20), "\n";
      print "#      ^...";
    }
    
    ok 0;
    printf "# Unequal lengths %s and %s\n", length($out[0]), length($out[1]);
    return 1;
  }
}


sub write_files {
  my ($txt1, $txt2) = @_;
  my @outnames = map $outfile . $_ , qw(0 1);
  open my $out_fh2, '>', "$outnames[0].txt" || die "Could not read file $outnames[0].txt: $!";

  for my $txt ($txt1, $txt2) {
    push @outnames, $outnames[-1];
    ++$outnames[-1];
  };

  pop @outnames;
  printf "# Writing to %s.txt .. %s.txt\n", $outnames[0], $outnames[-1];
  shift @outnames;
    
  binmode $out_fh2;
  for my $txt ($txt1, $txt2) {
    my $outname = shift @outnames;
    open my $out_fh, '>', "$outname.txt" || die "Could not read file $outname.txt: $!";
    binmode $out_fh;
    print $out_fh $txt, "\n";
    print $out_fh2 $txt, "\n";
    close $out_fh;
   }
  close $out_fh2;
}


sub slurp_file {
  my ($file) = @_;
  my $content;
  open my $in, $file or die "Could not read file '$file': $!\n";
  {
    local $/;
    $content = <$in>;
  }
  close $in;
  return $content;
}

__END__


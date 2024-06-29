# Testing HTMLBatch
use strict;
use warnings;

use Test::More tests => 13;

#sub Pod::Simple::HTMLBatch::DEBUG () {5};

require Pod::Simple::HTMLBatch;;

use File::Spec;
use Cwd;
my $cwd = cwd();
note "CWD: $cwd";

use File::Spec;
use Cwd ();
use File::Basename ();

my $t_dir = File::Basename::dirname(Cwd::abs_path(__FILE__));
my $corpus_dir = File::Spec->catdir($t_dir, 'testlib1');

note "OK, found the test corpus as $corpus_dir";

my $outdir;
while(1) {
  my $rand = sprintf "%05x", rand( 0x100000 );
  $outdir = File::Spec->catdir( $t_dir, "delme-$rand-out" );
  last unless -e $outdir;
}

END {
    use File::Path;
    rmtree $outdir, 0, 0;
}

note "Output dir: $outdir";

mkdir $outdir, 0777 or die "Can't mkdir $outdir: $!";

note "Converting $corpus_dir => $outdir";
my $conv = Pod::Simple::HTMLBatch->new;
$conv->verbose(0);
$conv->index(1);
$conv->batch_convert( [$corpus_dir], $outdir );
note "OK, back from converting";

my @files;
use File::Find;
find( sub {
      push @files, $File::Find::name;
      if (/[.]html\z/ && $_ !~ /perl|index/) {
          # Make sure an index was generated.
          open HTML, $_ or die "Cannot open $_: $!\n";
          my $html = do { local $/; <HTML> };
          close HTML;
          like $html, qr/<div class='indexgroup'>/;
      }
      return;
}, $outdir );

{
  my $long = ( grep m/zikzik\./i, @files )[0];
  ok($long) or diag "How odd, no zikzik file in $outdir!?";
  if($long) {
    $long =~ s{zikzik\.html?\z}{};
    for(@files) { substr($_, 0, length($long)) = '' }
    @files = grep length($_), @files;
  }
}

note "Produced in $outdir ...";
foreach my $f (sort @files) {
    note "  $f";
}
note "(", scalar(@files), " items total)";

# Some minimal sanity checks:
cmp_ok scalar(grep m/\.css\z/i, @files), '>', 5;
cmp_ok scalar(grep m/\.html?\z/i, @files), '>', 5;
cmp_ok scalar(grep m{squaa\W+Glunk.html?\z}i, @files), '>', 0;

if (my @long = grep { /^[^.]{9,}/ } map { File::Basename::basename($_) } @files) {
    ok 0;
    diag "   File names too long:";
    diag "        $_" for @long;
} else {
    ok 1;
}

# use Pod::Simple;
# *pretty = \&Pod::Simple::BlackBox::pretty;

BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }
    print "1..1\nok 1 # skip perl is too old\n" and exit
      if $] < 5.008; # printing to a scalar doesn't work
}

use strict;
use warnings;
use Test::More tests => 14;
use Pod::Simple::Text;

sub Y($$$)
{ 
  my ( $match, $descr, $doc ) = @_;
  my $o = '';
  my $q = Pod::Simple::Text->new();
  open my $fh, ">", \$o;
  $q->output_fh($fh);
  $q->parse_string_document("=pod\n\n$doc\n");
  close $fh;
  unlike( $o, qr/ERRORS/, "check errors for $descr");
  like( $o , $match, $descr);
}

Y qr/foo/, 'framework ok', 'foo';

Y qr/text/, 'plain text after =end',    "=for image src: foo\n\ntext";
Y qr/text/, 'verbatim text after =end', "=for image src: foo\n\n text";
Y qr/text/, 'formatting after =end', "=for image src: foo\n\n=over\n\n=item text\n\n=back\n";

Y qr/text/, 'plain text after =image-text',      "=for image-text src: foo\n\ntext\n\n=for image-cut";
Y qr/text/, 'verbatim text after =image-text',   "=for image-text src: foo\n\n text\n\n=for image-cut";
Y qr/text/, 'formatting text after =image-text', "=for image-text src: foo\n\n=over\n\n=item text\n\n=back\n\n=for image-cut";

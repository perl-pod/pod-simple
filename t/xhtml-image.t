#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 54;
use Pod::Simple::XHTML;

sub prep
{
    my ( $doc, $name ) = @_;
    my $o = '';
    my $q = Pod::Simple::XHTML->new();
    $q->html_header('');
    $q->html_footer('');
    $q->output_string(\$o);
    $q->parse_string_document("=pod\n\n$doc\n");
    unlike( $o, qr/ERRORS/, "check errors for $name");
    return $o;
}

sub Y($$$) { like  ( prep(@_[2,1]) , $_[0], $_[1] ) }
sub N($$$) { unlike( prep(@_[2,1]) , $_[0], $_[1] ) }

# basic
Y qr/foo/,                      'framework ok'    , 'foo';
# =image
Y qr/img src='foo.png'/,        'img src in for'   , "=for image src:foo.png";
Y qr/img src='foo.png'/,        'img src in begin' , "=begin image\n\nsrc: foo.png\n\n=end image";
Y qr/alt='fallback'/,           'img alt'          , "=for image src:foo.png\nalt:fallback";
Y qr/<figure>/,                 'figure'           , "=for image src:foo.png\ntitle:title";
Y qr/figcaption>.*<p>title</s,  'figcaption'       , "=for image src:foo.png\ntitle:title";
Y qr/img src='i&amp;png'/,      'escape'           , "=for image src:i&png";
Y qr/after/,                    'after norm'       ,  "=for image src:i\n\nafter";
Y qr/after/,                    'after verbatim',  ,  "=for image src:i\n\n after";
Y qr/after/,                    'after over'       ,  "=for image src:i\n\n=over\n\n=item after\n\n=back";

Y qr/multiline after/,          'tricky multiline', <<POD;
=begin image

src:foo
title: |
  multiline
  
  after
=end image
POD

# =image-title
Y qr/figcaption.*title/s,       'image-title=for'        , <<POD;
=for image-title src:foo.png

title

=for image-cut
POD

Y qr/after/,                    'image-title=for/after-plain'  , <<POD;
=for image-title src:foo.png

title

=for image-cut

after
POD

Y qr/after/,                    'image-title=for/after-verbatim'  , <<POD;
=for image-title src:foo.png

title

=for image-cut

 after
POD

Y qr/after/,                    'image-title=for/after-over'  , <<POD;
=for image-title src:foo.png

title

=for image-cut

=over

=item after

=back
POD

Y qr/yes/,                    'image-title=precedence'  , <<POD;
=begin image-title

src:foo.png
title:no

=end image-title

yes

=for image-cut
POD

Y qr/after/,                   'image-title=begin/after-plain', <<POD;
=begin image-title

src:foo.png

=end image-title

title

=for image-cut

after

POD

Y qr/after/,                   'image-title=begin/after-verbatim', <<POD;
=begin image-title

src:foo.png

=end image-title

title

=for image-cut

 after

POD

Y qr/after/,                   'image-title=begin/after-over', <<POD;
=begin image-title

src:foo.png

=end image-title

title

=for image-cut

=over

=item after

=back

POD

Y qr/figcaption.*title/s,       'image-title=begin+plain', <<POD;
=begin image-title

src:foo.png

=end image-title

title

=for image-cut
POD

Y qr/figcaption.*title/s,       'image-title=begin+verbatim' , <<POD;
=begin image-title

src:foo.png

=end image-title

  title

=for image-cut
POD

Y qr/figcaption.*\<dt\>.*title/s,  'image-title=begin+over'     , <<POD;
=begin image-title

src:foo.png

=end image-title

=over

=item title

=back

=for image-cut
POD

# =image-text
N qr/skip/,                        'image-text=for/skip'      , <<POD;
=for image-text src:foo.png

skip

=for image-cut
POD

N qr/skip/,                        'image-text=begin/skip-plain'  , <<POD;
=begin image-text

src:foo.png

=end image-text

skip

=for image-cut
POD

N qr/skip/,                        'image-text=begin/skip-verbatim'  , <<POD;
=begin image-text

src:foo.png

=end image-text

  skip

=for image-cut
POD

N qr/skip/,                        'image-text=begin/skip-over'      , <<POD;
=begin image-text

src:foo.png

=end image-text

=over

=item skip

=back

=for image-cut
POD

# found bugs
Y qr/bar/,                        'begin image-text, cut, back'      , <<POD;
=over

foo

=begin image-text

src:foo.png

=end image-text

=for image-cut

bar

=back
POD

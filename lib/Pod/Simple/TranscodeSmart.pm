
require 5;
## This module is to be use()'d only by Pod::Simple::Transcode

package Pod::Simple::TranscodeSmart;
use strict;
require Encode;

sub is_dumb  {0}
sub is_smart {1}

sub all_encodings {
  return Encode::->encodings(':all');
}

sub encoding_is_available {
  return Encode::resolve_alias($_[1]);
}

sub encmodver {
  return "Encode.pm v" .($Encode::VERSION || '?');
}

sub make_transcoder {
  my($e) = $_[1];
  die "WHAT ENCODING!?!?" unless $e;
  my $x;
  return sub {
    foreach $x (@_) { $x = Encode::decode($e, $x) } return;
  };
}


1;



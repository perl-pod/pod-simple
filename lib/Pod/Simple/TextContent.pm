

require 5;
package Pod::Simple::TextContent;
use strict;
use Carp ();
use Pod::Simple ();
use vars qw( @ISA $VERSION );
$VERSION = '1.01';
@ISA = ('Pod::Simple');

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->nix_X_codes(1);
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _handle_element_start {
  print {$_[0]{'output_fh'}} "\n"  unless $_[1] =~ m/^[A-Z]$/s;
  return;
}

sub _handle_text {
  if( chr(65) eq 'A' ) {     # in ASCIIworld
    $_[1] =~ tr/\xAD//d;
    $_[1] =~ tr/\xA0/ /;
  }
  print {$_[0]{'output_fh'}} $_[1];
  return;
}

sub _handle_element_end {
  print {$_[0]{'output_fh'}} "\n"  unless $_[1] =~ m/^[A-Z]$/s;
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
1;


__END__

=head1 NAME

TODO - TODO

=head1 SYNOPSIS

 TODO

  perl -MPod::Simple::TextContent -e \
   "exit Pod::Simple::TextContent->filter(shift)->any_errata_seen" \
   thingy.pod

=head1 DESCRIPTION

This class is for TODO.
This is a subclass of L<Pod::Simple> and inherits all its methods.

TODO

=head1 SEE ALSO

L<Pod::Simple>

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.  All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut


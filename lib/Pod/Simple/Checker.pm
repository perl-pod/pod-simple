
# A quite dimwitted pod2plaintext that need only know how to format whatever
# text comes out of Pod::BlackBox's _gen_errata

require 5;
package Pod::Simple::Checker;
use strict;
use Carp ();
use Pod::Simple::Methody ();
use Pod::Simple ();
use vars qw( @ISA $VERSION );
$VERSION = '1.01';
@ISA = ('Pod::Simple::Methody');
BEGIN { *DEBUG = defined(&Pod::Simple::DEBUG)
          ? \&Pod::Simple::DEBUG
          : sub() {0}
      }

use Text::Wrap 2001.0131 ();
$Text::Wrap::wrap = 'overflow';
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub any_errata_seen {  # read-only accessor
  return $_[1]->{'Errata_seen'};
}

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->{'Thispara'} = '';
  $new->{'Indent'} = 0;
  $new->{'Indentstring'} = '   ';
  $new->{'Errata_seen'} = 0;
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text {  $_[0]{'Errata_seen'} and $_[0]{'Thispara'} .= $_[1] }

sub start_Para  {  $_[0]{'Thispara'} = '' }

sub start_head1 {
  if($_[0]{'Errata_seen'}) {
    $_[0]{'Thispara'} = '';
  } else {
    if($_[1]{'errata'}) { # start of errata!
      $_[0]{'Errata_seen'} = 1;
      $_[0]{'Thispara'} = $_[0]{'source_filename'} ?
        "$_[0]{'source_filename'} -- " : ''
    }
  }
}
sub start_head2 {  $_[0]{'Thispara'} = '' }
sub start_head3 {  $_[0]{'Thispara'} = '' }
sub start_head4 {  $_[0]{'Thispara'} = '' }

sub start_Verbatim    { $_[0]{'Thispara'} = ''   }
sub start_item_bullet { $_[0]{'Thispara'} = '* ' }
sub start_item_number { $_[0]{'Thispara'} = "$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'Thispara'} = ''   }

sub start_over_bullet  { ++$_[0]{'Indent'} }
sub start_over_number  { ++$_[0]{'Indent'} }
sub start_over_text    { ++$_[0]{'Indent'} }
sub start_over_block   { ++$_[0]{'Indent'} }

sub   end_over_bullet  { --$_[0]{'Indent'} }
sub   end_over_number  { --$_[0]{'Indent'} }
sub   end_over_text    { --$_[0]{'Indent'} }
sub   end_over_block   { --$_[0]{'Indent'} }


# . . . . . Now the actual formatters:

sub end_head1       { $_[0]->emit_par(-4) }
sub end_head2       { $_[0]->emit_par(-3) }
sub end_head3       { $_[0]->emit_par(-2) }
sub end_head4       { $_[0]->emit_par(-1) }
sub end_Para        { $_[0]->emit_par( 0) }
sub end_item_bullet { $_[0]->emit_par( 0) }
sub end_item_number { $_[0]->emit_par( 0) }
sub end_item_text   { $_[0]->emit_par(-2) }

sub emit_par {
  return unless $_[0]{'Errata_seen'};
  my($self, $tweak_indent) = splice(@_,0,2);
  my $indent = ' ' x ( 2 * $self->{'Indent'} + ($tweak_indent||0) );
   # Yes, 'STRING' x NEGATIVE gives '', same as 'STRING' x 0

  $self->{'Thispara'} =~ tr{\xAD}{}d if Pod::Simple::ASCII;
  my $out = Text::Wrap::wrap($indent, $indent, $self->{'Thispara'} .= "\n");
  $out =~ tr{\xA0}{ } if Pod::Simple::ASCII;
  print {$self->{'output_fh'}} $out,
    #"\n"
  ;
  $self->{'Thispara'} = '';
  
  return;
}

# . . . . . . . . . . And then off by its lonesome:

sub end_Verbatim  {
  return unless $_[0]{'Errata_seen'};
  my $self = shift;
  if(Pod::Simple::ASCII) {
    $self->{'Thispara'} =~ tr{\xA0}{ };
    $self->{'Thispara'} =~ tr{\xAD}{}d;
  }

  my $i = ' ' x ( 2 * $self->{'Indent'} + 4);
  
  $self->{'Thispara'} =~ s/^/$i/mg;
  
  print { $self->{'output_fh'} }   '', 
    $self->{'Thispara'},
    "\n\n"
  ;
  $self->{'Thispara'} = '';
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
1;

__END__

=head1 NAME

TODO - TODO

=head1 SYNOPSIS

 TODO

  perl -MPod::Simple::Checker -e \
   "exit Pod::Simple::Checker->filter(shift)->any_errata_seen" \
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


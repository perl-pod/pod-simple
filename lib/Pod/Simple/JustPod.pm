use 5;
package Pod::Simple::JustPod;
# ABSTRACT: Pod::Simple formatter that outputs POD
use strict;
use warnings;

use Pod::Simple::Methody ();
our @ISA = ('Pod::Simple::Methody');

sub new {
  my $self = shift;
  my $new  = $self->SUPER::new(@_);

  $new->accept_targets('*');
  $new->keep_encoding_directive(1);
  $new->preserve_whitespace(1);
  $new->_output_is_for_JustPod(1);

  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text       {
  ### FIXME need to figure out how to count number of characters that need to
  ### be escaped

  #### EXAMPLE: C<<< $? >> 8 >>> needs three escapes because of '>>'

  if ( $_[0]{escape} and $_[1] =~ m|([<>]+)|) {
    my $l = '<' x length $1;
    my $r = '>' x length $1;
    $_[1] = "$l $_[1] $r";
  }
  $_[0]{buffer} .= $_[1] unless $_[0]{linkbuffer} ;
}

sub _generic_start {

  # Called from tags like =head1, etc.

  my ($self, $text, $arg) = @_;
  $self->{buffer} .= $text;
}

sub start_Document    { shift->_generic_start("=pod\n\n"); }
sub start_head1       { shift->_generic_start('=head1', @_); }
sub start_head2       { shift->_generic_start('=head2', @_); }
sub start_head3       { shift->_generic_start('=head3', @_); }
sub start_head4       { shift->_generic_start('=head4', @_); }
sub start_encoding    { shift->_generic_start('=encoding', @_); }
# sub start_Para
# sub start_Verbatim

sub start_item_bullet {
  $_[0]{buffer} .= '=item *';

  if ( $_[1]{'~orig_content'} eq '*' ) {
    $_[0]{buffer} .= "\n\n"
  }
  else {
    $_[0]{buffer} .= " ";
  }
}
sub start_item_number { $_[0]{buffer} .= '=item ' }
sub start_item_text   { $_[0]{buffer} .= '=item ' }

sub _end_item {
  my $self = shift;
  $self->emit;
}

*end_item_bullet = *_end_item;
*end_item_number = *_end_item;
*end_item_text   = *_end_item;

sub _start_over  {
  my ($self, $arg) = @_;
  $self->{buffer} .= '=over ' . $arg->{indent} . "\n\n";
}

*start_over_bullet = *_start_over;
*start_over_number = *_start_over;
*start_over_text   = *_start_over;
*start_over_block  = *_start_over;

sub _end_over  {
  my $self = shift;
  $self->{buffer} .= '=back';
  $self->emit;
}

*end_over_bullet = *_end_over;
*end_over_number = *_end_over;
*end_over_text   = *_end_over;
*end_over_block  = *_end_over;

sub end_Document    {
  my $self = shift;
  $self->emit;        # Make sure buffer gets flushed
  print {$self->{'output_fh'} } "=cut\n"
}

sub _end_generic  {
  my $self = shift;
  $self->emit;
}

*end_head1    = *_end_generic;
*end_head2    = *_end_generic;
*end_head3    = *_end_generic;
*end_head4    = *_end_generic;
*end_encoding = *_end_generic;
*end_Para     = *_end_generic;
*end_Verbatim = *_end_generic;

sub _start_fcode {
  my ($type, $self, $flags) = @_;
  $self->{buffer} .= "$type<";
  $self->{escape} = 1;
}

sub start_B { _start_fcode('B', @_); }
sub start_C { _start_fcode('C', @_); }
sub start_E { _start_fcode('E', @_); }
sub start_F { _start_fcode('F', @_); }
sub start_I { _start_fcode('I', @_); }
sub start_S { _start_fcode('S', @_); }
sub start_X { _start_fcode('X', @_); }
sub start_Z { _start_fcode('Z', @_); }

sub _end_fcode {
  my $self = shift;
  $self->{buffer} .= '>';
  $self->{escape} = 0;
}

*end_B   = *_end_fcode;
*end_C   = *_end_fcode;
*end_E   = *_end_fcode;
*end_F   = *_end_fcode;
*end_I   = *_end_fcode;
*end_S   = *_end_fcode;
*end_X   = *_end_fcode;
*end_Z   = *_end_fcode;

sub start_L { $_[0]{buffer} .= 'L<' . $_[1]->{raw} . '>' ; $_[0]->{linkbuffer} = 1 }
sub end_L   { $_[0]{linkbuffer} = 0 }

sub emit {
  my $self = shift;

  print { $self->{'output_fh'} } '',$self->{buffer} ,"\n\n";

  $self->{buffer} = '';

  return;
}

1;

__END__

=head1 NAME

Pod::Simple::JustPod -- format Pod as POD

=head1 SYNOPSIS

  my $parser = Pod::Simple::JustPod->new();
  my $input  = read_in_perl_module();
  my $output;
  $parser->output_string( \$output );
  $parser->parse_string_document( $input );

=head1 DESCRIPTION

This class is a formatter that takes Pod and renders it as
POD.

This is a subclass of L<Pod::Simple::Methody> and inherits all its methods.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Simple::Methody>

=head1 SUPPORT

Questions or discussion about POD and Pod::Simple should be sent to the
pod-people@perl.org mail list. Send an empty email to
pod-people-subscribe@perl.org to subscribe.

This module is managed in an open GitHub repository,
L<https://github.com/theory/pod-simple/>. Feel free to fork and contribute, or
to clone L<git://github.com/theory/pod-simple.git> and send patches!

Patches against Pod::Simple are welcome. Please send bug reports to
<bug-pod-simple@rt.cpan.org>.

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Pod::Simple was created by Sean M. Burke <sburke@cpan.org>.
But don't bother him, he's retired.

Pod::Simple is maintained by:

=over

=item * Allison Randal C<allison@perl.org>

=item * Hans Dieter Pearcey C<hdp@cpan.org>

=item * David E. Wheeler C<dwheeler@cpan.org>

=back

Pod::Simple::JustPod was developed by John SJ Anderson C<genehack@genehack.org>

=cut

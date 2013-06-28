use 5;
package Pod::Simple::Pod;
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

sub start_Document    { $_[0]{buffer} = "=pod\n\n" }

sub start_head1       { $_[0]{buffer} .= '=head1 '    }
sub start_head2       { $_[0]{buffer} .= '=head2 '    }
sub start_head3       { $_[0]{buffer} .= '=head3 '    }
sub start_head4       { $_[0]{buffer} .= '=head4 '    }
sub start_encoding    { $_[0]{buffer} .= '=encoding ' }
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

sub end_item_bullet { $_[0]->emit }
sub end_item_number { $_[0]->emit }
sub end_item_text   { $_[0]->emit }

sub start_over_bullet  { $_[0]{buffer} .= '=over ' . $_[1]->{indent} . "\n\n"}
sub start_over_number  { $_[0]{buffer} .= '=over ' . $_[1]->{indent} . "\n\n"}
sub start_over_text    { $_[0]{buffer} .= '=over ' . $_[1]->{indent} . "\n\n"}
sub start_over_block   { $_[0]{buffer} .= '=over ' . $_[1]->{indent} . "\n\n"}

sub end_over_bullet  { $_[0]->{buffer} .= '=back' ; $_[0]->emit }
sub end_over_number  { $_[0]->{buffer} .= '=back' ; $_[0]->emit }
sub end_over_text    { $_[0]->{buffer} .= '=back' ; $_[0]->emit }
sub end_over_block   { $_[0]->{buffer} .= '=back' ; $_[0]->emit }

sub end_Document    { print {$_[0]{'output_fh'} } "=cut\n" }

sub end_head1       { $_[0]->emit }
sub end_head2       { $_[0]->emit }
sub end_head3       { $_[0]->emit }
sub end_head4       { $_[0]->emit }
sub end_encoding    { $_[0]->emit }
sub end_Para        { $_[0]->emit }
sub end_Verbatim    { $_[0]->emit }

sub start_B { $_[0]{buffer} .= 'B<' ; $_[0]{escape} = 1 }
sub end_B   { $_[0]{buffer} .= '>'  ; $_[0]{escape} = 0 }
sub start_C { $_[0]{buffer} .= 'C<' ; $_[0]{escape} = 1 }
sub end_C   { $_[0]{buffer} .= '>'  ; $_[0]{escape} = 0 }
sub start_F { $_[0]{buffer} .= 'F<' }
sub end_F   { $_[0]{buffer} .= '>'  }
sub start_I { $_[0]{buffer} .= 'I<' ; $_[0]{escape} = 1 }
sub end_I   { $_[0]{buffer} .= '>'  ; $_[0]{escape} = 0 }
sub start_S { $_[0]{buffer} .= 'S<' ; $_[0]{escape} = 1 }
sub end_S   { $_[0]{buffer} .= '>'  ; $_[0]{escape} = 0 }
sub start_X { $_[0]{buffer} .= 'X<' ; $_[0]{escape} = 1 }
sub end_X   { $_[0]{buffer} .= '>'  ; $_[0]{escape} = 0 }

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

Pod::Simple::Pod -- format Pod as POD

=head1 SYNOPSIS

  my $parser = Pod::Simple::Pod->new();
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

Pod::Simple::Pod was developed by John SJ Anderson C<genehack@genehack.org>

=cut

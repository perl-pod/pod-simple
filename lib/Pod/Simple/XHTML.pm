package Pod::Simple::XHTML;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '3.04';
use Carp ();
use Pod::Simple::Methody ();
@ISA = ('Pod::Simple::Methody');

use HTML::Entities 'encode_entities';

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->accept_targets( 'html', 'HTML' );

  $new->nix_X_codes(1);
  $new->add_css_tags(0);
  $new->add_body_tags(1);
  $new->codes_in_verbatim(1);
  $new->{'scratch'} = '';
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_text {
    # escape special characters in HTML (<, >, &, etc)
    $_[0]{'scratch'} .= $_[0]{'in_verbatim'} ? encode_entities( $_[1] ) : $_[1]
}

sub start_Para     { $_[0]{'scratch'} = '<p>' }
sub start_Verbatim { $_[0]{'scratch'} = '<pre><code>'; $_[0]{'in_verbatim'} = 1}

sub start_head1 {  $_[0]{'scratch'} = '<h1>' }
sub start_head2 {  $_[0]{'scratch'} = '<h2>' }
sub start_head3 {  $_[0]{'scratch'} = '<h3>' }
sub start_head4 {  $_[0]{'scratch'} = '<h4>' }

sub start_item_bullet { $_[0]{'scratch'} = '<li>' }
sub start_item_number { $_[0]{'scratch'} = "<li>$_[1]{'number'}. "  }
sub start_item_text   { $_[0]{'scratch'} = '<li>'   }

sub start_over_bullet { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_text   { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_block  { $_[0]{'scratch'} = '<ul>'; $_[0]->emit() }
sub start_over_number { $_[0]{'scratch'} = '<ol>'; $_[0]->emit() }

sub end_over_bullet { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_text   { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_block  { $_[0]{'scratch'} .= '</ul>'; $_[0]->emit() }
sub end_over_number { $_[0]{'scratch'} .= '</ol>'; $_[0]->emit() }

# . . . . . Now the actual formatters:

sub end_Para     { $_[0]{'scratch'} .= '</p>'; $_[0]->emit() }
sub end_Verbatim {
    $_[0]{'scratch'}     .= '</code></pre>';
    $_[0]{'in_verbatim'}  = 0;
    $_[0]->emit();
}

sub end_head1       { $_[0]{'scratch'} .= '</h1>'; $_[0]->emit() }
sub end_head2       { $_[0]{'scratch'} .= '</h2>'; $_[0]->emit() }
sub end_head3       { $_[0]{'scratch'} .= '</h3>'; $_[0]->emit() }
sub end_head4       { $_[0]{'scratch'} .= '</h4>'; $_[0]->emit() }

sub end_item_bullet { $_[0]{'scratch'} .= '</li>'; $_[0]->emit() }
sub end_item_number { $_[0]{'scratch'} .= '</li>'; $_[0]->emit() }
sub end_item_text   { $_[0]->emit() }

# This handles =begin and =for blocks of all kinds.
sub start_for { 
  my ($self, $flags) = @_;
  $self->{'scratch'} .= '<div';
  $self->{'scratch'} .= ' class="'.$flags->{'target'}.'"' if ($flags->{'target'});
  $self->{'scratch'} .= '>';
  $self->emit();

}
sub end_for { 
  my ($self) = @_;
  $self->{'scratch'} .= '</div>';
  $self->emit();
}

sub start_Document { 
  my ($self) = @_;
  if ($self->{'body_tags'}) {
    $self->{'scratch'} .= "<html>\n<body>";
    if ($self->{'css_tags'}) {
      $self->{'scratch'} .= "\n<link rel='stylesheet' href='" .
                            $self->{'css_tags'} .
                            "' type='text/css'>";
    }
    $self->emit();
  }
}
sub end_Document   { 
  my ($self) = @_;
  if ($self->{'body_tags'}) {
    $self->{'scratch'} .= "</body>\n</html>";
    $self->emit();
  }
}

# Handling code tags
sub start_B { $_[0]{'scratch'} .= '<b>' }
sub end_B   { $_[0]{'scratch'} .= '</b>' }

sub start_C { $_[0]{'scratch'} .= '<code>' }
sub end_C   { $_[0]{'scratch'} .= '</code>' }

sub start_E { $_[0]{'scratch'} .= '&' }
sub end_E   { $_[0]{'scratch'} .= ';' }

sub start_F { $_[0]{'scratch'} .= '<i>' }
sub end_F   { $_[0]{'scratch'} .= '</i>' }

sub start_I { $_[0]{'scratch'} .= '<i>' }
sub end_I   { $_[0]{'scratch'} .= '</i>' }

sub start_L { $_[0]{'scratch'} .= '<a href="#' }
sub end_L   { $_[0]{'scratch'} .= '">link</a>' }

sub start_S { $_[0]{'scratch'} .= '<nobr>' }
sub end_S   { $_[0]{'scratch'} .= '</nobr>' }

sub emit {
  my($self) = @_;
  my $out = $self->{'scratch'} . "\n";
  print {$self->{'output_fh'}} $out, "\n";
  $self->{'scratch'} = '';
  return;
}

# Set additional options

sub add_body_tags { $_[0]{'body_tags'} = $_[1] }
sub add_css_tags { $_[0]{'css_tags'} = $_[1] }

# bypass built-in E<> handling to preserve entity encoding
sub _treat_Es {} 

1;

__END__

=head1 NAME

Pod::Simple::XHTML -- format Pod as validating XHTML

=head1 SYNOPSIS

  use Pod::Simple::HTML;

  my $parser = Pod::PseudoPod::HTML->new();

  ...

  $parser->parse_file('path/to/file.pod');

=head1 DESCRIPTION

This class is a formatter that takes Pod and renders it as XHTML
validating HTML.

This is a subclass of L<Pod::Simple::Methody> and inherits all its methods.

=head1 METHODS

=head2 add_body_tags

  $parser->add_body_tags(1);
  $parser->parse_file($file);

Adds beginning and ending "<html>" and "<body>" tags to the formatted
document.

=head2 add_css_tags

  $parser->add_css_tags('path/to/style.css');
  $parser->parse_file($file);

Imports a css stylesheet to the html document and adds additional css
tags to url, footnote, and sidebar elements for a nicer display. If
you don't plan on writing a style.css file (or using the one provided
in "examples/"), you probably don't want this option on.

=head1 SEE ALSO

L<Pod::Simple>, L<Pod::Simple::Methody>

=head1 COPYRIGHT

Copyright (c) 2003-2005 Allison Randal.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

This library is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Allison Randal <allison@perl.org>

=cut


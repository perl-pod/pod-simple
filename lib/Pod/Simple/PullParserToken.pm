
require 5;
package Pod::Simple::PullParserToken;
 # Base class for tokens gotten from Pod::Simple::PullParser's $parser->get_token
@ISA = ();
$VERSION = 1.02;
use strict;

sub new {  # Class->new('type', stuff...);  ## Overridden in derived classes anyway
  my $class = shift;
  return bless [@_], ref($class) || $class;
}

sub type { $_[0][0] }  # Can't change the type of an object
sub dump { Pod::Simple::pretty( [ @{ $_[0] } ] ) }

sub is_start { $_[0][0] eq 'start' }
sub is_end   { $_[0][0] eq 'end'   }
sub is_text  { $_[0][0] eq 'text'  }

1;
__END__

sub dump { '[' . _esc( @{ $_[0] } ) . ']' }

# JUNK:
#use utf8;   # Lame Perls would need this, if we generated Unicode
# characters for them anyway.

sub _esc {
  return '' unless @_;
  my @out;
  foreach my $in (@_) {
    push @out, '"' . $in . '"';
    $out[-1] =~ s/([^- \:\:\.\,\'\>\<\"\/\=\?\+\|\[\]\{\}\_a-zA-Z0-9_\`\~\!\#\%\^\&\*\(\)])/
      sprintf( (ord($1) < 256) ? "\\x%02X" : "\\x{%X}", ord($1))
    /eg;
  }
  return join ', ', @out;
}


__END__

=head1 NAME

TODO - TODO

=head1 SYNOPSIS

 TODO

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


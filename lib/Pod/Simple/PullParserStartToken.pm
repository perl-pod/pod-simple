
require 5;
package Pod::Simple::PullParserStartToken;
use Pod::Simple::PullParserToken ();
@ISA = ('Pod::Simple::PullParserToken');
use strict;

sub new {  # Class->new(tagname, optional_attrhash);
  my $class = shift;
  return bless ['start', @_], ref($class) || $class;
}

# Purely accessors:

sub tagname   { (@_ == 2) ? ($_[0][1] = $_[1]) : $_[0][1] }

sub attr_hash { $_[0][2] ||= {} }

sub attr      {
  if(@_ == 2) {      # Reading: $token->attr('attrname')
    ${$_[0][2] || return undef}{ $_[1] };
  } elsif(@_ > 2) {  # Writing: $token->attr('attrname', 'newval')
    ${$_[0][2] ||= {}}{ $_[1] } = $_[2];
  } else {
    require Carp;
    Carp::croak(
      'usage: $object->attr("val") or $object->attr("key", "newval")');
    return undef;
  }
}

1;


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


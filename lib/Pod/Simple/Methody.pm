
require 5;
package Pod::Simple::Methody;
use strict;
use Pod::Simple ();
use vars qw(@ISA);
@ISA = ('Pod::Simple');

sub _handle_element_start {
  $_[1] =~ tr/-:./__/;
  ( $_[0]->can( 'start_' . $_[1] )
    || return
  )->(
    $_[0], $_[2]
  );
}

sub _handle_text {
  ( $_[0]->can( 'handle_text' )
    || return
  )->(
    @_
  );
}

sub _handle_element_end {
  $_[1] =~ tr/-:./__/;
  ( $_[0]->can( 'end_' . $_[1] )
    || return
  )->(
    $_[0]
  );
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


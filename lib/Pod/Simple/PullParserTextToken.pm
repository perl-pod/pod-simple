
require 5;
package Pod::Simple::PullParserTextToken;
use Pod::Simple::PullParserToken ();
@ISA = ('Pod::Simple::PullParserToken');
use strict;

sub new {  # Class->new(text);
  my $class = shift;
  return bless ['text', @_], ref($class) || $class;
}

# Purely accessors:

sub text { (@_ == 2) ? ($_[0][1] = $_[1]) : $_[0][1] }


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


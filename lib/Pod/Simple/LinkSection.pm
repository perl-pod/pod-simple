
require 5;
package Pod::Simple::LinkSection;
  # Based somewhat dimly on Array::Autojoin

use strict;
use Pod::Simple::BlackBox;

use overload( # So it'll stringify nice
  '""'   => \&Pod::Simple::BlackBox::stringify_lol,
  'bool' => \&Pod::Simple::BlackBox::stringify_lol,
  # '.='   => \&tack_on,  # grudgingly support
  
  'fallback' => 1,         # turn on cleverness
);

sub tack_on {
  $_[0] = ['', {}, "$_[0]" ];
  return $_[0][2] .= $_[1];
}

sub as_string {
  goto &Pod::Simple::BlackBox::stringify_lol;
}
sub stringify {
  goto &Pod::Simple::BlackBox::stringify_lol;
}

sub new {
  my $class = shift;
  $class = ref($class) || $class;
  my $new;
  if(@_ == 1) {
    if (!ref($_[0] || '')) { # most common case: one bare string
      return bless ['', {}, $_[0] ], $class;
    } elsif( ref($_[0] || '') eq 'ARRAY') {
      $new = [ @{ $_[0] } ];
    } else {
      Carp::croak( "$class new() doesn't know to clone $new" );
    }
  } else { # misc stuff
    $new = [ '', {}, @_ ];
  }

  # By now it's a treelet:  [ 'foo', {}, ... ]
  foreach my $x (@$new) {
    if(ref($x || '') eq 'ARRAY') {
      $x = $class->new($x); # recurse
    } elsif(ref($x || '') eq 'HASH') {
      $x = { %$x };
    }
     # otherwise leave it.
  }

  return bless $new, $class;
}

# Not much in this class is likely to be link-section specific --
# but it just so happens that link-sections are about the only treelets
# that are exposed to the user.

1;

__END__

# TODO: let it be an option whether a given subclass even wants little treelets?


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


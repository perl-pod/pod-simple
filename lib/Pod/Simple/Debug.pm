
require 5;
package Pod::Simple::Debug;
use strict;

sub import {
  my($value,$variable);
  
  if(@_ == 2) {
    $value = $_[1];
  } elsif(@_ == 3) {
    ($variable, $value) = @_[1,2];
    
    ($variable, $value) = ($value, $variable)
       if     defined $value    and ref($value)    eq 'SCALAR'
      and not(defined $variable and ref($variable) eq 'SCALAR')
    ; # tolerate getting it backwards
    
    unless( defined $variable and ref($variable) eq 'SCALAR') {
      require Carp;
      Carp::croak("Usage:\n use Pod::Simple::Debug (NUMVAL)\nor"
                . "\n use Pod::Simple::Debug (\\\$var, STARTNUMVAL)\nAborting");
    }
  } else {
    require Carp;
    Carp::croak("Usage:\n use Pod::Simple::Debug (NUMVAL)\nor"
                    . "\n use Pod::Simple::Debug (\\\$var, STARTNUMVAL)\nAborting");
  }

  if( defined &Pod::Simple::DEBUG ) {
    require Carp;
    Carp::croak("It's too late to call Pod::Simple::Debug -- "
              . "Pod::Simple has already loaded\nAborting");
  }
  
  $value = 0 unless defined $value;

  unless($value =~ m/^-?\d+$/) {
    require Carp;
    Carp::croak( "$value isn't a numeric value."
            . "\nUsage:\n use Pod::Simple::Debug (NUMVAL)\nor"
                    . "\n use Pod::Simple::Debug (\\\$var, STARTNUMVAL)\nAborting");
  }

  if( defined $variable ) {
    # make a not-really-constant
    *Pod::Simple::DEBUG = sub () { $$variable } ;
    $$variable = $value;
    print "# Starting Pod::Simple::DEBUG = non-constant $variable with val $value\n";
  } else {
    *Pod::Simple::DEBUG = eval " sub () { $value } ";
    print "# Starting Pod::Simple::DEBUG = $value\n";
  }
  
  require Pod::Simple;
  return;
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



use strict;
package Pod::Simple::TiedOutFH;
use Symbol ('gensym');
use Carp ();

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub handle_on { # some horrible frightening things are encapsulated in here
  my $class = shift;
  $class = ref($class) || $class;
  
  Carp::croak "Usage: ${class}->handle_on(\$somescalar)" unless @_;
  
  my $x = (defined($_[0]) and ref($_[0]))
    ? $_[0]
    : ( \( $_[0] ) )[0]
  ;
  $$x = '' unless defined $$x;
  
  #Pod::Simple::DEBUG and print "New $class handle on $x = \"$$x\"\n";
  
  my $new = gensym();
  tie *$new, $class, $x;
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub TIEHANDLE {  # Ties to just a scalar ref
  my($class, $scalar_ref) = @_;
  $$scalar_ref = '' unless defined $$scalar_ref;
  return bless \$scalar_ref,  ref($class) || $class;
}

sub PRINT {
  my $it = shift;
  foreach my $x (@_) { $$$it .= $x }

  #Pod::Simple::DEBUG > 10 and print " appended to $$it = \"$$$it\"\n";

  return 1;
}

sub FETCH {
  return ${$_[0]};
}

sub PRINTF {
  my $it = shift;
  my $format = shift;
  $$$it .= sprintf $format, @_;
  return 1;
}

sub CLOSE { 1 }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1;
__END__


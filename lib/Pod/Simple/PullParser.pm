
require 5;
package Pod::Simple::PullParser;
$VERSION = '1.01';
use Pod::Simple ();
BEGIN {@ISA = ('Pod::Simple')}

use strict;

use Carp ();

use Pod::Simple::PullParserStartToken;
use Pod::Simple::PullParserEndToken;
use Pod::Simple::PullParserTextToken;

BEGIN { *DEBUG = \&Pod::Simple::DEBUG unless defined &DEBUG }

__PACKAGE__->_accessorize(
  'source_fh',         # the filehandle we're reading from
  'source_scalar_ref', # the scalarref we're reading from
  'source_arrayref',   # the arrayref we're reading from
);

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
#  And here is how we implement a pull-parser on top of a push-parser...

sub filter {
  my($self, $source) = @_;
  $self = $self->new unless ref $self;
  my $d;
  $self->output_string(\$d);
  $self->set_source($source);
  $self->run; # define run() in a subclass if you want to use filter()!
  return $d;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  die "Couldn't construct for $class" unless $self;

  $self->{'token_buffer'} ||= [];
  $self->{'start_token_class'} ||= 'Pod::Simple::PullParserStartToken';
  $self->{'text_token_class'}  ||= 'Pod::Simple::PullParserTextToken';
  $self->{'end_token_class'}   ||= 'Pod::Simple::PullParserEndToken';

  DEBUG > 1 and print "New pullparser object: $self\n";

  return $self;
}


sub get_token {
  my $self = shift;
  DEBUG > 1 and print "\nget_token starting up on $self.\n";
  DEBUG > 2 and print " Items in token-buffer (",
   scalar( @{ $self->{'token_buffer'} } ) ,
   ") :\n", map(
     "    " . $_->dump . "\n", @{ $self->{'token_buffer'} }
   ),
   @{ $self->{'token_buffer'} } ? '' : '       (no tokens)',
   "\n"
  ;

  until( @{ $self->{'token_buffer'} } ) {
    DEBUG > 3 and print "I need to get something into my empty token buffer...\n";
    if($self->{'source_dead'}) {
      DEBUG and print "$self 's source is dead.\n";
      push @{ $self->{'token_buffer'} }, undef;
    } elsif(exists $self->{'source_fh'}) {
      my @lines;
      my $fh = $self->{'source_fh'}
       || Carp::croak('You have to call set_source before you can call get_token');
       
      DEBUG and print "$self 's source is filehandle $fh.\n";
      # Read those many lines at a time
      for(my $i = Pod::Simple::MANY_LINES; $i--;) {
        DEBUG > 3 and print " Fetching a line...\n";
        push @lines, scalar(<$fh>);
        unless( defined $lines[-1] ) {
          DEBUG and print "That's it for that source fh!  Killing.\n";
          delete $self->{'source_fh'}; # so it can be GC'd
          last;
        }
         # but pass thru the undef, which will set source_dead to true
      }
      $self->parse_lines(@lines);
      
    } elsif(exists $self->{'source_arrayref'}) {
      DEBUG and print "$self 's source is arrayref $self->{'source_arrayref'}, with ",
       scalar(@{$self->{'source_arrayref'}}), " items left in it.\n";

      DEBUG > 3 and print "  Fetching ", Pod::Simple::MANY_LINES, " lines.\n";
      $self->parse_lines(
        splice @{ $self->{'source_arrayref'} },
        0,
        Pod::Simple::MANY_LINES
      );
      unless( @{ $self->{'source_arrayref'} } ) {
        DEBUG and print "That's it for that source arrayref!  Killing.\n";
        $self->parse_lines(undef);
        delete $self->{'source_arrayref'}; # so it can be GC'd
      }
       # to make sure that an undef is always sent to signal end-of-stream

    } elsif(exists $self->{'source_scalar_ref'}) {

      DEBUG and print "$self 's source is scalarref $self->{'source_scalar_ref'}, with ",
        length(${ $self->{'source_scalar_ref'} }) -
        (pos(${ $self->{'source_scalar_ref'} }) || 0),
        " characters left to parse.\n";

      DEBUG > 3 and print " Fetching a line...\n";
      if( ${ $self->{'source_scalar_ref'} } =~
        m/([^\n\r]*)((?:\r?\n)?)/g
      ) {
        #print(">> $1\n"),
        $self->parse_lines($1)
         if length($1) or length($2)
          or pos(     ${ $self->{'source_scalar_ref'} })
           != length( ${ $self->{'source_scalar_ref'} });
         # I.e., unless it's a zero-length "empty line" at the very
         #  end of "foo\nbar\n" (i.e., between the \n and the EOS).
      } else { # that's the end.  Byebye
        $self->parse_lines(undef);
        delete $self->{'source_scalar_ref'};
        DEBUG and print "That's it for that source scalarref!  Killing.\n";
      }

      
    } else {
      die "What source??";
    }
  }
  DEBUG and print "get_token about to return ",
   Pod::Simple::pretty( @{$self->{'token_buffer'}}
     ? $self->{'token_buffer'}[-1] : undef
   ), "\n";
  return shift @{$self->{'token_buffer'}}; # that's an undef if empty
}

use UNIVERSAL ();
sub unget_token {
  my $self = shift;
  DEBUG and print "Ungetting ", scalar(@_), " tokens: ",
   @_ ? "@_\n" : "().\n";
  foreach my $t (@_) {
    Carp::croak "Can't unget that, because it's not a token -- it's undef!"
     unless defined $t;
    Carp::croak "Can't unget $t, because it's not a token -- it's a string!"
     unless ref $t;
    Carp::croak "Can't unget $t, because it's not a token object!"
     unless UNIVERSAL::can($t, 'type');
  }
  
  unshift @{$self->{'token_buffer'}}, @_;
  DEBUG > 1 and print "Token buffer now has ",
   scalar(@{$self->{'token_buffer'}}), " items in it.\n";
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

# $self->{'source_filename'} = $source;

sub set_source {
  my $self = shift @_;
  return $self->{'source_fh'} unless @_;
  my $handle;
  if(!defined $_[0]) {
    Carp::croak("Can't use empty-string as a source for set_source");
  } elsif(ref(\( $_[0] )) eq 'GLOB') {
    $self->{'source_filename'} = '' . ($handle = $_[0]);
    DEBUG and print "$self 's source is glob $_[0]\n";
    # and fall thru   
  } elsif(ref( $_[0] ) eq 'SCALAR') {
    $self->{'source_scalar_ref'} = $_[0];
    DEBUG and print "$self 's source is scalar ref $_[0]\n";
    return;
  } elsif(ref( $_[0] ) eq 'ARRAY') {
    $self->{'source_arrayref'} = $_[0];
    DEBUG and print "$self 's source is array ref $_[0]\n";
    return;
  } elsif(ref $_[0]) {
    $self->{'source_filename'} = '' . ($handle = $_[0]);
    DEBUG and print "$self 's source is fh-obj $_[0]\n";
  } elsif(!length $_[0]) {
    Carp::croak("Can't use empty-string as a source for set_source");
  } else {  # it's a filename
    DEBUG and print "$self 's source is filename $_[0]\n";
    {
      local *PODSOURCE;
      open(PODSOURCE, "<$_[0]") || Carp::croak "Can't open $_[0]: $!";
      $handle = *PODSOURCE{IO};
    }
    $self->{'source_filename'} = $_[0];
    DEBUG and print "  Its name is $_[0].\n";

    # TODO: file-discipline things here!
  }

  $self->{'source_fh'} = $handle;
  DEBUG and print "  Its handle is $handle\n";
  return 1;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
#  Methods that actually do work at parse-time:

sub _handle_element_start {
  my $self = shift;   # leaving ($element_name, $attr_hash_r)
  DEBUG > 2 and print "++ $_[0] (", map("<$_> ", %{$_[1]}), ")\n";
  
  push @{ $self->{'token_buffer'} },
       $self->{'start_token_class'}->new(@_);
  return;
}

sub _handle_text {
  my $self = shift;   # leaving ($text)
  DEBUG > 2 and print "== $_[0]\n";
  push @{ $self->{'token_buffer'} },
       $self->{'text_token_class'}->new(@_);
  return;
}

sub _handle_element_end {
  my $self = shift;   # leaving ($element_name);
  DEBUG > 2 and print "-- $_[0]\n";
  push @{ $self->{'token_buffer'} }, 
       $self->{'end_token_class'}->new(@_);
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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


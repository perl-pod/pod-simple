
require 5;
package Pod::Simple::HTML;
use strict;
use Pod::Simple::PullParser (); # for its _xml_esc
use vars qw(@ISA %Tagmap $Computerese $Lame);
@ISA = ('Pod::Simple::PullParser');

sub DEBUG () {0}

$Computerese =  " lang='und' xml:lang='und'" unless defined $Computerese;
$Lame = ' class="pad"' unless defined $Lame;

%Tagmap = (
  'Verbatim'  => "\n<pre$Computerese>",
  '/Verbatim' => "</pre>\n",
  'Data'  => "\n",
  '/Data' => "\n",
  changes(qw(
    Para=p
    head1=h1 head2=h2 head3=h3 head4=h4 B=b I=i
    over-bullet=ul
    over-number=ol
    over-text=dl
    over-block=blockquote
    item-bullet=li
    item-number=li
    item-text=dt
  )),
  '/item-bullet' => "</li><p$Lame></p>\n",
  '/item-number' => "</li><p$Lame></p>\n",
  '/item-text'   => "</li><p$Lame></p>\n",
  'Para_item'    => "\n<dd>",
  '/Para_item'   => "</dd><p$Lame></p>\n",

  'B'      =>  "<b>",                  '/B'     =>  "</b>",
  'I'      =>  "<i>",                  '/I'     =>  "</i>",
  'F'      =>  "<em$Computerese>",     '/F'     =>  "</em>",
  'C'      =>  "<code$Computerese>",   '/C'     =>  "</code>",
  'L'  =>  "<a href='YOU_SHOULD_NEVER_SEE_THIS'>", # ideally never used!
  '/L' =>  "</a>",
);



sub changes {
  return map {; m/^([-_:0-9a-zA-Z]+)=([-_:0-9a-zA-Z]+)$/s
     ? ( $1, => "\n<$2>", "/$1", => "</$2>\n" ) : die "Funky $_"
  } @_;
}

sub new {
  my $new = shift->SUPER::new(@_);
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->accept_directive_as_data( 'html', 'HTML' );
  $new->{'Tagmap'} = {%Tagmap};
  return $new;
}

sub run {
  my $self = $_[0];
  return
   $self->do_beginning && $self->do_middle && $self->do_end;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_pod_link { return "TODO" }
sub do_url_link { return $_[1]->attr('to') }
sub do_man_link { return "TODO" }

sub do_link {
  my($self, $token) = @_;
  my $type = $token->attr('type');
  if(!defined $type) {
    $self->whine("Typeless L!?", $token->attr('start_line'));
  } elsif( $type eq 'pod') { return $self->do_pod_link($token);
  } elsif( $type eq 'url') { return $self->do_url_link($token);
  } elsif( $type eq 'man') { return $self->do_man_link($token);
  } else {
    $self->whine("L of unknown type $type!?", $token->attr('start_line'));
  }
  return 'FNORG';
}

sub do_middle {      # the main work
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  
  my($token, $type, $tagname);
  my @stack;
  while($token = $self->get_token) {
    if( ($type = $token->type) eq 'start' ) {
      if(($tagname = $token->tagname) eq 'L') {
        esc($type = $self->do_link($token)); # reuse it, why not
        print $fh "<a href='$type'>";
      } else {
        if( $tagname =~ m/^over-(.+)$/s ) {
          push @stack, $1;
        } elsif( $tagname eq 'Para') {
          $tagname = 'Para_item' if @stack and $stack[-1] eq 'text';
        }
        print $fh $self->{'Tagmap'}{$tagname} || next;
      }
    } elsif( $type eq 'end' ) {
      if( ($tagname = $token->tagname) =~ m/^over-/s ) {
        pop @stack;
      } elsif( $tagname eq 'Para' ) {
        $tagname = 'Para_item' if @stack and $stack[-1] eq 'text';
      }
      print $fh $self->{'Tagmap'}{"/$tagname"} || next;
    } elsif( $type eq 'text' ) {
      esc($type = $token->text); # reuse it, why not
      print $fh $type;
    }
  }
  return 1;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub do_beginning {			# tricky!
  my $self = $_[0];

  # Try to find the title
  my $title;
  {
    my @to_unget;
    while(1) {
      push @to_unget, $self->get_token;
      unless(defined $to_unget[-1]) { # whoops, short doc!
        pop @to_unget;
        if(@to_unget < 3) {
          DEBUG and print "Aborting do_beginning...\n";
          return 0;
        }
        last;
      }

      DEBUG and print "-Got token ", $to_unget[-1]->dump, "\n";

      (DEBUG and print "Too much in the buffer.\n"),
       last if @to_unget > 25; # sanity
      
      my $pattern = '';
      if( #$to_unget[-1]->type eq 'end'
          #and $to_unget[-1]->tagname eq 'Para'
          #and
          ($pattern = join('',
           map {;
              ($_->type eq 'start') ? ("<" . $_->tagname .">")
            : ($_->type eq 'end'  ) ? ("</". $_->tagname .">")
            : ($_->type eq 'text' ) ? ($_->text =~ m<^([A-Z]+)$>s ? $1 : 'X')
            : "BLORP"
           } @to_unget
         )) =~ m{<head1>NAME</head1><Para>X+</Para>$}s
      ) {
        # Whee, it fits the pattern
        $title = '';
        foreach my $t (reverse @to_unget) {
          last if $t->type eq 'start';
          $title = $t->text . $title if $t->type eq 'text';
        }
        undef $title if $title =~ m<^\s*$>; # make sure it's contentful!
        last;
      } else {
        DEBUG and $pattern and print "Leading pattern: $pattern\n";
      }
    }
    $self->unget_token(@to_unget);
  }
  
  $title = '' unless defined $title;
  $self->{'Title'} = $title;

  esc($title);
  print {$self->{'output_fh'}}
   "<html><head>\n<title>$title</title>\n</head>\n<body>\n", 
   "<!-- start doc -->\n",
  ;
   # TODO: more configurability there

  DEBUG and print "Returning from do_beginning...\n";
  return 1;
}


sub do_end {
  my $self = $_[0];
  print {$self->{'output_fh'}} "\n<!-- end doc -->\n</body></html>\n";
   # TODO: allow for a footer
  return 1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub esc {
  if(defined wantarray) {
    if(wantarray) {
      @_ = splice @_; # break aliasing
    } else {
      my $x = shift;
      $x =~ s/([^-\n\t !\#\$\%\(\)\*\+,\.\~\/\:\;=\?\@\[\\\]\^_\`\{\|\}abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789])/'&#'.(ord($1)).';'/eg;
      return $x;
    }
  }
  foreach my $x (@_) {
    # Escape things very cautiously:
    $x =~ s/([^-\n\t !\#\$\%\(\)\*\+,\.\~\/\:\;=\?\@\[\\\]\^_\`\{\|\}abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789])/'&#'.(ord($1)).';'/eg;
    # Yes, stipulate the list without a range, so that this can work right on
    #  all charsets that this module happens to run under.
    # Altho, hmm, what about that ord?  Presumably that won't work right
    #  under non-ASCII charsets.  Something should be done about that.
  }
  return @_;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
1;
__END__

=head1 NAME

TODO - TODO

=head1 SYNOPSIS

 TODO

  perl -MPod::Simple::HTML -e \
   "exit Pod::Simple::HTML->filter(shift)->any_errata_seen" \
   thingy.pod


=head1 DESCRIPTION

This class is for TODO.
This is a subclass of L<Pod::Simple::PullParser> and inherits all its
methods.

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


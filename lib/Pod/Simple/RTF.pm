
require 5;
package Pod::Simple::RTF;

#use utf8;

#sub DEBUG () {4};
#sub Pod::Simple::DEBUG () {4};
#sub Pod::Simple::PullParser::DEBUG () {4};

use strict;
use vars qw($VERSION @ISA %Escape $WRAP %Tagmap);
$VERSION = '1.01';
use Pod::Simple::PullParser ();
BEGIN {@ISA = ('Pod::Simple::PullParser')}

use Carp ();
BEGIN { *DEBUG = \&Pod::Simple::DEBUG unless defined &DEBUG }

$WRAP = 1 unless defined $WRAP;


# TODO:  use the if-foreign code from SMB::Pod::Tree::RTF

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _openclose {
 return map {;
   m/^([-A-Za-z]+)=(\w[^\=]*)$/s or die "what's <$_>?";
   ( $1,  "{\\$2\n",   "/$1",  "}" );
 } @_;
}

my @_to_accept;

%Tagmap = (
 # 'foo=bar' means ('foo' => '{\bar'."\n", '/foo' => '}')
 _openclose(
  'B=cs18\b',
  'I=cs16\i',
  'C=cs19\f1\lang1024\noproof',
  'F=cs17\i\lang1024\noproof',
 
  map {; m/^([-a-z]+)/s && push @_to_accept, $1; $_ }
   qw[
       underline=ul         smallcaps=scaps  shadow=shad
       superscript=super    subscript=sub    strikethrough=strike
       outline=outl         emboss=embo      engrave=impr   
       dotted-underline=uld          dash-underline=uldash
       dot-dash-underline=uldashd    dot-dot-dash-underline=uldashdd     
       double-underline=uldb         thick-underline=ulth
       word-underline=ulw            wave-underline=ulwave
   ]
   # But no double-strikethrough, because MSWord can't agree with the
   #  RTF spec on whether it's supposed to be \strikedl or \striked1 (!!!)
 ),

 # Bit of a hack here:
 'L=pod' => '{\cs22\i'."\n",
 'L=url' => '{\cs23\i'."\n",
 'L=man' => '{\cs24\i'."\n",
 '/L' => '}',

 'Data'  => "\n",
 '/Data' => "\n",

 'Verbatim'  => "\n{\\pard\\li#rtfindent##rtfkeep#\\plain\\s20\\sa180\\f1\\fs18\\lang1024\\noproof\n",
 '/Verbatim' => "\n\\par}\n",
 'Para'    => "\n{\\pard\\li#rtfindent#\\sa180\n",
 '/Para'   => "\n\\par}\n",
 'head1'   => "\n{\\pard\\li#rtfindent#\\s31\\keepn\\sb90\\sa180\\f2\\fs#head1_halfpoint_size#\\ul{\n",
 '/head1'  => "\n}\\par}\n",
 'head2'   => "\n{\\pard\\li#rtfindent#\\s32\\keepn\\sb90\\sa180\\f2\\fs#head2_halfpoint_size#\\ul{\n",
 '/head2'  => "\n}\\par}\n",
 'head3'   => "\n{\\pard\\li#rtfindent#\\s33\\keepn\\sb90\\sa180\\f2\\fs#head3_halfpoint_size#\\ul{\n",
 '/head3'  => "\n}\\par}\n",
 'head4'   => "\n{\\pard\\li#rtfindent#\\s34\\keepn\\sb90\\sa180\\f2\\fs#head4_halfpoint_size#\\ul{\n",
 '/head4'  => "\n}\\par}\n",
   # wordpad borks on \tc\tcl1, or I'd put that in =head1 and =head2

 'item-bullet'  => "\n{\\pard\\li#rtfindent##rtfitemkeepn#\\sb60\\sa150\\fi-120\n",
 '/item-bullet' => "\n\\par}\n",
 'item-number'  => "\n{\\pard\\li#rtfindent##rtfitemkeepn#\\sb60\\sa150\\fi-120\n",
 '/item-number' => "\n\\par}\n",
 'item-text'    => "\n{\\pard\\li#rtfindent##rtfitemkeepn#\\sb60\\sa150\\fi-120\n",
 '/item-text'   => "\n\\par}\n",

 # we don't need any styles for over-* and /over-*
);


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub new {
  my $new = shift->SUPER::new(@_);
  $new->nix_X_codes(1);
  $new->nbsp_for_S(1);
  $new->accept_targets( 'rtf', 'RTF' );

  $new->{'Tagmap'} = {%Tagmap};

  $new->accept_codes(@_to_accept);
  DEBUG > 2 and print "To accept: ", join(' ',@_to_accept), "\n";

  $new->head1_halfpoint_size(32);
  $new->head2_halfpoint_size(28);
  $new->head3_halfpoint_size(25);
  $new->head4_halfpoint_size(22);
  $new->codeblock_halfpoint_size(18);
  $new->header_halfpoint_size(20);
  $new->normal_halfpoint_size(22);

  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# TODO: document these

__PACKAGE__->_accessorize(
 'head1_halfpoint_size',
 'head2_halfpoint_size',
 'head3_halfpoint_size',
 'head4_halfpoint_size',
 'codeblock_halfpoint_size',
 'header_halfpoint_size',
 'normal_halfpoint_size',
 'no_proofing_exemptions',
);


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub run {
  my $self = $_[0];
  return $self->do_middle if $self->bare_output;
  return
   $self->do_beginning && $self->do_middle && $self->do_end;
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub do_middle {      # the main work
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  
  my($token, $type, $tagname, $scratch);
  my @stack;
  my @indent_stack;
  $self->{'rtfindent'} = 0 unless defined $self->{'rtfindent'};
  
  while($token = $self->get_token) {
  
    if( ($type = $token->type) eq 'text' ) {
      if( $self->{'rtfverbatim'} ) {
        DEBUG > 1 and print "  $type " , $token->text, " in verbatim!\n";
        rtf_esc_codely($scratch = $token->text);
        print $fh $scratch;
        next;
      }

      DEBUG > 1 and print "  $type " , $token->text, "\n";
      
      $scratch = $token->text;
      $scratch =~ tr/\t\cb\cc/ /d; # and turn tabs to spaces while we're at it
      
      $self->{'no_proofing_exemptions'} or $scratch =~
       s/(?:
           ^
           |
           (?<=[\cm\cj\t "\[\<\(])
         )   # start on whitespace, sequence-start, or quote
         ( # something looking like a Perl token:
          (?:
           [\$\@\:\<\*\\_]\S+  # either starting with a sigil, etc.
          )
          |
          # or starting alpha, but containing anything strange:
          (?:
           [a-zA-Z'\x80-\xFF]+[\$\@\:_<>\(\\\*]\S+
          )
         )
        /\cb$1\cc/xsg
      ;
      
      rtf_esc($scratch);
      $scratch =~
         s/(
            [^\cm\cj\n]{65}        # Snare 65 characters from a line
            [^\cm\cj\n\x20]{0,50}  #  and finish any current word
           )
           (\x20{1,10})(?![\cm\cj\n]) # capture some spaces not at line-end
          /$1\n$2/gx     # and put a NL before those spaces
        if $WRAP;
        # This may wrap at well past the 65th column, but not past the 120th.
      
      print $fh $scratch;

    } elsif( $type eq 'start' ) {
      DEBUG > 1 and print "  +$type ",$token->tagname,
        " (", map("<$_> ", %{$token->attr_hash}), ")\n";

      if( ($tagname = $token->tagname) eq 'Verbatim' ) {
        ++$self->{'rtfverbatim'};
        my $next = $self->get_token;
        next unless defined $next;
        my $line_count = 1;
        if($next->type eq 'text') {
          my $t = $next->text_r;
          while( $$t =~ m/$/mg ) {
            last if  ++$line_count  > 15; # no point in counting further
          }
          DEBUG > 3 and print "    verbatim line count: $line_count\n";
        }
        $self->unget_token($next);
        $self->{'rtfkeep'} = ($line_count > 15) ? '' : '\keepn' ;     

      } elsif( $tagname =~ m/^item-/s ) {
        my @to_unget;
        my $text_count_here = 0;
        $self->{'rtfitemkeepn'} = '';
        # Some heuristics to stop item-*'s functioning as subheadings
        #  from getting split from the things they're subheadings for.
        #
        # It's not terribly pretty, but it really does make things pretty.
        #
        while(1) {
          push @to_unget, $self->get_token;
          unshift(@to_unget), last unless defined $to_unget[-1];
          if($to_unget[-1]->type eq 'text') {
            if( ($text_count_here += length ${$to_unget[-1]->text_r}) > 150 ){
              DEBUG > 1 and print "    item-* is too long to be keepn'd.\n";
              last;
            }
          } elsif (@to_unget > 1 and
            $to_unget[-2]->type eq 'end' and
            $to_unget[-2]->tagname =~ m/^item-/s
          ) {
            # Bail out here, after setting rtfitemkeepn yea or nay.
            $self->{'rtfitemkeepn'} = '\keepn' if 
              $to_unget[-1]->type eq 'start' and
              $to_unget[-1]->tagname eq 'Para';

            DEBUG > 1 and printf "    item-* before %s(%s) %s keepn'd.\n",
              $to_unget[-1]->type,
              $to_unget[-1]->can('tagname') ? $to_unget[-1]->tagname : '',
              $self->{'rtfitemkeepn'} ? "gets" : "doesn't get";
            last;
          } elsif (@to_unget > 40) {
            DEBUG > 1 and print "    item-* now has too many tokens (",
              scalar(@to_unget),
              (DEBUG > 4) ? (q<: >, map($_->dump, @to_unget)) : (),
              ") to be keepn'd.\n";
            last; # give up
          }
          # else keep while'ing along
        }
        # Now put it aaaaall back...
        $self->unget_token(@to_unget);

      } elsif( $tagname =~ m/^over-/s ) {
        push @stack, $1;
        push @indent_stack,
         int($token->attr('indent') * 4 * $self->normal_halfpoint_size);
        DEBUG and print "Indenting over $indent_stack[-1] twips.\n";
        $self->{'rtfindent'} += $indent_stack[-1];
        
      } elsif ($tagname eq 'L') {
        $tagname .= '=' . ($token->attr('type') || 'pod');
        
      } elsif ($tagname eq 'Data') {
        my $next = $self->get_token;
        next unless defined $next;
        unless( $next->type eq 'text' ) {
          $self->unget_token($next);
          next;
        }
        DEBUG and print "    raw text ", $next->text, "\n";
        printf $fh "\n" . $next->text . "\n";
        next;
      }

      defined($scratch = $self->{'Tagmap'}{$tagname}) or next;
      $scratch =~ s/\#([^\#]+)\#/${$self}{$1}/g; # interpolate
      print $fh $scratch;
      
      if ($tagname eq 'item-number') {
        print $fh $token->attr('number'), ". \n";
      } elsif ($tagname eq 'item-bullet') {
        print $fh "\\'95 \n";
        #for funky testing: print $fh '', rtf_esc("\x{4E4B}\x{9053}");
      }

    } elsif( $type eq 'end' ) {
      DEBUG > 1 and print "  -$type ",$token->tagname,"\n";
      if( ($tagname = $token->tagname) =~ m/^over-/s ) {
        DEBUG and print "Indenting back $indent_stack[-1] twips.\n";
        $self->{'rtfindent'} -= pop @indent_stack;
        pop @stack;
      } elsif( $tagname eq 'Verbatim' ) {
        --$self->{'rtfverbatim'};
      }
      defined($scratch = $self->{'Tagmap'}{"/$tagname"}) or next;
      $scratch =~ s/\#([^\#]+)\#/${$self}{$1}/g; # interpolate
      print $fh $scratch;
    }
  }
  return 1;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
sub do_beginning {
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  return print $fh join '',
    $self->doc_init,
    $self->font_table,
    $self->stylesheet,
    $self->color_table,
    $self->doc_info,
    $self->doc_start,
    "\n"
  ;
}

sub do_end {
  my $self = $_[0];
  my $fh = $self->{'output_fh'};
  return print $fh '}'; # that should do it
}

###########################################################################

sub stylesheet {
  return sprintf <<'END',
{\stylesheet
{\snext0 Normal;}
{\*\cs10 \additive Default Paragraph Font;}
{\*\cs16 \additive \i \sbasedon10 pod-I;}
{\*\cs17 \additive \i\lang1024\noproof \sbasedon10 pod-F;}
{\*\cs18 \additive \b \sbasedon10 pod-B;}
{\*\cs19 \additive \f1\lang1024\noproof\sbasedon10 pod-C;}
{\s20\ql \li0\ri0\sa180\widctlpar\f1\fs%s\lang1024\noproof\sbasedon0 \snext0 pod-codeblock;}
{\*\cs21 \additive \lang1024\noproof \sbasedon10 pod-computerese;}
{\*\cs22 \additive \i\lang1024\noproof\sbasedon10 pod-L-pod;}
{\*\cs23 \additive \i\lang1024\noproof\sbasedon10 pod-L-url;}
{\*\cs24 \additive \i\lang1024\noproof\sbasedon10 pod-L-man;}

{\s31\ql \keepn\sb90\sa180\f2\fs%s\ul\sbasedon0 \snext0 pod-head1;}
{\s32\ql \keepn\sb90\sa180\f2\fs%s\ul\sbasedon0 \snext0 pod-head2;}
{\s33\ql \keepn\sb90\sa180\f2\fs%s\ul\sbasedon0 \snext0 pod-head3;}
{\s34\ql \keepn\sb90\sa180\f2\fs%s\ul\sbasedon0 \snext0 pod-head4;}
}

END

   $_[0]->codeblock_halfpoint_size(),
   $_[0]->head1_halfpoint_size(),
   $_[0]->head2_halfpoint_size(),
   $_[0]->head3_halfpoint_size(),
   $_[0]->head4_halfpoint_size(),
  ;
}

###########################################################################
# Override these as necessary for further customization

sub font_table {
  # 

  return <<'END';  # text font, code font, heading font
{\fonttbl
{\f0\froman Georgia;}
{\f1\fmodern Courier New;}
{\f2\fswiss Verdana;}
}

END
}

sub doc_init {
   return <<'END';
{\rtf1\ansi\deff0

END
}

sub color_table {
   return <<'END';
{\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
END
}


sub doc_info {
   my $self = $_[0];
   return sprintf <<'END',
{\info{\doccomm generated by %s v%s using %s v%s under
 Perl v%s at %s GMT}
{\author [see doc]}{\company [see doc]}{\operator [see doc]}
}

END

  # None of the following things should need escaping, I dare say!
  ref($self), $self->VERSION(), $ISA[0], $ISA[0]->VERSION(),
  $], scalar(gmtime),
  ;
}

sub doc_start {
  my $self = $_[0];
  my $title = $self->get_short_title();
  DEBUG and print "Short Title: <$title>\n";
  $title .= ' ' if length $title;
  
  $title =~ s/ *$/ /s; $title =~ s/^ //s;
   # make sure it ends in a space, unless it's 0-length

  my $is_obviously_module_name;
  $is_obviously_module_name = 1
   if $title =~ m/^\S+$/s and $title =~ m/::/s;
    # catches the most common case, at least

  DEBUG and print "Title0: <$title>\n";
  $title = rtf_esc($title);
  DEBUG and print "Title1: <$title>\n";
  $title = '\lang1024\noproof ' . $title
   if $is_obviously_module_name;

  return sprintf <<'END', 
\deflang1033\widowctrl
{\header\pard\qr\plain\f0\fs%s
%s
p.\chpgn\par}
\fs%s

END

    $self->header_halfpoint_size,
    $title,
    $self->normal_halfpoint_size,
  ;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#-------------------------------------------------------------------------

# TODO: escaping Unicode characters?
use integer;
sub rtf_esc {
  my $x; # scratch
  if(!defined wantarray) { # void context: alter in-place!
    for(@_) {
      s/([F\x00-\x1F\-\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
      s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
    }
    return;
  } elsif(wantarray) {  # return an array
    return map {; ($x = $_) =~
      s/([F\x00-\x1F\-\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
      $x =~ s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
      $x;
    } @_;
  } else { # return a single scalar
    ($x = ((@_ == 1) ? $_[0] : join '', @_)
    ) =~ s/([F\x00-\x1F\-\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
             # Escape \, {, }, -, control chars, and 7f-ff.
    $x =~ s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
    return $x;
  }
}

sub rtf_esc_codely {
  # Doesn't change "-" to hard-hyphen, nor apply computerese style
  
  my $x; # scratch
  if(!defined wantarray) { # void context: alter in-place!
    for(@_) {
      s/([F\x00-\x1F\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
      s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
    }
    return;
  } elsif(wantarray) {  # return an array
    return map {; ($x = $_) =~
      s/([F\x00-\x1F\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
      $x =~ s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
      $x;
    } @_;
  } else { # return a single scalar
    ($x = ((@_ == 1) ? $_[0] : join '', @_)
    ) =~ s/([F\x00-\x1F\\\{\}\x7F-\xFF])/$Escape{$1}/g;  # ESCAPER
             # Escape \, {, }, -, control chars, and 7f-ff.
    $x =~ s/([^\x00-\xFF])/'\\uc1\\u'.((ord($1)<32768)?ord($1):(ord($1)-65536)).'?'/eg;
    return $x;
  }
}

%Escape = (
  map( (chr($_),chr($_)),       # things not apparently needing escaping
       0x20 .. 0x7E ),
  map( (chr($_),sprintf("\\'%02x", $_)),    # apparently escapeworthy things
       0x00 .. 0x1F, 0x5c, 0x7b, 0x7d, 0x7f .. 0xFF, 0x46),

  # We get to escape out 'F' so that we can send RTF files thru the mail
  # without the slightest worry that paragraphs beginning with "From"
  # will get munged.

  # And some refinements:
  #"\n"   => "\n\\line ",
  #"\cm"  => "\n\\line ",
  #"\cj"  => "\n\\line ",

  "\t"   => "\\tab ",     # Tabs (altho theoretically raw \t's are okay)
  "\f"   => "\n\\page\n", # Formfeed
  "-"    => "\\_",        # Turn plaintext '-' into a non-breaking hyphen
  "\xA0" => "\\~",        # Latin-1 non-breaking space
  "\xAD" => "\\-",        # Latin-1 soft (optional) hyphen

  # CRAZY HACKS:
  "\n" => "\\line\n",
  "\r" => "\n",
  "\cb" => "{\n\\cs21\\lang1024\\noproof ",  # \\cf1
  "\cc" => "}",
);

__END__

How do do a comment in rtf

{\*\qqqqqqqq
    I like cookies!!!!!
}

From the spec:

Destinations added after the RTF Specification published in the March
1987 Microsoft Systems Journal may be preceded by the control symbol \*.
This control symbol identifies destinations whose related text should be
ignored if the RTF reader does not recognize the destination.
[...]
If the \* control symbol precedes a control word, then it defines a
destination group and was itself preceded by an opening brace ({). The
RTF reader should discard all text up to and including the closing brace
(}) that closes this group.



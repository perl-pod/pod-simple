package Pod::Simple::YAML;
#
# Simple YAML parser enough to parse =for image properties.
#
use strict;
use warnings;
use Carp ();
use vars qw($VERSION );
$VERSION = '3.40';

sub new
{
  my $class = shift;
  my %opt = (
    line          => 1,
    array_allowed => 0,
    level         => 0,
    spaces        => undef,
    running       => 1,
    @_,
    offset        => '',
  );
  bless \%opt, $class;
}

sub check
{
  my $self = shift->new( array_allowed => 1 );
  open my $fh, "<", $_[0] or die "Cannot open $_[0]:$!";
  local $/;
  my $c = <$fh>;
  close $fh;
  my $ok = $self->parse($c);
  print "** Warning: $_->[1] at line $_->[0]\n" for $self->warnings;
  if ( $ok ) {
    require Data::Dumper;
    print Data::Dumper::Dumper($ok);
  } else {
    print "Error: ", $self->error, " on line ", $self->line, "\n";
    my $pos = pos($c);
    my @l = split "(\n)", $c;
    my $c = $l[($self->line - 1) * 2];
    if ( defined $c ) {
      print $c, "\n";
      for ( my $i = 1; $i < $self->line; $i++) {
        $pos -= length($l[$i*2-2] . $l[$i*2-1]);
      }
      print ' ' x $pos if ($pos || 0) > 0;
      print "^\n";
    }
  }
}

sub error    { $_[0]->{error} }
sub line     { $_[0]->{line} }
sub warnings { @{ $_[0]->{warnings} || [] } }

sub raise
{
  my ( $self, $error ) = @_;
  $self->{error} = $error;
  print STDERR Carp::longmess($error) if $ENV{POD_SIMPLE_YAML_DEBUG};
  return undef;
}

sub raise_warning
{
  my ( $self, $warning ) = @_;
  $self->{warnings} ||= [];
  push @{$self->{warnings}}, [ $self->{line}, $warning ];
}

our $SPACE     = qr/[ \t]/;
our $INDENTING = qr/\x{20}/;
our $URI_CHAR  = qr/[\!\w\%\;\/\?\:\@\&\=\+\$\,\_\.\~\*\'\(\)\[\]]/;

sub regex_spaces
{
  my ( $self, $at_least ) = @_;
  my $sp = $_[0]->{spaces}->[-1];
  $sp++ if $at_least || $sp < 0;
  return $at_least ? 
  	qr/$INDENTING {$sp,}/x :
	qr/$INDENTING {$sp} /x;
}

sub expect_newline
{
  my ($self, $t) = @_;
  return $self->raise('newline expected') unless $$t =~ m/\G(\n|$)/gcs;
  $self->{line}++;
  return 1;
}

sub expect_inline_closing
{
  my ($self, $t) = @_;
  return $self->raise('newline expected')
    unless $$t =~ m/\G$SPACE*(#[^\n]*)?(\n|$)/gcs;
  $self->{line}++;
  return 1;
}

sub skip_whitespace_and_comments
{
  my ($self, $t) = @_;
  my $indent;
  while ( 1 ) {
    $$t =~ m/\G($SPACE*)\#([^\n]*)/gcs and do {
      return $self->raise('space missing before #') unless length $1;
      redo;
    };
    $$t =~ m/\G($INDENTING+)/gcs and do {
      $indent = length($1);
      redo;
    };
    $$t =~ m/\G($SPACE+)/gcs and redo;
    $$t =~ m/\G\n/gcs and do {
      $self->{line}++;
      $indent = 0;
      redo;
    };
    $$t =~ m/\G$/gcs and $indent = undef;
    return 1;
  }
}

sub expect_str
{
  my ($self, $str, $t) = @_;
  if ( $$t =~ m/\G($str)/gcs ) {
    return $1;
  } else {
    return $self->raise("'$str' expected");
  }
}

sub expect_scalar
{
  my ($self, $want_multiline, $t, $allowed) = @_;
  my $mid    = qr/[^\n\'\"\[\]\{\}\,\:\?]/;
  my $midns  = qr/[^\n\'\"\[\]\{\}\,\:\?\s]/;
  my $start  = qr/[\:\?]/;
  my $mid2   = qr/[\?]/;
  my $qr     = $allowed ? qr/(?:$midns|$allowed)/ : $midns;
  my $qr2    = $allowed ? qr/(?:$mid|$allowed)/   : $mid;
  my $scalar = qr/(?:$qr|$start+$midns)(?:$qr2|$mid2|\:$midns)*/;
  if ( $$t =~ m/\G($scalar)/gcs ) {
    my $v = $1;
    $v =~ s/(^|\s)#.*$//;
    $v =~ s/^\s*//;
    $v =~ s/\s*$//;
    $v =~ s/^\!\S*\s?//;

    if ( $want_multiline ) {
      # could this be .. a plain multiline scalar ?
      my $pos = pos($$t);
      my $newline = $$t =~ m/\G\n/gcs;
      if ( $newline ) {
        $self->{line}++;
        while ( 1 ) {
          last unless $$t =~ m/\G$SPACE*($scalar)/gcs;
          $v .= " $1";
          last unless $$t =~ m/\G\n/gcs;
          $self->{line}++;
        }
      } else {
        pos($$t) = $pos;
      }
    }
    return $v;
  }

  return $self-> parse_single_quoting(undef,$t) if $$t =~ m/\G'/gcs;
  return $self-> parse_double_quoting(undef,$t) if $$t =~ m/\G"/gcs;
  return $self-> parse_inline_array($t) if $$t =~ m/\G\[/gcs;
  return $self-> parse_inline_hash($t)  if $$t =~ m/\G\{/gcs;

  $$t =~ m/\G\*/gc and return $self->raise("aliases are not supported");
  $$t =~ m/\G\?/gc and return $self->raise("explicit keys are not supported");
  $$t =~ m/\G\&/gc and return $self->raise("anchors are not supported");

  return $self-> raise('unrecognized scalar');
}

sub parse_plain_multiline
{
  my ( $self, $spaces, $t ) = @_;
  my $ret = '';
  my $add_space = 1;
  while ( 1 ) {
    # extra spaces are ignored
    my $v;
    if ( $$t =~ m/\G$spaces(?:$SPACE*)(.*)/gc ) {
      $v = $1;
      if ($ret eq '' && $v =~ /^\s*(\#.*)$/) {
        # no payload is defined yet? so no rules about # in multiline
        # but spaces could be wrong then, too
        $spaces = $self->regex_spaces(1);
        return unless $self->expect_newline($t);
        next;
      }
    } else {
      return $ret;
    }

    return $self-> raise("multiline [$v] cannot contain : or # characters")
      if $v =~ /\:$SPACE|$SPACE\#/;

    $ret .= ' ' if length($v) && $add_space;
    $add_space = 1;
    $ret .= $v;
    $ret .= "\n", $add_space = 0 unless length($v);
    return unless $self->expect_newline($t);
  }
}

sub parse_block_scalar
{
  my ( $self, $style, $chomping, $indent, $t ) = @_;

  # end
  return '' if length($$t) == pos($$t);
  return unless $self->expect_newline($t);

  my @ret;
  $indent     = undef unless length $indent;
  my $nspaces = $indent;
  my $spaces  = defined($nspaces) ? (' ' x $nspaces) : $self->regex_spaces(1);
  while ( 1 ) {
    if ( !defined($nspaces)) {
      if ($$t =~ m/\G($spaces)([^\n]*)(\n|$)/gcs) {
        $self->{line}++;
        push @ret, $2;
        if ( length $2 ) {
          $nspaces = length($1);
          $spaces  = ' ' x $nspaces;
        }
      } else {
        last;
      }
    } elsif ( $$t =~ m/\G$spaces([^\n]*)(\n|$)/gcs) {
      push @ret, $1;
      $self->{line}++;
    } elsif ( $$t =~ m/\G$INDENTING+(\n|$)/gcs) {
      push @ret, '';
      $self->{line}++;
    } else {
      last;
    }
    return $self->raise("invalid reserve character '$1'")
      if 1 == @ret && $ret[0] =~ m/^([\@\`])/;
  }

  my @tail;
  while ( @ret && !length($ret[-1])) {
    unshift @tail, pop @ret;
  }

  my $ret;
  if ( $style eq '|') {
    $ret = join("\n", @ret);
  } else {
    $ret = '';
    my $add_space = 0;
    for ( my $i = 0; $i < $#ret; $i++) {
      my $v = $ret[$i];
      if ( length $v ) {
        $ret .= ' ' if $add_space;
        $ret .= $v;
        $add_space = 1;
      } else {
        $ret .= "\n";
        $add_space = 0;
      }
    }
    $ret .= ' ' if $add_space;
    $ret .= $ret[-1] if @ret;
  }

  if ( $chomping eq '') {
    $ret .= "\n" if length $ret;
  } elsif ( $chomping eq '+') {
    $ret .= "\n" x (1 + @tail);
  }

  return $ret;
}

sub parse_quoted_multiline
{
  my ( $self, $quote, $indent, $t ) = @_;

  my $match = ($quote eq '"') ?
    qr/(?:\\[^\n]|[^"\n\\])+/ :
    qr/(?:\'\'|[^'\n])+/;

  my $ret = '';
  my $first_line  = 1;
  my $add_space   = 0;
  my $curr_indent = 0;
  while ( 1 ) {
    $first_line == 0 and $$t =~ m/\G($SPACE+)/gcs and do {
      $curr_indent = length $1;
      redo;
    };
    $$t =~ m/\G($match)/gcs and do {
      return $self->raise('inconsistent spacing')
        if defined($indent) and $first_line == 0 && $curr_indent < $indent;
      $ret .= ' ' if $add_space;
      $ret .= $1;
      $first_line = 0;
      redo;
    };
    $$t =~ m/\G\Q$quote\E/gcs and do {
      if ( $$t =~ m/\G($SPACE*)\#[^\n]*/gcs ) {
        return $self->raise('space missing before #') unless length $1;
      }
      last;
    };
    $$t =~ m/\G$/gcs and return $self->raise("trailing quote ($quote) required");
    $quote eq '"' and $$t =~ m/\G\\\n/gcs and do {
      $self->{line}++;
      $add_space = 0;
      $first_line = 0;
      $curr_indent = 0;
      redo;
    };
    $$t =~ m/\G((?:$SPACE*\n)+)/gcs and do {
      my $nl = $1;
      $nl =~ s/$SPACE+//gs;
      $nl = length $nl;
      $ret .= "\n" x ( $nl - 1 );
      $self->{line} += $nl;
      $add_space = ($nl == 1);
      $first_line = 0;
      $curr_indent = 0;
      redo;
    };
  }

  return $ret;
}

sub parse_single_quoting_scalar
{
  my ($self, $t) = @_;
  my $final = '';
  while ( 1 ) {
    $$t =~ m/\G([^']+)/gcs and do {
      $final .= $1;
      redo;
    };
    $$t =~ m/\G''/gcs and do {
      $final .= "'";
      redo;
    };
    $$t =~ m/\G$/gcs and return $final;
    return $self->raise("unquoted ' character");
  }
}

sub parse_single_quoting
{
  my ( $self, $spaces, $t ) = @_;

  my $ret = $self->parse_quoted_multiline("'", $spaces, $t);
  return unless defined $ret;
  return $self->parse_single_quoting_scalar(\$ret);
}

sub escape
{
  my ($self, $c) = @_;
  if ( $c =~ /^([\r\n]+)$/) {
    return $1;
  } elsif ( $c eq '0') {
    return "\0";
  } elsif ( $c eq 'a') {
    return "\a";
  } elsif ( $c eq 'b') {
    return "\b";
  } elsif ( $c eq 'e') {
    return "\x{1b}";
  } elsif ( $c eq 'f') {
    return "\f";
  } elsif ( $c eq 'n') {
    return "\n";
  } elsif ( $c eq 'r') {
    return "\r";
  } elsif ( $c eq 't') {
    return "\t";
  } elsif ( $c eq 'v') {
    return "\x{b}";
  } elsif ( $c =~ /^[ux](.*)$/i) {
    return chr(hex($1));
  } elsif ( $c eq '_') {
    return "\x{a0}";
  } elsif ( $c eq 'N') {
    return "\x{85}";
  } elsif ( $c eq 'L') {
    return "\x{2028}";
  } elsif ( $c eq 'P') {
    return "\x{2029}";
  } elsif ( $c =~ m/^[\\\/"]$/) {
    return $c;
  } else {
    $self->raise("character $c doesn't need to be quoted");
  }
}

sub parse_double_quoting_scalar
{
  my ($self, $t) = @_;
  my $final = '';
  while ( 1 ) {
    $$t =~ m/\G$/gcs and last;
    $$t =~ m/\G([^\\"]+)/gcs and do {
      $final .= $1;
      redo;
    };
    $$t =~ m/\G\\((?:
      \x{0d}\x{0a}|
      x[0-9a-fA-F]{2}|
      u[0-9a-fA-F]{4}|
      U[0-9a-fA-F]{8}|
      .
    ))/gcsx and do {
      my $char = $self->escape($1);
      return unless defined $char;
      $final .= $char;
      redo;
    };
    $$t =~ m/\G(.*)/gc and return $self->raise("unexpected input: '$1'");
  }
  return $final;
}

sub parse_double_quoting
{
  my ( $self, $spaces, $t ) = @_;

  my $ret = $self->parse_quoted_multiline('"', $spaces, $t);
  return unless defined $ret;
  return $self->parse_double_quoting_scalar(\$ret);
}

# Parses key: head (head can be empty)
#   plain multiline
#
# starting after 'key: '
#
# if end of input or end of scope is reached, returns data read
#
# 2. Looks ahead to check for whether there are any extra keys after -foo:42
# (when $set_continuation is 1)
sub parse_leaf
{
  my ( $self, $set_continuation, $parent_ref, $t ) = @_;

  my $head = '';
  $head = $1 if $$t =~ m/\G([^\n]+)/gcs;
  $head =~ s/(^|\s)\#.*$//;
  $head =~ s/$SPACE+$//;
  return $self->raise("invalid reserve character '$1'") if $head =~ m/^([\@\`])/;
  return $self->raise("anchors are not supported") if $head =~ m/^\&/;
  return $self->raise("aliases are not supported") if $head =~ m/^\*/;
  return $self->raise("aliases are not supported") if $head =~ m/^\*/;
  return $self->raise("value [$head] cannot contain : or # characters")
      if $head =~ /\:$SPACE|$SPACE\#/;
  my $pos = pos($$t);

  # end
  goto SINGLE_LINED if $$t =~ m/\G$/gcs;
  return unless $self->expect_newline($t);

  # hash or array
  $pos = pos($$t);
  my $set_continuation_detected;
  if ($$t =~ m/\G
    # empty lines and lines with comments only
    (?:
      $SPACE*
      (?:(?:^|$SPACE)\#[^\n]*)
      \n
    )*
    ($SPACE*)
    # payload
    (
      (?:- )?[^\n]*\:(?:$SPACE|\n|$) |
      -
    )
  /gcsx) {
    my $l = length $1;
    my $payload = $2;

    # same level? don't bother parsing
    if ($l == $self->{spaces}->[-1]) {
      if ( $parent_ref eq 'HASH' && $payload =~ /^-(\s|$)/ ) {
        # array inside a hash may start on the same offset
        $self->{level}++;
        pos($$t) = $pos;
        push @{$self->{spaces}}, ( $self->{spaces}->[-1] > -1 ) ? $self->{spaces}->[-1] - 1 : -1;
        my $parsed = $self->parse_do($parent_ref, $t);
        pop @{$self->{spaces}};
        $self->{level}--;
        return $parsed, 0;
      } else {
        goto SINGLE_LINED;
      }
    }

    # end of scope? also don't parse
    goto SINGLE_LINED
      if $self->{level} > 0 && $l < $self->{spaces}->[-1];

    # deeper level?
    if ($l > $self->{spaces}->[-1]) {
      if ($set_continuation) {
        $set_continuation_detected = 1;
        goto SINGLE_LINED;
      } elsif ( length $head ) {
        return $self->raise('cannot declare both immediate and deeper level data here');
      }

      $self->{level}++;
      pos($$t) = $pos;
      my $parsed = $self->parse_do($parent_ref, $t);
      $self->{level}--;
      return $parsed, 0;
    }

    return $self->raise( "unexpected number of spaces ($l)");
  }

  # multiline?
  my $spaces = $self->regex_spaces(1);
  pos($$t) = $pos;
  if ($$t =~ m/\G($spaces)/gcs) {
    my $multi_indent = $1;
    pos($$t) = $pos;
    if ( $head =~ /^$SPACE*$/) {
      # peek for other structures
      my $line = $self->{line};
      while ( 1 ) {
        $$t =~ m/\G$SPACE*\n/gcs and do {
          $self->{line}++;
          redo;
        };
        $$t =~ m/\G$SPACE+\#.*[^\n]/gcs and redo;
        $$t =~ m/\G$SPACE+/gcs;
        last;
      }
      if ( $$t =~ m/\G\'/gc) {
        return $self->parse_single_quoting($self->{spaces}->[-1] + 1, $t);
      } elsif ( $$t =~ m/\G"/gc) {
        return $self->parse_double_quoting($self->{spaces}->[-1] + 1, $t);
      } elsif ( $$t =~ m/\G\[/gc) {
        return $self->parse_inline_array($t);
      } elsif ( $$t =~ m/\G\{/gc) {
        return $self->parse_inline_hash($t);
      } else {
        pos($$t) = $pos;
        $self->{line} = $line;
      }
    }
    my $tail = $self->parse_plain_multiline($multi_indent, $t);
    return unless defined $tail;
    $tail =~ s/^\s// if $head =~ /^\s*$/;
    return $head . $tail, 0;
  } elsif ( $$t =~ m/\G($SPACE*\#[^\n]*)?(\n|$)/gcs) {
    pos($$t) = $pos;
    return $head, 0;
  }

  pos($$t) = $pos;
  $$t =~ m/\G($SPACE*)/s;
  my $l = length($1) || 0;
  return $self->raise(
    "badly formatted plain multiline scalar: expected ".
    (1+$self->{spaces}->[-1]) .
    " spaces, got $l"
  );

SINGLE_LINED:
  pos($$t) = $pos;
  if ( $set_continuation && !$set_continuation_detected ) {
    # also look-ahead for eventual set continuation
    my $spaces = $self->regex_spaces(0);
    $set_continuation_detected = $$t =~ m/\G$spaces(?!\- )[^\s\n]/gcs;
    pos($$t) = $pos;
  }
  return $head, $set_continuation_detected;
}

sub parse_type_null { '' }

sub parse_type_bool
{
  my ( $self, $value ) = @_;
  return 1 if $value =~ /^(True|TRUE|true)$/;
  return 0 if $value =~ /^(False|FALSE|false)$/;
  return $self->raise("invalid boolean value");
}

# constructs like {}#comment are invalid because space is missing before #
sub skip_comments_after_closing
{
  my ( $self, $t) = @_;
  return 1 unless $$t =~ /\G($SPACE*)\#[^\n]*/;
  return 1 if length $1;
  return $self->raise('space missing before #');
}

sub parse_inline_array
{
  my ($self, $t) = @_;
  my @ret;
  my $pos = pos($$t);
  while ( 1 ) {
    $self-> skip_whitespace_and_comments($t) or return;
    $$t =~ m/\G\]/gcs and last;

    my $scalar = $self->expect_scalar( 1, $t);
    return unless defined $scalar;
    push @ret, $scalar;

    $self-> skip_whitespace_and_comments($t) or return;
    my $match = $self->expect_str(qr/[,:\]]/, $t);
    return unless defined $match;
    last if $match eq ']';
    if ( $match eq ':') {
      $self-> skip_whitespace_and_comments($t) or return;
      my $value = $self->expect_scalar(1, $t);
      return unless defined $value;
      $ret[-1] = { $scalar, $value };
      $self-> skip_whitespace_and_comments($t) or return;

      $match = $self->expect_str(qr/[,\]]/, $t);
      return unless defined $match;
      last if $match eq ']';
    }
  }
  return unless $self-> skip_comments_after_closing($t);
  return \@ret;
}

sub parse_inline_hash
{
  my ($self, $t, $closed_by_array) = @_;
  my %ret;
  my $closer  = $closed_by_array ? qr/[,\]]/ : qr/[,\}]/;
  my $bracket = $closed_by_array ? qr/[\]]/ : qr/[\}]/;
  while ( 1 ) {
    $self-> skip_whitespace_and_comments($t) or return;
    $$t =~ m/\G\}/gcs and last;

    # this is only for trailing comma {1:2,}
    $closed_by_array  and $$t =~ m/\G\]/gcs and last;
    !$closed_by_array and $$t =~ m/\G\}/gcs and last;

    my $key = $self->expect_scalar( 1, $t);
    return unless defined $key;

    $self-> skip_whitespace_and_comments($t) or return;
    my $match = $self-> expect_str(qr/[:]|$closer/, $t);
    return unless defined $match;
    my $value;
    if ( $match eq ':') {
      $self-> skip_whitespace_and_comments($t) or return;
      if ( $$t =~ m/\G$bracket/gcs ) {
        $ret{$key} = ''; # null
        last;
      } else {
        $value = $self->expect_scalar( 0, $t, qr/[:]/ );
      }
      return unless defined $value;
      $self-> skip_whitespace_and_comments($t) or return;
      $match = $self-> expect_str(qr/$closer/, $t);
    } elsif ( $match =~ /$closer/ ) {
      $value = ''; # null
    }

    if ( exists $ret{$key}) {
      $self->raise_warning("found duplicate key '$key'");
    } else {
      $ret{$key} = $value;
    }
    return unless defined $match;
    last if $match =~ m/$bracket/;
  }
  return unless $self-> skip_comments_after_closing($t);
  return \%ret;
}

sub parse_tag
{
  my ( $self, $t ) = @_;

  if ( $$t =~ m/\G
    \s*
    (\!(?:
      $URI_CHAR+|   # !tag
      \<[^\>]*\>|   # !<tag>
      $SPACE        # !
    ))
    ($SPACE*)
  /gcsx) {
    my $xtag = $1;
    return "$1" if $xtag =~ /^!!(\w+)$/;
    return 1; # don't care about <tags>
  }
  return undef;
}

sub parse_dataentry
{
  my ( $self, $set_continuation, $parent_ref, $t ) = @_;
  my $value;
  my $set_continuation_detected;

  my $type = $self-> parse_tag($t);
  if ( $$t =~ m/\G([\&\*]\w+\s*)/gcs) {
    return $self->raise('anchors and aliases are not supported');
  }
  if ( $$t =~ m/\G([>|])([-\d+]*)(?:$SPACE*?)(?:($SPACE#.*)|(.+))?/gc) {
    return $self-> raise("unexpected input '$4' in block scalar definition")
      if defined($4) && length($4);
    my ( $style, $chomping_and_indent) = ( $1, $2 );
    my ( $chomping, $indent );
    if ( $chomping_and_indent =~ /^([-+]?)(\d*)$/) {
       ( $chomping, $indent ) = ($1, $2);
    } elsif ( $chomping_and_indent =~ /^(\d*)([-+]?)$/) {
       ( $chomping, $indent ) = ($2, $1);
    } else {
      return $self->raise("invalid chomp/input specification '$chomping_and_indent'");
    }
    $value = $self->parse_block_scalar($style, $chomping, $indent, $t);
  } elsif ( $$t =~ m/\G\'/gc) {
    $value = $self->parse_single_quoting($self->{spaces}->[-1] + 1, $t);
  } elsif ( $$t =~ m/\G"/gc) {
    $value = $self->parse_double_quoting($self->{spaces}->[-1] + 1, $t);
  } elsif ( $$t =~ m/\G\[/gc) {
    $value = $self->parse_inline_array($t);
    return unless defined $value;
    return unless $self-> expect_inline_closing($t);
  } elsif ( $$t =~ m/\G\{/gc) {
    $value = $self->parse_inline_hash($t);
    return unless defined $value;
    return unless $self-> expect_inline_closing($t);
  } else {
    ($value, $set_continuation_detected) = $self->parse_leaf($set_continuation, $parent_ref, $t);
    return unless defined $value;
    $value = '' if $value eq '~';
    if ( defined $type && (my $method = $self->can("parse_type_$type"))) {
      $value = $method->($self, $value);
    }
  }
  return unless defined $value;
  return $value, $set_continuation_detected;
}

sub parse_do
{
  my ($self, $parent_ref, $t) = @_;
  my $data       = undef;
  my $got_spaces = 0;
  my $spaces     = defined($self->{spaces}) ? $self-> regex_spaces(1) : qr/$INDENTING*/;
  my $key        = qr/
    "[^"\n]*"\s*|                # double-quoted
    '[^'\n]*'\s*|                # single-quoted
    (?:
      [^\n\s\{\[\&\?\*\'\"\-]|   # non-quoted head
      [\?\*\&\-][^\s\:]
    )
    (?:                          # non-quoted tail
      [^\n\#\:]|
      \:\S|
      (?<=\S)\#
    )*
  /x;

  while ( 1 ) {
    # empty lines
    $$t =~ m/\G$SPACE*\#[^\n]*/gc and redo;
    $$t =~ m/\G\%[^\n]*/gc and redo;

    # newline
    $$t =~ m/\G$SPACE*\n/gcs and do {
      $self->{line}++;
      redo;
    };

    # hash or set
    my $pos = pos($$t);
    $$t =~ m/\G($spaces)(\- )?($key)\:(?:$SPACE+|(?=\n)|$)/gc and do {
      unless ( $got_spaces ) {
        push @{$self->{spaces}}, length $1;
        $spaces = $self->regex_spaces(0);
        $got_spaces = 1;
      }
      my $is_set = $2;
      my $key    = $3;

      $key =~ s/\s+$//;
      if ( $key =~ /^(["'])(.*)$/) {
        my ($q, $k) = ($1, $2);
        $key = ($q eq '"') ?
          $self->parse_double_quoting(undef, \$k) :
          $self->parse_single_quoting(undef, \$k);
        return unless defined $key;
      }
      if ( my $tag = $self-> parse_tag(\$key) ) {
        substr($key, 0, pos($key)) = '';
      }

      if ( $is_set ) {
        return $self->raise("array is not allowed here")
          if $self->{level} == 0 && !$self->{array_allowed};
        return $self->raise("current definition is not a set") if defined($data) && ref($data) ne 'ARRAY';
        $data = [] unless defined $data;

        my ($value, $set_continuation_detected) = $self-> parse_dataentry(1, 'ARRAY', $t);
        my %set = ($key => $value);
        push @$data, \%set;
        return unless defined $value;

        if ( $set_continuation_detected ) {
          $self->{level}++;
          my $contd = $self->parse_do('ARRAY', $t);
          $self->{level}--;
          return unless defined $contd;
          return $self->raise("set returned not as a hash") if ref($contd) ne 'HASH';
          %set = ( %set, %$contd );
        }
      } else {
        if (defined($data) && ref($data) ne 'HASH') {
          if ( ref($data) eq 'ARRAY' && $parent_ref eq 'HASH') {
            # array that started on the same depth as its parent hash, ends here
            pos($$t) = $pos;
            goto ENDOSCOPE;
          } else {
            return $self->raise("current definition is not a hash");
          }
        }
        my ($value) = $self-> parse_dataentry(0, 'HASH', $t);
        return unless defined $value;
        $data = {} unless defined $data;
        if ( exists $data->{$key}) {
          $self->raise_warning("found duplicate key '$key'");
        } else {
          $data->{$key} = $value;
        }
      }
      redo;
    };
    $$t =~ m/\G\t*\{/gcs and do {
      $self->raise("unexpected flow hash") if $data;
      $data = $self->parse_inline_hash($t) or return;
      redo;
    };

    # arrays
    $$t =~ m/\G($spaces)\-($SPACE?)/gc and do {
      my $offset      = length $1;
      my $extra_space = length $2;
      return $self->raise("array is not allowed here")
        if $self->{level} == 0 && !$self->{array_allowed};
      return $self->raise("current definition is not an array")
        if defined($data) && ref($data) ne 'ARRAY';
      unless ( $got_spaces ) {
        push @{$self->{spaces}}, length $1;
        $spaces = $self->regex_spaces(0);
        $got_spaces = 1;
      }
      $data = [] unless defined $data;

      if ( $extra_space && $$t =~ m/\G\-$SPACE/gc ) {
        substr($$t, ($pos || 0) + $offset, 1, ' ');
        pos($$t) = $pos;
        $self->{level}++;
        my $value = $self-> parse_do('ARRAY', $t);
        $self->{level}--;
        return unless defined $value;
        push @$data, $value;
      } else {
        my ($value) = $self-> parse_dataentry(0, 'ARRAY', $t);
        return unless defined $value;
        push @$data, $value;
      }
      redo;
    };
    $$t =~ m/\G\t*\[/gcs and do {
      $self->raise("unexpected flow array") if $data;
      $data = $self->parse_inline_array($t) or return;
      redo;
    };

    ENDOSCOPE: # end of scope
    if ( $self->{level} > 0 ) {
      my $pos = pos($$t);
      if ( $$t =~ m/\G($SPACE*)/gc ) {
        my $l = length $1;
        pop @{ $self->{spaces} };
        my $m = $self->{spaces}->[-1] || 0;
        return $self->raise("inconsistent number of spaces ($l) when $m is expected")
          if $l > 0 && $l != $m;
        return $self->raise('end of scope without any data')
          unless defined $data;

        pos($$t) = $pos;
        return $data;
      }
    }

    pos($$t) = pos($$t); # double match on \G$ fails. Bug?
    $$t =~ m/\G$/gcs and do {
      pop @{ $self->{spaces} };
      return $self->raise('empty document') unless defined $data;
      return $data;
    };

    # anything else
    $$t =~ m/\G\*/gc and return $self->raise("aliases are not supported");
    $$t =~ m/\G\?/gc and return $self->raise("explicit keys are not supported");
    $$t =~ m/\G\&/gc and return $self->raise("anchors are not supported");
    $$t =~ m/\G\t/gc and return $self->raise("tabs may not be used for indentation");
    $$t =~ m/\G(.+)/gc and return $self->raise("unexpected input: '$1'");
  }
}

sub preparse
{
  my ( $self, $t) = @_;
  my $xline = $self->{line};
  my ($ct, $append, $start, $end) = ('', 1);
  while ( 1 ) {
    $t =~ m/\G\-\-\-$SPACE*(.*)(\n?)/gcm and do {
      return $self->raise("multiple yaml documents not supported")
        if length($ct) || $start;
      my $payload = $1;
      $payload =~ s/^!\S*\s*//;
      return $self->raise("invalid content after document start") if length $payload;
      $start = 1;
      $self->{line}++;
      $xline++;
      redo;
    };
    $t =~ m/\G\.\.\.(.*)/gcm and do {
      return $self->raise("multiple yaml documents not supported")
        if $end;
      return $self->raise("invalid content after end marker")
        if length $1;
      $end = 1;
      $append = 0;
      redo;
    };
    $t =~ m/\G$/gcs and last;
    $t =~ m/\G\s*([\#\%].*)(\n?)/gcm and do {
      if (!length($ct)) {
        $xline++ if length $2;
        redo;
      } elsif ( $1 =~ /^%/) {
        return $self->raise('unexpected % tag');
      }
    };
    $t =~ m/\G(.*)/gcm and $append and $ct .= $1;
    $t =~ m/\G\n/gcm and do {
      $ct .= "\n" if $append;
      $self->{line}++;
    };
  }
  $self->{line} = $xline;
  return $ct;
}

sub parse
{
  my ($self, $t) = @_;
  if ($t =~ /^[-.]{3}/m) {
    $t = $self->preparse($t);
    return unless defined $t;
  }
  return $self->parse_do('', \ $t);
}

1;

=pod

=encoding utf-8

=head1 NAME

Pod::Simple::YAML -- minimal YAML parser for the image tag

=head1 DESCRIPTION

Generic YAML parser based on YAML 1.2 spec is used to process content of C<=for
image> pod sections. These sections represent image properties such as
location, title, etc.

Only a subset of full YAML specification was implemented.  Specifically, the
following features are missing: tags, anchors, begin/end of document.

=head1 SYNOPSIS

  use Pod::Simple::YAML;
  my $yaml   = Pod::Simple::YAML->new;
  my $parsed = $yaml->parse($_[2]);
  die "error: ", $yaml-> error, " at line ", $yaml->line, "\n"
    unless defined $parsed;

or, from command line:

  perl -MPod::Simple::YAML -e 'Pod::Simple::YAML->check(shift)' file.yml

=head1 RATIONALE

The module implements a large part of YAML features, most notably structures of
arbitrary depth. Even though this is a clear overkill for the purposes of the
C<=for image> tag, it might not be so in the future; then, some document
containing such structures will throw an error when processed by an older
version of this module. The same is true for all other YAML features.

On the other hand, there was never a goal to implement the whole set of YAML
features. It is also rather a subjective decision where to draw a line, which
feature are to implement, and which not to, and why. So far this module strives
to provide a full set of YAML features regarding multiline and anonymous arrays
and hashes. Any other features (see below) are decidedly unimplemented to not
clutter the implementation.

Another goal is to make support of image tags not limited by perl parsers only.
The idea is to publish a minimal, but rather solid subset of YAML features,
and, most importantly, do not parse invalid YAML, so that pod parsers in other
languages could easily use their respective YAML libraries.

=head1 DIFFERENCES

The parser is different from the YAML specification in the following:

=over

=item *

Tags in form of C<%TAG> and C<!tagname> etc are unimplemented, but tolerated.
C<%YAML> and other C<%> tags are ignored, too

=item *

Anchors, aliases, and explicit keys are unimplemented, and throw an error.

=item *

The start of the document tag, C<--->, is not required, but recognized, and the
end of the document tag C<...> is recognized too. However these tags in the
text do not mean much for the parser, except that the input after C<...> is
discarded, and an attempt to start another document with C<---> thereafter
raises an error.

=item *

Types marked as C<!!type> are not recognized, but tolerated. Specifically,
binary format in form C<!!binary BASE64_TEXT> does not decode base64 (that
type is not in the default 1.2 Schema anymore anyway).

The only recognized types are C<!!bool> and C<!!null>, these treat their values
according to the spec.

=item *

Null values C<~> and empty string are resolved as empty string, not as
C<undef>.  This is done to not confuse formatters that might otherwise produce
undef warnings when parsing required properties.

Also, C<!!null null> will produce empty string as well.

=item *

Any top-level structure type but mapping (i.e. hash) is not supported and will
throw an error. Specifically, explicit typecasts to C<!!seq>, C<!!set>,
C<!!omap> will be ignored and will either not work or produce an error in the
top-level.

=back

=head1 API

=over

=item new %PROPERTIES

Creates a new YAML parser. The following properties are recognized:

=over

=item array_allowed = 0

If set, allows top-level arrays to be parsed.

=item line = 1

When set, line counter starts from this number

=back

=item parse TEXT

Parses the yaml text and returns the corresponding structure, if successful.
Otherwise returns undef.

=item error

After parsing was tried and was unsuccessful, returns the parsing error

=item warnings

Returns collected warnings

=item line

After parsing was tried and was unsuccessful, returns the line number where the error occured

=back

=head1 DEVELOPMENT

F<xt/yaml-test-suite.t> tests the parser against the YAML test suite from
L<https://github.com/yaml/yaml-test-suite.git>. Use it when extending the parser.

=head1 THANKS

Sawyer X
Karen Etheridge
Russ Allbery
Karl Williamson
Tina Müller

=head1 AUTHOR

Dmitry Karasik C<dmitry@karasik.eu.org>

=cut

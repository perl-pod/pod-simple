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
    @_,
    step          => undef,
    offset        => '',
  );
  bless \%opt, $class;
}

sub check
{
  my $self = shift->new;
  open my $fh, "<", $_[0] or die "Cannot open $_[0]:$!";
  local $/;
  my $c = <$fh>;
  close $fh;
  my $ok = $self->parse($c);
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
      print ' ' x $pos if $pos > 0;
      print "^\n";
    }
  }
}

sub error { $_[0]->{error} }
sub line  { $_[0]->{line} }

sub raise
{
  my ( $self, $error ) = @_;
  $self->{error} = $error;
  print STDERR Carp::longmess($error) if $ENV{POD_SIMPLE_YAML_DEBUG};
  return undef;
}

sub expect_newline
{
  my ($self, $t) = @_;
  return $self->raise('newline expected') unless $$t =~ m/\G(\n|$)/gcs;
  $self->{line}++;
  return 1;
}

sub expect_str
{
  my ($self, $str, $t) = @_;
  return $self->raise("'$str' expected") unless $$t =~ m/\G$str/gcs;
  return 1;
}

sub expect_scalar
{
  my ($self, $t) = @_;
  $$t =~ m/\G(\w+)/gcs and return $1;
  return $self-> parse_single_quoting_scalar(0,$t) if $$t =~ m/\G'/gcs;
  return $self-> parse_double_quoting_scalar(0,$t) if $$t =~ m/\G"/gcs;
  return $self-> parse_inline_array($t) if $$t =~ m/\G\[/gcs;
  return $self-> parse_inline_hash($t)  if $$t =~ m/\G\{/gcs;
  return $self-> raise('unrecognized scalar');
}

sub parse_plain_multiline
{
  my ( $self, $spaces, $t ) = @_;
  my $ret = '';
  while ( 1 ) {
    # extra spaces are ignored
    my $v;
    if ( defined($spaces) && $$t =~ m/\G$spaces\x{20}*(.*)/gc ) {
      $v = $1;
    } elsif ( !defined($spaces) && $$t =~ m/\G(\x{20}+)(.*)/gc ) {
      $v = $2;
      $self->{step} = length($1);
      $spaces = ' ' x $self->{step};
    } else {
      return $ret;
    }

    return $self-> raise("multiline cannot contain : or # characters")
      if $v =~ /[:#]/;

    $ret .= $v;
    $ret .= "\n" unless length($v);
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
  my $nspaces = defined($indent) ? $indent : $self->{step};
  my $spaces  = defined($nspaces) ? (' ' x $nspaces) : undef;
  while ( 1 ) {
    if ( !defined($nspaces)) {
      if ($$t =~ m/\G(\x{20}+)([^\n]*)(\n|$)/gcs) {
        $nspaces = length($1);
        push @ret, $2;
        $spaces  = ' ' x $nspaces;
        $self->{line}++;
      } else {
        last;
      }
    } elsif ( $$t =~ m/\G$spaces([^\n]*)(\n|$)/gcs) {
      push @ret, $1;
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

  my $ret = ( $style eq '|') ?
    join("\n", @ret) :
    join('', map { length($_) ? $_ : "\n" } @ret);

  if ( $chomping eq '') {
    $ret .= "\n";
  } elsif ( $chomping eq '+') {
    $ret .= "\n" x @tail;
  }

  return $ret;
}

sub parse_quoted_multiline
{
  my ( $self, $head, $quote, $t ) = @_;

  # end
  my $ret = $head;
  return $ret if length($$t) == pos($$t);
  return unless $self->expect_newline($t);

  my $spaces = defined($self->{step}) ? (' ' x $self->{step}) : undef;
  while ( 1 ) {
    # leading whitespace is ignored -- spec
    if ( defined($spaces) && $$t =~ m/\G$spaces\x{20}*([^\n]*)/gcs) { 
      $ret .= "\n" if $1 eq $quote;
      $ret .= $1;
      $ret .= "\n" if $1 eq '';
      return unless $self->expect_newline($t);
    } elsif ( !defined($spaces) && $$t =~ m/\G(\x{20}+)([^\n]*)/gcs) {
      $self->{step} = length $1;
      $ret .= "\n" if $2 eq $quote;
      $ret .= $2;
      $ret .= "\n" if $2 eq '';
      return unless $self->expect_newline($t);
      $spaces = ' ' x $self->{step};
    } else {
      last;
    }
  }

  $ret =~ s/\s*(#.*)?$//;

  return $ret;
}

sub parse_single_quoting_scalar
{
  my ($self, $check_eol, $t) = @_;
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
    if ( $check_eol ) {
      $$t =~ m/\G'$/gcs and return $final;
    } else {
      $$t =~ m/\G'/gcs and return $final;
    }
    return $self->raise("Unquoted ' character");
  }
}

sub parse_single_quoting
{
  my ( $self, $head, $t ) = @_;

  my $ret = $self->parse_quoted_multiline($head, "'", $t);
  return unless defined $ret;
  return $self->parse_single_quoting_scalar(1,\$ret);
}

sub escape
{
  my $c = shift;
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
  } else {
    return $c;
  }
}

sub parse_double_quoting_scalar
{
  my ($self, $check_eol, $t) = @_;
  my $final = '';
  while ( 1 ) {
    if ( $check_eol ) {
      $$t =~ m/\G\"$/gcs and last;
    } else {
      $$t =~ m/\G\"/gcs and last;
    }
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
      $final .= escape($1);
      redo;
    };
    $$t =~ m/\G(.+)/gc and return $self->raise("unexpected input: '$1'");
  }
  return $final;
}

sub parse_double_quoting
{
  my ( $self, $head, $t ) = @_;

  my $ret = $self->parse_quoted_multiline($head, '"', $t);
  return unless defined $ret;
  return $self->raise('Trailing double quote expected') unless $ret =~ m/"$/ms;
  return $self->parse_double_quoting_scalar(1, \$ret);
}

# 1. parses one of these:
#
# 1: key: head (head can be empty)
#   plain multiline
#
# 2: key:
#      hash or array
#
# starting after 'key: '
#
# if end of input or end of scope is reached, returns data read
#
# 2. Looks ahead to check for whether there are any extra keys after -foo:42
# (when $set_continuation is 1)
sub parse_leaf
{
  my ( $self, $set_continuation, $head, $t ) = @_;

  return $self->raise("invalid reserve character '$1'") if $head =~ m/^([\@\`])/;

  my $pos = pos($$t);

  # end
  goto SINGLE_LINED if $$t =~ m/\G$/gcs;
  return unless $self->expect_newline($t);

  # hash or array
  $pos = pos($$t);
  my $set_continuation_detected;
  if ($$t =~ m/\G(\x{20}*)((?:- )?\w*\x{20}*:|-)/gcs) {
    my $l = length $1;

    # same level? don't bother parsing
    goto SINGLE_LINED if $l == ($self->{step} || 0) * $self->{level};
    $self->{step} ||= $l; # happens only on level 0

    # end of scope? also don't parse
    goto SINGLE_LINED
      if $self->{level} > 0 && $l < $self->{step} * $self->{level};

    # deeper level?
    if ($l == $self->{step} * ( $self->{level} + 1 )) {
      if ($set_continuation) {
        $set_continuation_detected = 1;
        goto SINGLE_LINED;
      } elsif ( length $head ) {
        return $self->raise('cannot declare both immediate and deeper level data here');
      }

      $self->{level}++;
      pos($$t) = $pos;
      my $parsed = $self->parse_do($t);
      $self->{level}--;
      return $parsed, 0;
    }

    return $self->raise(
      "unexpected number of spaces, wanted " . 
      ($self->{step} * $self->{level}) . ", got $l"
    );
  }

  # plain multiline?
  my $nspaces = ( $self->{step} || 0 ) * ($self->{level} + 1 );
  my $spaces = ' ' x $nspaces;
  $pos = pos($$t);
  if ($$t =~ m/\G$spaces/gs) {
    pos($$t) = $pos;
    $spaces = undef if $self->{level} == 0 && !defined $self->{step};
    my $tail = $self->parse_plain_multiline($spaces, $t);
    return unless defined $tail;
    return $head . $tail, 0;
  }
 
  pos($$t) = $pos;
  $$t =~ m/\G(\x{20}*)/s;
  my $l = length($1) || 0;
  return $self->raise("badly formatted plain multiline scalar: expected $nspaces spaces, got $l");

SINGLE_LINED:
  pos($$t) = $pos;
  if ( $set_continuation && !$set_continuation_detected ) {
    # also look-ahead for eventual set continuation
    if ( defined $self->{step}) {
      my $nspaces = $self->{step} * $self->{level};
      my $spaces = ' ' x $nspaces;
      $set_continuation_detected = $$t =~ m/\G$spaces\w/gcs;
    } elsif ( $$t =~ m/\G\x{20}+\w/gcs) {
      $set_continuation_detected = 1;
    }
    pos($$t) = $pos;
  }
  $head =~ s/\s*(#.*)?$//;
  return $head, $set_continuation_detected;
}

sub parse_type_null { '' }

sub parse_type_bool
{
  my ( $self, $value ) = @_;
  return 1 if $value eq 'true';
  return 0 if $value eq 'false';
  return $self->raise("invalid boolean value");
}

sub parse_inline_array
{
  my ($self, $t) = @_;
  my @ret;
  $$t =~ m/\G\s*\]\s*$/gcs and return [];
  while ( 1 ) {
    my $scalar = $self->expect_scalar( $t );
    return unless defined $scalar;
    push @ret, $scalar;
    $$t =~ m/\G\s*/gcs;
    $$t =~ m/\G\]\s*/gcs and last;
    $self->expect_str(',', $t) or return;
    $$t =~ m/\G\s*/gcs;
  }
  return \@ret;
}

sub parse_inline_hash
{
  my ($self, $t) = @_;
  my %ret;
  $$t =~ m/\G\s*\}\*/gcs and return {};
  while ( 1 ) {
    my $key = $self->expect_scalar( $t );
    return unless defined $key;
    $self->expect_str(':', $t) or return;
    $$t =~ m/\G\s*/gcs;
    my $value = $self->expect_scalar( $t );
    return unless defined $value;
    $ret{$key} = $value;
    $$t =~ m/\G\s*/gcs;
    $$t =~ m/\G\}\s*/gcs and last;
    $self->expect_str(',', $t) or return;
    $$t =~ m/\G\s*/gcs;
  }
  return \%ret;
}

sub parse_inline_ref
{
  my ( $self, $t ) = @_;
  if ( $$t =~ /^\[(.*\])$/ ) {
    return $self->parse_inline_array(\"$1");
  } elsif ( $$t =~ /^\{(.*\})$/ ) {
    return $self->parse_inline_hash(\"$1");
  } else {
    return $self->raise('neither hash nor an array');
  }
}

sub parse_dataentry
{
  my ( $self, $head, $set_continuation, $t ) = @_;
  my $value;
  my $type;
  my $set_continuation_detected;

  if ( $head =~ /^(\!(?:[\!\w]+|\<[^\>]*\>))(\x{20}*)/ ) {
    my $xtag = $1;
    substr( $head, 0, length($1) + length($2), '');
    $type = $1 if $xtag =~ /^!!(\w+)$/;
  }
  if ( $head =~ /^([\&\*]\w+\s*)/) {
    # anchors are ignored for now
    substr( $head, 0, length($1), '');
  }
  if ( $head =~ /^([>|])([-+]?)(\d*)\s*(?:(#.*)|(.+))?$/) {
    return $self-> raise("unexpected input $5 in block scalar definition")
      if defined($5) && length($5);
    $value = $self->parse_block_scalar($1, $2, $3, $t);
  } elsif ( $head =~ /^\'(.*)/) {
    $value = $self->parse_single_quoting($1, $t);
  } elsif ( $head =~ /^"(.*)/) {
    $value = $self->parse_double_quoting($1, $t);
  } else {
    ($value, $set_continuation_detected) = $self->parse_leaf($set_continuation, $head, $t);
    return unless defined $value;
    $value = '' if $value eq '~';
    if ( defined $type && (my $method = $self->can("parse_type_$type"))) {
      $value = $method->($self, $value);
      return unless defined $value;
    }
    $value = $self->parse_inline_ref(\ $value) if $value =~ m/^[\[\{]/;
  }
  return $value, $set_continuation_detected;
}

sub parse_do
{
  my ($self, $t) = @_;
  my $data = undef;
  my $spaces;
  if ( $self->{level} > 0 ) {
    $spaces = ' ' x ( $self->{step} * $self->{level} );
    $spaces = qr/$spaces/;
  } else {
    $spaces = '';
  }

  while ( 1 ) {
    # empty lines
    $$t =~ m/\G\s*\#.*/gc and redo;
    $$t =~ m/\G\-\-\-\s*/gc and redo;
    $$t =~ m/\G\.\.\.\s*/gc and redo;
    $$t =~ m/\G\%.*/gc and redo;

    # newline
    $$t =~ m/\G\n/gcs and do {
      $self->{line}++;
      redo;
    };

    # hash or set
    $$t =~ m/\G$spaces(\- )?(\w+)\x{20}*\:\x{20}*(.*)/gc and do {
      my $is_set = $1;
      my $key    = $2;
      my $value  = $3;
      if ( $is_set ) {
        return $self->raise("array is not allowed here")
          if $self->{level} == 0 && !$self->{array_allowed};
        return $self->raise("current definition is not a set") if defined($data) && ref($data) ne 'ARRAY';
        $data = [] unless defined $data;

        my $set_continuation_detected;
        ($value, $set_continuation_detected) = $self-> parse_dataentry($value, 1, $t);
        my %set = ($key => $value);
        push @$data, \%set;
        return unless defined $value;

        if ( $set_continuation_detected ) {
          $self->{level}++;
          my $contd = $self->parse_do($t);
          $self->{level}--;
          return unless defined $contd;
          %set = ( %set, %$contd );
        }
      } else {
        return $self->raise("current definition is not a hash") if defined($data) && ref($data) ne 'HASH';
        ($value) = $self-> parse_dataentry($value, 0, $t);
        return unless defined $value;
        $data = {} unless defined $data;
        $data->{$key} = $value;
      }
      redo;
    };

    # arrays
    $$t =~ m/\G$spaces\-(?: (.*))?/gc and do {
      my ($value) = $self-> parse_dataentry(defined($1) ? $1 : '', 0, $t);
      return $self->raise("array is not allowed here")
        if $self->{level} == 0 && !$self->{array_allowed};
      return $self->raise("current definition is not an array") if defined($data) && ref($data) ne 'ARRAY';
      $data = [] unless defined $data;
      push @$data, $value if length $value; # also refs!
      redo;
    };

    # end of scope
    if ( $self->{level} > 0 ) {
      my $pos = pos($$t);
      if ( $$t =~ m/\G(\x{20}*)/gc ) {
        my $l = length $1;
        return $self->raise("uneven number of spaces ($l) when offset is $self->{step}")
          if $l > 0 && $l % $self->{step};
        return $self->raise('end of scope without any data')
          unless defined $data;
        return $self->raise("bad definition of a deeper level data with $l spaces")
          if $l >= $self->{step} * $self->{level};

        pos($$t) = $pos;
        return $data;
      }
    }

    pos($$t) = pos($$t); # double match on \G$ fails. Bug?
    $$t =~ m/\G$/gcs and do {
      return defined($data) ? $data : {};
    };

    # anything else
    $$t =~ m/\G(.+)/gc and return $self->raise("unexpected input: $1");
  }
}

sub parse
{
  my $self = $_[0];
  return $self->parse_do(\ $_[1]);
}


1;

=pod

=head1 NAME

Pod::Simple::YAML -- minimal YAML parser for the image tag

=head1 DESCRIPTION

Generic YAML parser based on YAML 1.2 spec is used to process content of C<=for
image> pod sections. These sections represent image properties such as
location, title, etc.

Only a subset of full YAML specification was implemented.  Specifically, the
following features are missing: tags, anchors, begin/end of document, binary
format.

=head1 SYNOPSIS

  use Pod::Simple::YAML;
  my $yaml   = Pod::Simple::YAML->new;
  my $parsed = $yaml->parse($_[2]);
  die "error: ", $yaml-> error, " at line ", $yaml->line, "\n"
    unless defined $parsed;

or, from command line:

  perl -MPod::Simple::YAML -e 'Pod::Simple::YAML->check(shift)' file.yml

=head1 RATIONALE

The module implements a rather complete set of YAML features, most notably
structures of arbitrary depth. Even though this is a clear overkill for the
purposes of the C<=for image> tag, it might not be so in the future; then, some
document containing such structures will throw an error when processed by an
older version of this module. The same is true for all other YAML features.

=head1 DIFFERENCES

The parser is different from the YAML specification in the following:

=over

=item *

Tags in form of C<%TAG> and C<!tagname> etc are unimplemented, but tolerated.
C<%YAML> and other C<%> tags are ignored, too

=item *

Anchors are unimplemented, but no error is thrown when these occur in the
document. The C<&> anchors are ignored, and C<*> aliases are set to null.

=item *

The start of the document tag, C<--->, is not required, but recognized, and the
end of the document tag C<...> is recognized too. However these tags in the
text do not mean anything for the parser, so trying to split a text into
several documents won't work, the whole text will be treated as a single
document. Use the following C<=begin/=end image> scheme for this:

   =begin image

   src: image1

   =end image

   =begin image

   src: image2

   =end image

=item *

The parser is lax on spaces required after a colon before a value, for
the sake of syntax brewity; it treats C<foo:bar> same as C<foo: bar>.

=item *

Types marked as C<!!type> are not recognized, but tolerated. Specifically,
binary format in form C<!!binary BASE64_TEXT> does not decode base64.  If the
image tag will evolve to have image bits embedded in a document, this will
be implemented.

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

=item *

Entries started with C<?> and C<:> (mapping between sequences, unordered sets)
are not recognized because the corresponding examples from http://yaml.org/
could not be parsed by the CPAN's YAML.pm reference implementation. Some help
might be needed here.

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

=item line

After parsing was tried and was unsuccessful, returns the line number where the error occured

=back

=head1 AUTHOR

Dmitry Karasik C<dmitry@karasik.eu.org>

=cut

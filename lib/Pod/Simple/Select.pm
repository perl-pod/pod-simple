
require 5;
package Pod::Simple::Select;
$VERSION = '3.29';

BEGIN {@ISA = qw(Pod::Simple Exporter)}

require Exporter;
@EXPORT = qw(&podselect);

use strict;
use warnings;
use Pod::Simple ();
use Carp ();
use constant MAX_HEAD_LVL => 4;

BEGIN { *DEBUG = \&Pod::Simple::DEBUG unless defined &DEBUG }


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Methods

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->{'raw_mode'}    = 1;
  return $new;
}


sub select {
  # Get or set the Pod sections to use
  my ($self, @sections) = @_;
  if (@sections) {
    my @regexs;
    for my $spec (@sections) {
      if (not defined $spec) {
        Carp::croak "Section should be specified as a scalar but got undef\n";
      }
      if (ref $spec) {
        Carp::croak "Section should be specified as a scalar but got a ".
          ref($spec)." reference\n";
      }
      push @regexs, $self->_compile_section_spec($spec);
    }
    $self->{sections} = \@sections;
    $self->{regexs}   = \@regexs;
  }
  return (exists $self->{sections}) ? @{$self->{sections}} : undef;
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Functions

sub podselect {  # 100% compatible with Pod::Select
  # Process arguments
  my %opts;
  if (ref $_[0] eq 'HASH') {
    %opts = %{shift()};
    # For backward compatibility (all uppercase words)
    %opts = map {
      my ($key, $val) = (lc $_, $opts{$_});
      $key =~ s/^(?=\w)/-/;
      $key =~ /^-se[cl]/  and  $key  = '-sections';
      ($key => $val);
    } (keys %opts);
  }
  my @inputs = @_ ? @_ : ();

  # Setup Pod parser
  my $parser = Pod::Simple::Select->new;
  if (defined $opts{'-sections'}) {
    $parser->select( @{$opts{'-sections'}} );
  }

  # Parse files
  my $output = $opts{'-output'};
  for my $input (@inputs) {
    $parser->parse_from_file($input, $output);
  }
  # parse_from_file() should take care of closing created filehandles

  return 1;
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Pod::Simple parsing interface

sub _handle_text {
  my ($self, $line) = @_;
  DEBUG and print "== \"$line\"\n";
  $line .= "\n";
  if ( (not defined $self->{sections}) || $self->_keep($line) ) {
    print {$self->{'output_fh'}} $line;
  }
  return 1;
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Helper methods

my $prev_keep;

sub _keep {
  # Method to decide whether to keep a line or not based on -section specs
  my ($self, $line) = @_;

  # Set headings
  my $para_has_changed = 0;
  if ($line =~ m/^=head([1-MAX_HEAD_LVL])\s+(.*)$/) {
    $para_has_changed = 1;
    my ($new_level, $new_heading) = ($1, $2);
    my $level = $self->{section_headings} || 0;
    $self->{section_headings}->[$new_level-1] = $new_heading;
    if ($new_level < $level) {
      for ($new_level .. scalar @{$self->{section_headings}} - 1) {
        pop @{$self->{section_headings}};
      }
    }
  }

  my $keep = 0;
  if (not $para_has_changed) {
    # Re-use previous match results if we are still in same paragraph
    $keep = $prev_keep;
  } else {
    # Do match to see if we keep this line
    if ($self->{section_headings}) {
      for my $re_specs (@{$self->{regexs}}) {
        # To keep this Pod, each portion of this spec must match. Assume a
        # match and apply 'and' on it with the results of matching the specs.
        my $match = 1;
        for my $i (0 .. MAX_HEAD_LVL-1) {
          my $name = $self->{section_headings}->[$i];
          last if not defined $name;
          my $re = $re_specs->[$i];
          my $negated = ($re =~ s/^\!//);
          $match  &= ( $negated ? ($name !~ /${re}/) : ($name =~ /${re}/) );
          last if not $match;
        }
        if ($match) {
          $keep = 1;
          last;
        }
      }
    }
    $prev_keep = $keep;
  }

  return $keep;
}


sub _compile_section_spec {
  # Method that takes a section specification and compiles it into a
  # list of regular, and returns the list. An error message is issued when
  # an invalid regex is encountered. This code was pretty much entirely
  # taken from Pod::Select.
  my ($self, $section_spec) = @_;
  my (@regexs, $negated);

  # Compile the spec into a list of regexs
  local $_ = $section_spec;
  s{\\\\}{\001}g;  # handle escaped backward slashes
  s{\\/}{\002}g;   # handle escaped forward slashes

  # Parse the regexs for the heading titles
  @regexs = split(/\//, $_, MAX_HEAD_LVL);

  # Set default regex for omitted levels
  for my $i (0 .. MAX_HEAD_LVL-1) {
    $regexs[$i] = '.*' if not (   (defined $regexs[$i])
                               && (length  $regexs[$i]) );
  }
  # Modify the regexs as needed and validate their syntax
  for (@regexs) {
    $_ .= '.+'  if ($_ eq '!');
    s{\001}{\\\\}g;       # restore escaped backward slashes
    s{\002}{\\/}g;        # restore escaped forward slashes
    $negated = s/^\!//;   # check for negation
    eval "m{$_}";         # check regex syntax
    if ($@) {
      Carp::croak "Bad regular expression /$_/ in '$section_spec': $@\n";
    } else {
      # Add the forward and rear anchors (and put the negator back)
      $_ = '^' . $_  if not /^\^/;
      $_ = $_ . '$'  if not /\$$/;
      $_ = '!' . $_  if $negated;
    }
    $_ = qr/$_/;
  }
  return \@regexs;
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

1;

__END__

=head1 NAME

Pod::Simple::Select -- Extract selected sections of Pod

=head1 SYNOPSIS

   perl -MPod::Simple::Select -e \
    "exit Pod::Simple::Select->filter(shift)->any_errata_seen" \
    thingy.pod

=head1 DESCRIPTION

This module is for extracting Pod from Perl files and displaying only the
desired sections. It aims at replacing the module L<Pod::Select>.

=head1 OBJECT METHODS

This module a subclass of L<Pod::Simple> and inherits all of its methods.

In addition, the following methods are provided:

=head2 select

   $parser->select($section_spec1, $section_spec2, ...);

This method is used to store or retrieve the specifications of the
particular sections and subsections of Pod documentation to be extracted.
Each of the C<$section_spec> arguments should be specified as described
in L<"SECTION SPECIFICATIONS">. If no C<$section_spec> arguments are
given, B<all> sections are processed.

=head1 FUNCTIONS

The following function is exported by this module. Please note that this
is a function (not a method) and therefore does not take an implicit
first argument.

=head2 podselect

   podselect(\%options, @filelist);

C<podselect()> is a drop-in replacement for the C<podselect()> function
of L<Pod::Select>.

C<podselect()> will print the raw (untranslated) POD paragraphs of all
POD sections in the given input files specified by C<@filelist>
according to the given options.

If the first argument to B<podselect> is a reference to a hash
(associative array) then the values with the following keys are
processed as follows:

=over

=item -output

A string corresponding to the desired output file (or '>&STDOUT'
or '>&STDERR'), or filehandle to write on. The default is to use
standard output.

=item -sections

A reference to an array of sections specifications (as described in
L<"SECTION SPECIFICATIONS">) which indicate the desired set of POD
sections and subsections to be selected from input. If no section
specifications are given, then all sections of the PODs are used.

=back

All other arguments are optional and should correspond to the names
of input files (or filehandles) containing POD sections. A file name of
'', '-' or '<&STDIN' means to read from standard input (which is the
default if no filenames are given).

=head1 SECTION SPECIFICATIONS

C<podselect()> and C<Pod::Select::select()> may be given one or more
"section specifications" to restrict the text processed to only the
desired set of sections and their corresponding subsections. Each section
specification is a string containing one or more Perl-style regular
expressions separated by forward slashes ('/').  If you need to use a
forward slash literally within a section title you can escape it with a
backslash ('\/').

The formal syntax of a section specification is:

=over

=item *

I<head1-title-regex>/I<head2-title-regex>/...

=back

Any omitted or empty regular expressions will default to '.*'.
Please note that each regular expression given is implicitly
anchored by adding '^' and '$' to the beginning and end.  Also, if a
given regular expression starts with a '!' character, then the
expression is I<negated> (so C<!foo> would match anything I<except>
C<foo>).

Some example section specifications follow.

=over 4

=item *

Match the C<NAME> and C<SYNOPSIS> sections and all of their subsections:

C<NAME|SYNOPSIS>

=item *

Match only the C<Question> and C<Answer> subsections of the C<DESCRIPTION>
section:

C<DESCRIPTION/Question|Answer>

=item *

Match the C<Comments> subsection of I<all> sections:

C</Comments>

=item *

Match all subsections of C<DESCRIPTION> I<except> for C<Comments>:

C<DESCRIPTION/!Comments>

=item *

Match the C<DESCRIPTION> section but do I<not> match any of its subsections:

C<DESCRIPTION/!.+>

=item *

Match all top level sections but none of their subsections:

C</!.+>

=back 

=head1 SEE ALSO

L<Pod::Simple>

The older library, L<Pod::Select>, upon which this one is based.

=head1 SUPPORT

Questions or discussion about POD and Pod::Simple should be sent to the
pod-people@perl.org mail list. Send an empty email to
pod-people-subscribe@perl.org to subscribe.

This module is managed in an open GitHub repository,
L<http://github.com/theory/pod-simple/>. Feel free to fork and contribute, or
to clone L<git://github.com/theory/pod-simple.git> and send patches!

Patches against Pod::Simple are welcome. Please send bug reports to
<bug-pod-simple@rt.cpan.org>.

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2002 Sean M. Burke.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Pod::Simple was created by Sean M. Burke <sburke@cpan.org>.
But don't bother him, he's retired.

Pod::Simple is maintained by:

=over

=item * Allison Randal C<allison@perl.org>

=item * Hans Dieter Pearcey C<hdp@cpan.org>

=item * David E. Wheeler C<dwheeler@cpan.org>

=back

=cut

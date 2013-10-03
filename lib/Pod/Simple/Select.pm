
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


sub select {  # for compatibility with Pod::Select
  # Get or set the Pod sections to use
  my ($self, @sections) = @_;
  if (@sections) {
    for my $section (@sections) {
      if (not defined $section) {
        Carp::croak "Section should be specified as a scalar but got undef\n";
      }
      if (ref $section) {
        Carp::croak "Section should be specified as a scalar but got a ".
          ref($section)." reference\n";
      }
      Carp::carp "Selecting -sections is not implemented!\n"; #### TODO
    }
    $self->{sections} = \@sections;
  }
  return $self->{sections};
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Functions

sub podselect {  # for compatibility with Pod::Select
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
  print {$self->{'output_fh'}}
        ( (defined $self->select) ? $self->_filter($line) : $line);
  return 1;
}


sub _filter {
  my ($self, $line) = @_;
  ### TODO: filter line based on sections stored in $self->select()
  return $line;
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
desired set of sections and their corresponding subsections.  A section
specification is a string containing one or more Perl-style regular
expressions separated by forward slashes ("/").  If you need to use a
forward slash literally within a section title you can escape it with a
backslash ("\/").

The formal syntax of a section specification is:

=over

=item *

I<head1-title-regex>/I<head2-title-regex>/...

=back

Any omitted or empty regular expressions will default to ".*".
Please note that each regular expression given is implicitly
anchored by adding "^" and "$" to the beginning and end.  Also, if a
given regular expression starts with a "!" character, then the
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

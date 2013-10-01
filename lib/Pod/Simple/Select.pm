
require 5;
package Pod::Simple::Select;
$VERSION = '3.20';

BEGIN {@ISA = qw(Pod::Simple Exporter)}

require Exporter;
@EXPORT = qw(&podselect);

use strict;
use warnings;
use Pod::Simple ();

BEGIN { *DEBUG = \&Pod::Simple::DEBUG unless defined &DEBUG }

sub new {
  my $self = shift;
  my $new = $self->SUPER::new(@_);
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->{'raw_mode'}    = 1;
  return $new;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Pod::Simple interface

sub _handle_text { # self, pod_line
  my ($self, $pod_line) = @_;
  DEBUG and print "== \"$pod_line\"\n";
  print {$self->{'output_fh'}} $pod_line, "\n";
  return;
}


#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Compatibility with Pod::Select

sub podselect {
   die "podselect() is not implemented!\n";
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

This is a subclass of L<Pod::Simple> and inherits all of its methods.

=head1 EXPORTED FUNCTION

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

If any argument to B<podselect> is a reference to a hash
(associative array) then the values with the following keys are
processed as follows:

=over

=item -output

A string corresponding to the desired output file (or ">&STDOUT"
or ">&STDERR"). The default is to use standard output.

=item -sections

A reference to an array of sections specifications (as described in
L<"SECTION SPECIFICATIONS">) which indicate the desired set of POD
sections and subsections to be selected from input. If no section
specifications are given, then all sections of the PODs are used.

=back

=head1 SEE ALSO

L<Pod::Simple>

The older library, L<Pod::Select>

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

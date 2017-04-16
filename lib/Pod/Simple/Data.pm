

require 5;
package Pod::Simple::Data;
use strict;
use Carp ();
use Pod::Simple ();
use vars qw( @ISA $VERSION );
$VERSION = '3.28';
@ISA = ('Pod::Simple');

sub new {
  my $self = shift;
  my $new = $self->SUPER::new();
  $new->{'output_fh'} ||= *STDOUT{IO};
  $new->nix_X_codes(1);
  push @_, '*' unless scalar(@_);
  $new->accept_targets(@_);
  return $new;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~w

sub _handle_text {
  my $para = $_[0]{'curr_open'}->[-1];
  if (defined $para && $para->[0] eq '=for') {
     print {$_[0]{'output_fh'}} $_[1];
     print {$_[0]{'output_fh'}} "\n" unless $_[1] =~ /\n$/;
  }
  return;
}

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
1;


__END__

=head1 NAME

Pod::Simple::Data -- get the data inlined in Pod

=head1 SYNOPSIS

  perl -MPod::Simple::Data -e \
   "exit Pod::Simple::Data->new('stuff', 'xstuff')->parse_file(shift)->any_errata_seen" \
   thingy.pod

=head1 DESCRIPTION

This class is that for retrieving data from C<< =begin/=for/=end >> sections.
The constructor accepts a list of identifier, the default is '*' which allows
to retrieve all data.

This is a subclass of L<Pod::Simple> and inherits all its methods.

=head1 CALLING FROM THE COMMAND LINE

  perl -MPod::Simple::Data -e \
   "exit Pod::Simple::Data->new()->parse_file(shift)->any_errata_seen" \
   thingy.pod

=head1 CALLING FROM PERL

=head2 Minimal code

  use Pod::Simple::Data;
  my $p = Pod::Simple::Data->new();
  $p->output_string(\my $data);
  $p->parse_file('path/to/Module/Name.pm');
  open my $out, '>', 'out.dat' or die "Cannot open 'out.dat': $!\n";
  print $out $data;

=head1 SEE ALSO

L<Pod::Simple>, L<< perlpodspec/About Data Paragraphs >>

=head1 SUPPORT

Questions or discussion about POD and Pod::Simple should be sent to the
pod-people@perl.org mail list. Send an empty email to
pod-people-subscribe@perl.org to subscribe.

This module is managed in an open GitHub repository,
L<https://github.com/theory/pod-simple/>. Feel free to fork and contribute, or
to clone L<git://github.com/theory/pod-simple.git> and send patches!

Patches against Pod::Simple are welcome. Please send bug reports to
<bug-pod-simple@rt.cpan.org>.

=head1 COPYRIGHT AND DISCLAIMERS

Copyright (c) 2014 Francois Perrad.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=head1 AUTHOR

Pod::Simple::Data was created by Francois Perrad <francois.perrad@gadz.org>.

Pod::Simple is maintained by:

=over

=item * Allison Randal C<allison@perl.org>

=item * Hans Dieter Pearcey C<hdp@cpan.org>

=item * David E. Wheeler C<dwheeler@cpan.org>

=back

=cut

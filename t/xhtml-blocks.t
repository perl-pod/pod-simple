#!/usr/bin/perl -w

# t/xhtml-basic.t - check output from Pod::Simple::XHTML

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 5;

use_ok('Pod::Simple::XHTML') or exit;

my $parser = Pod::Simple::XHTML->new ();
isa_ok ($parser, 'Pod::Simple::XHTML');

my $results;

foreach my $target qw(note tip warning) {
  initialize($parser, $results);
  $parser->accept_targets_as_text( $target );
  $parser->parse_string_document(<<"EOPOD");
=begin $target

This is a $target.

=end $target
EOPOD

  is($results, <<"EOHTML", "allow $target blocks");
<div class="$target">

<p>This is a $target.</p>

</div>

EOHTML

}

######################################

sub initialize {
	$_[0] = Pod::Simple::XHTML->new ();
        $_[0]->add_body_tags(0);
	$_[0]->output_string( \$results ); # Send the resulting output to a string
	$_[1] = '';
	return;
}

#!/usr/bin/perl -w

# t/data01.t - check basic output from Pod::Simple::Data

BEGIN {
    chdir 't' if -d 't';
}

use strict;
use lib '../lib';
use Test::More tests => 11;

use_ok('Pod::Simple::Data') or exit;

my $parser = Pod::Simple::Data->new ();
isa_ok ($parser, 'Pod::Simple::Data');
isa_ok ($parser, 'Pod::Simple');

my $results;

$parser = Pod::Simple::Data->new ();
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document(<<'EOPOD');
=pod

=begin xml

<root>
    <child/>
</root>

=end xml
EOPOD

is($results, <<'EODATA', "single data");
<root>
    <child/>
</root>
EODATA


$parser = Pod::Simple::Data->new ('*');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document(<<'EOPOD');
=pod

=head1 Head

=begin xml

<root>

=end xml

=over 4

=item Child

=begin xml

    <child/>

=end xml

=back

=begin xml

</root>

=end xml

=cut
EOPOD

is($results, <<'EODATA', "mixed data");
<root>
    <child/>
</root>
EODATA

my $pod = << 'EOPOD';
=pod

=for xml <root>

=for xml1 <child1/>

=for xml2 <child2/>

=for xml </root>

=cut
EOPOD

$parser = Pod::Simple::Data->new ();
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, <<'EODATA', "all data");
<root>
<child1/>
<child2/>
</root>
EODATA

$parser = Pod::Simple::Data->new ('no_stuff');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, '', "no data");

$parser = Pod::Simple::Data->new ('xml');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, <<'EODATA', "xml");
<root>
</root>
EODATA

$parser = Pod::Simple::Data->new ('xml', 'xml1');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, <<'EODATA', "xml + xml1");
<root>
<child1/>
</root>
EODATA

$parser = Pod::Simple::Data->new ('xml', 'xml2');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, <<'EODATA', "xml + xml2");
<root>
<child2/>
</root>
EODATA

$parser = Pod::Simple::Data->new ('xml', 'xml1', 'xml2');
$results = ''; $parser->output_string( \$results );
$parser->parse_string_document($pod);
is($results, <<'EODATA', "xml + xml1 + xml2");
<root>
<child1/>
<child2/>
</root>
EODATA


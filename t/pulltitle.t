
use strict;
use Test;
BEGIN { plan tests => 42 };

#use Pod::Simple::Debug (5);

#sub Pod::Simple::MANY_LINES () {1}
#sub Pod::Simple::PullParser::DEBUG () {3}


use Pod::Simple::PullParser;

ok 1;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
###########################################################################

{
print "# Testing set 1\n";

my $p = Pod::Simple::PullParser->new;
$p->set_source( \qq{\n=head1 NAME\n\nBzorch\n\n=pod\n\nLala\n\n\=cut\n} );

ok $p->get_title(), 'Bzorch';
my $t;

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'Document' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'head1' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'text');
ok( $t && $t->type eq 'text' && $t->text, 'NAME' );

}

###########################################################################

{
print "# Testing set 2\n";

my $p = Pod::Simple::PullParser->new;
$p->set_source( \qq{\n=head1 NAME\n\nBzorch - I<thing> lala\n\n=pod\n\nLala\n\n\=cut\n} );

ok $p->get_title(), 'Bzorch - thing lala';
my $t;

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'Document' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'head1' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'text');
ok( $t && $t->type eq 'text' && $t->text, 'NAME' );

}

###########################################################################

{
print "# Testing set 3\n";

my $p = Pod::Simple::PullParser->new;
$p->set_source( \qq{\n=head1 Bzorch lala\n\n=pod\n\nLala\n\n\=cut\n} );

ok $p->get_title(), 'Bzorch lala';
my $t;

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'Document' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'head1' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'text');
ok( $t && $t->type eq 'text' && $t->text, 'Bzorch lala' );

}

###########################################################################

{
print "# Testing set 4\n";

my $p = Pod::Simple::PullParser->new;
$p->set_source( \qq{\n=head1 Bzorch - I<thing> lala\n\n=pod\n\nLala\n\n\=cut\n} );

ok $p->get_title(), 'Bzorch - thing lala';
my $t;

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'Document' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'start');
ok( $t && $t->type eq 'start' && $t->tagname, 'head1' );

ok( $t = $p->get_token);
ok( $t && $t->type, 'text');
ok( $t && $t->type eq 'text' && $t->text, 'Bzorch - ' );

}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";

__END__


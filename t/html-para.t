# t/html-para.t
 
use strict;
use Test;
BEGIN { plan tests => 8 };

#use Pod::Simple::Debug (10);

use Pod::Simple::HTML;

sub x ($) { Pod::Simple::HTML->_out(
  sub{  $_[0]->bare_output(1)  },
  "=pod\n\n$_[0]",
) }

ok( x(
q{
=pod
 
This is a paragraph
 
=cut
}),
  qq{\n<p>This is a paragraph</p>\n},
  "paragraph building"
);


ok( x(qq{=pod\n\nThis is a paragraph}),
 qq{\n<p>This is a paragraph</p>\n},
 "paragraph building"
);


ok( x(qq{This is a paragraph}),
 qq{\n<p>This is a paragraph</p>\n},
 "paragraph building"
);



ok(x(
'=head1 This is a heading')
 => qq{\n<h1><a name="This_is_a_heading"\n>This is a heading</a></h1>\n},
  "heading building"
);

ok(x(
'=head2 This is a heading')
 => qq{\n<h2><a name="This_is_a_heading"\n>This is a heading</a></h2>\n},
  "heading building"
);

ok(x(
'=head3 This is a heading')
 => qq{\n<h3><a name="This_is_a_heading"\n>This is a heading</a></h3>\n},
  "heading building"
);

ok(x(
'=head4 This is a heading')
 => qq{\n<h4><a name="This_is_a_heading"\n>This is a heading</a></h4>\n},
  "heading building"
);


print "# And one for the road...\n";
ok 1;


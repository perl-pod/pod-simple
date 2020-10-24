

use strict;
use warnings;
use Test;
BEGIN { plan tests => 37 };

#use Pod::Simple::Debug (6);

ok 1;

use Pod::Simple::SimpleTree;
print "# Pod::Simple version $Pod::Simple::VERSION\n";

my $hashes_dont_matter = 0;


my $x = 'Pod::Simple::SimpleTree';
sub x {
 my $p = $x->new;
 $p->merge_text(1);
 $p->parse_string_document( shift )->root;
}

sub xi {
 my $p = $x->new;
 $p->merge_text(1);
 $p->accept_image;
 $p->parse_string_document( shift )->root;
}

ok 1;

print "# a bit of meta-testing...\n";
&ok( deq( 1,     1     ));
&ok(!deq( 2,     1     ));

&ok( deq( undef, undef ));
&ok(!deq( undef, 1     ));
&ok(!deq( 1,     undef ));

&ok( deq( [ ],   [ ]    ));
&ok(!deq( [ ],   1      ));
&ok(!deq( 1,     [ ]    ));

&ok( deq( [1],   [1]    ));
&ok(!deq( [1],   1      ));
&ok(!deq( 1,     [1]    ));
&ok(!deq( [1],   [ ]    ));
&ok(!deq( [ ],   [1]    ));
&ok(!deq( [1],   [2]    ));
&ok(!deq( [2],   [1]    ));

&ok( deq( [ ],   [ ]    ));
&ok(!deq( [ ],   1      ));
&ok(!deq( 1,     [ ]    ));

&ok( deq( {},    {}     ));
&ok(!deq( {},    1      ));
&ok(!deq( 1,     {}     ));
&ok(!deq( {1,2}, {}     ));
&ok(!deq( {},    {1,2}  ));
&ok( deq( {1,2}, {1,2}  ));
&ok(!deq( {2,1}, {1,2}  ));




print '# ', Pod::Simple::pretty(x( "=pod\n\nI like pie.\n" )), "\n";
print "# Making sure we get a tree at all...\n";
ok x( "=pod\n\nI like pie.\n" );


print "# Some real tests...\n";
&ok( deq( x( "=pod\n\nI like pie.\n"),
  [ "Document", {"start_line"=>1},
    [ "Para",   {"start_line"=>3},
      "I like pie."
    ]
  ]
));

$hashes_dont_matter = 1;

&ok( deq( x("=pod\n\nB<foo\t>\n"),
  [ "Document", {},
    [ "Para",   {},
      ["B",     {},
        "foo "
      ]
    ]
  ]
));


&ok( deq( x("=pod\n\nB<pieF<zorch>X<foo>I<pling>>\n"),
  [ "Document", {},
    [ "Para",   {},
      ["B",     {},
        "pie",
        ['F',{}, 'zorch'],
        ['X',{}, 'foo'  ],
        ['I',{}, 'pling'],
      ]
    ]
  ]
));

&ok( deq( x("=over\n\n=item B<pieF<zorch>X<foo>I<pling>>!\n\n=back"),
  [ "Document", {},
    [ "over-text", {},
      [ "item-text", {},
        ["B",     {},
          "pie",
          ['F',{}, 'zorch'],
          ['X',{}, 'foo'  ],
          ['I',{}, 'pling'],
        ],
        '!'
      ]
    ]
  ]
));

&ok( deq( x("=for image src:foo.png"),
  [ "Document", { start_line => 1} ]
));

&ok( deq( xi("=for image src:foo.png"),
  [ "Document", {},
    [ "for", {"start_line"=>1, "target"=>"image", "target_matching"=>"image", "~ignore"=>0, "~image"=>'plain', "~really"=>"=for", "~resolve"=>0},
      [ "Image", {"image"=>{"src"=>"foo.png"}, "start_line"=>1} ]
    ]
  ]
));


&ok( deq( xi("=begin image-title\n\nsrc:foo.png\n\n=end image-title\n\ntitle\n\n=for image-cut"),
  [ "Document", {},
    [ "for", {"start_line"=>5, "target"=>"image-title", "target_matching"=>"image-title", "~ignore"=>0, "~image"=>'title', "~really"=>"=for", "~resolve"=>0},
      [ "Image", {"image"=>{"src"=>"foo.png"}, "start_line"=>3}, 
        [ 'ImageTitle', {"image"=>{"src"=>"foo.png"}, "start_line"=>3} ],
        [ 'Para', {"start_line"=>7}, "title" ],
        [ "for", {"start_line"=>9, "target"=>"image-cut", "target_matching"=>"image-cut", "~ignore"=>0, "~image"=>'title-cut', "~really"=>"=for", "~resolve"=>0}],
      ]
    ]
  ]
));

&ok( deq( xi("=begin image-text\n\nsrc:foo.png\n\n=end image-text\n\nskip\n\n=for image-cut"),
  [ "Document", {},
    [ "for", {"start_line"=>1, "target"=>"image", "target_matching"=>"image", "~ignore"=>0, "~image"=>'plain', "~really"=>"=for", "~resolve"=>0},
      [ "Image", {"image"=>{"src"=>"foo.png"}, "start_line"=>1} ]
    ]
  ]
));

print "# Wrapping up... one for the road...\n";
ok 1;
print "# --- Done with ", __FILE__, " --- \n";

sub deq { # deep-equals
  #print "# deq ", Pod::Simple::pretty($_[0], $_[1]), "\n";
  return 1 unless defined $_[0] or defined $_[1]; # two undefs = same
  return '' if defined $_[0] xor defined $_[1];
  return '' if ref($_[0]) ne ref($_[1]); # unequal referentiality
  return $_[0] eq $_[1] unless ref $_[0];
  # So it's a ref:
  if(UNIVERSAL::isa($_[0], 'ARRAY')) {
    return '' unless @{$_[0]} == @{$_[1]};
    for(my $i = 0; $i < @{$_[0]}; $i++) {
      print("# NEQ ", Pod::Simple::pretty($_[0]),
          "\n#  != ", Pod::Simple::pretty($_[1]), "\n"),
       return '' unless deq($_[0][$i], $_[1][$i]); # recurse!
    }
    return 1;
  } elsif(UNIVERSAL::isa($_[0], 'HASH')) {
    return 1 if $hashes_dont_matter;
    return '' unless keys %{$_[0]} == keys %{$_[1]};
    foreach my $k (keys %{$_[0]}) {
      return '' unless exists $_[1]{$k};
      return '' unless deq($_[0]{$k}, $_[1]{$k});
    }
    return 1;
  } else {
    print "# I don't know how to deque $_[0] & $_[1]\n";
    return 1;
  }
}



#!perl
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/../lib";
use Pod::Simple::YAML;
use JSON;
use Test::More;
use Data::Dumper;

die <<USAGE unless @ARGV;

format: $0 path_to_yaml_test_suite

get the latest test suite by 
git clone https://github.com/yaml/yaml-test-suite.git
USAGE

die "argument doesn't point to yaml test suite" unless -d $ARGV[0] && -d "$ARGV[0]/test";
my $path = "$ARGV[0]/test";

opendir D, $path or die $!;
for my $tn ( sort readdir D ) {
	my $f = "$path/$tn";
	next unless -f $f && $tn =~ /tml$/;

	if ( $tn =~ /
             36F6|5LLU|7ZZ5|CML9|
             9C9N|AB8U|
             DK4H|F6MC|F8F9|H2RW|
             NAT4|P2AD|QLJ7|R4YG|
             RR7F|S98Z|S9E8|SKE5|FTA2|
             U99R|W9L4|ZWK4|ZXT5
	/x) {
    # 1: These I think contradict either the spec or some other tests:
		# 36F6, F6MC: wrong multiline without spaces; IIUC conflicts with https://yaml.org/spec/1.2/spec.html#id2778971
		# H2RW, NAT4: - "" -
    #           : also, see examples in https://yaml-multiline.info/, there are always indents
		# 5LLU, S98Z: should be just treated as empty lines, as in https://yaml.org/spec/1.2/spec.html#id2778971?
    # W9L4      :
		# 9C9N: not compatible with 7TMG and possibly 4MUZ
    # CML9: conflicts with multi lines in f.ex. 8KB6
		# F8F9, P2AD: bug in test: keep should have 1 \n, not 2 (see example 8.5 in spec)
    # R4YG: <TAB> in the example is not present in the spec
    # U99R: conflicts with '6.8.2.2. Tag Prefixes'

    # 2: These are very confusing
		# DK4H, ZXT5: looks absolutely good to me. Any reference why?
		# AB8U: decidedly not supported
		# 7ZZ5: "- a\nb: c", i.e. hash and array on same level ... no idea what to do about it

    # 3: These are acknowledged specifically because anchors & stuff are not supported anyway,
    # but this script test for specific "anchors not supported" error, -- and these tests
    # throw some other error
    # QLJ7: tags are disallowed anyway; acknowledged
    # RR7F, ZWK4: explicit key error is not thrown but it's that error, acknowledged
    # FTA2, S9E8: - "" - same, but anchor
    # SKE5:     : - "" -
		SKIP: { skip $tn, 1 };
		next;
	}

	open F, "<", $f or die "cannot open $f:$!";
	binmode F, ":utf8";
	my %sections;
	my $last = '';
	my %tags;
	my $yaml_doc;
	my $title = $tn;
	while (<F>) {
		if ( m/^\-\-\-\s+([\-\w]+)(.*)/) {
			$last = $1;
			if ( $1 eq 'in-yaml' && $2 eq '(<)') {
				$yaml_doc++;
			} elsif ( $1 eq 'tags' && $2 =~ m/^\s*:\s*(.*)$/) {
				%tags = map { $_ => 1 } split /\s+/, $1;
			} else {
				$yaml_doc = 0;
			}
		} elsif ( m/^===\s+(.*)$/) {
			chomp $1;
			$title .= " ($1)";
		} else {
			s/^\x{20}{4}// if $yaml_doc;
			s/<SPC>/ /g;
			s/<TAB>/\t/g;
			$sections{$last} .= $_;
		}
	}
	close F;
	unless (defined $sections{'in-yaml'}) {
		SKIP: { skip "No in-yaml in $title", 1 };
		next;
	}
	unless (defined $sections{'in-json'} or defined $sections{'error'}) {
		SKIP: { skip "Neither in-json nor error in $title", 1 };
		next;
	}
	if (defined $sections{'in-json'} and defined $sections{'error'}) {
		SKIP: { skip "Both in-json and error in $title", 1 };
		next;
	}

	if (defined $tags{'1.3-mod'}) {
		SKIP: { skip "1.3-mod in $title", 1 };
		next;
	}
	if (defined $tags{'1.3-err'}) {
		SKIP: { skip "1.3-err in $title", 1 };
		next;
	}
	if ( $sections{'in-yaml'} =~ /!!(map|seq|omap)/) {
		SKIP: { skip "!!map/seq/omap in $title", 1 };
		next;
	}

	my $yaml = Pod::Simple::YAML->new( array_allowed => 1 );
	my $struc = $yaml->parse($sections{'in-yaml'});

	if ( defined $sections{error}) {
		ok( !defined $struc, $title);
		diag(Dumper($struc)) if defined $struc;
	} else {
		if ( $tags{anchor} || $tags{alias} || $tags{'explicit-key'}) {
			# should fail
			like(
				$yaml->error || '',
				qr/anchors|aliases|explicit\skeys|!!(set|map|omap)/,
				"$title: anchors,aliases,explicit keys are not supported"
			);
			diag(Dumper($struc)) if defined $struc;
			next;
		}

		my $json;
		eval { $json = decode_json( $sections{'in-json'} ) };
		if ( $@ ) {
			SKIP: {
				skip "Bad JSON in $title", 1;
			}
		} elsif ( ref($json) !~ /ARRAY|HASH/) {
			# scalars are not supported
			ok( !defined $struc, $title);
		} elsif ( defined $struc ) {
			$json = fixup_json($json);
			my $ok = is_deeply( $struc, $json, $title);
			diag(Dumper($struc, $json)) unless $ok;
		} else {
			ok( 0, $title );
			diag( $yaml->error );
		}
	}
}
closedir D;

sub fixup_json
{
	my $r = shift;
	if ( ref($r) eq 'HASH') {
		my $k = { map { $_, fixup_json($r->{$_}) } keys %$r };
		return $k;
	} elsif ( ref($r) eq 'ARRAY') {
		return [ map { fixup_json($_) } @$r ];
	} elsif ( ref($r) eq 'JSON::PP::Boolean') {
		return "$r";
	} elsif ( defined $r ) {
		return $r;
	} else {
		return ''; # this is our null
	}
}

done_testing;

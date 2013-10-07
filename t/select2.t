BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    } else {
        push @INC, '../lib';
    }
}

use strict;
use Test;
BEGIN { plan tests => 56 };
use Pod::Simple::Select;


chdir 't' unless $ENV{PERL_CORE};


# 

my $pod = <<EOP;
=pod

=head1 NAME

perlfaq3 - Programming Tools

=head1 DESCRIPTION

This section of the FAQ answers questions related to programmer tools
and programming support.

=head2 How do I do (anything)?

Have you looked at CPAN (see L<perlfaq2>)?  The chances are that
someone has already written a module that can solve your problem.
Have you read the appropriate man pages?  Here's a brief index:

        Basics          perldata, perlvar, perlsyn, perlop, perlsub
        Execution       perlrun, perldebug

=head2 To use perl interactively

The typical approach uses the Perl debugger, described in the
perldebug(1) man page, on an ``empty'' program.

=cut

=head2 Is there a Perl shell?

In general, no.  The Shell.pm module (distributed with Perl) makes
Perl try commands which aren't part of the Perl language as shell
commands.

=head2 Is there an IDE or Windows Perl Editor?

Perl programs are just plain text, so any editor will do, but check
the following:

=over 4

=item CodeMagicCD

http://www.codemagiccd.com/

=item Komodo

ActiveState's cross-platform, multi-language IDE has Perl support.

=back

=head1 COPYRIGHT

Copyright (c) 1997-1999

EOP

my ($parser, $out);

# Select everything
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->parse_string_document($pod);
ok $out, $pod;

# Select everything
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select(), undef;
ok $parser->parse_string_document($pod);
ok $out, $pod;

# Select all sections
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok [$parser->select('.*')]->[0], '.*';
ok [$parser->select()]->[0], '.*';
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

=head1 DESCRIPTION

This section of the FAQ answers questions related to programmer tools
and programming support.

=head2 How do I do (anything)?

Have you looked at CPAN (see L<perlfaq2>)?  The chances are that
someone has already written a module that can solve your problem.
Have you read the appropriate man pages?  Here's a brief index:

        Basics          perldata, perlvar, perlsyn, perlop, perlsub
        Execution       perlrun, perldebug

=head2 To use perl interactively

The typical approach uses the Perl debugger, described in the
perldebug(1) man page, on an ``empty'' program.

=cut

=head2 Is there a Perl shell?

In general, no.  The Shell.pm module (distributed with Perl) makes
Perl try commands which aren't part of the Perl language as shell
commands.

=head2 Is there an IDE or Windows Perl Editor?

Perl programs are just plain text, so any editor will do, but check
the following:

=over 4

=item CodeMagicCD

http://www.codemagiccd.com/

=item Komodo

ActiveState's cross-platform, multi-language IDE has Perl support.

=back

=head1 COPYRIGHT

Copyright (c) 1997-1999

};

# Select a head1 paragraph
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok [$parser->select('NAME')]->[0], 'NAME';
ok [$parser->select()]->[0], 'NAME';
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

};

# Select several paragraphs (several arguments)
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('NAME', 'COPYRIGHT');
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

=head1 COPYRIGHT

Copyright (c) 1997-1999

};

# Select several paragraphs (logical or)
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('NAME|COPYRIGHT');
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

=head1 COPYRIGHT

Copyright (c) 1997-1999

};

# Select by exclusion
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('!DESCRIPTION');
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

=head1 COPYRIGHT

Copyright (c) 1997-1999

};

# Select paragraphs at heading level 2
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('DESCRIPTION/To use perl interactively');
ok $parser->parse_string_document($pod);
ok $out, q{=head2 To use perl interactively

The typical approach uses the Perl debugger, described in the
perldebug(1) man page, on an ``empty'' program.

=cut

};

# Select paragraphs at heading level 2 (escape special characters)
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('DESCRIPTION/How do I do \(anything\)\?');
ok $parser->parse_string_document($pod);
ok $out, q{=head2 How do I do (anything)?

Have you looked at CPAN (see L<perlfaq2>)?  The chances are that
someone has already written a module that can solve your problem.
Have you read the appropriate man pages?  Here's a brief index:

        Basics          perldata, perlvar, perlsyn, perlop, perlsub
        Execution       perlrun, perldebug

};

# Select some paragraphs at heading level 2
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('/.*Perl.*');
ok $parser->parse_string_document($pod);
ok $out, q{=head2 Is there a Perl shell?

In general, no.  The Shell.pm module (distributed with Perl) makes
Perl try commands which aren't part of the Perl language as shell
commands.

=head2 Is there an IDE or Windows Perl Editor?

Perl programs are just plain text, so any editor will do, but check
the following:

=over 4

=item CodeMagicCD

http://www.codemagiccd.com/

=item Komodo

ActiveState's cross-platform, multi-language IDE has Perl support.

=back

};

# Match all top level sections but none of their subsections:
ok $parser = Pod::Simple::Select->new;
$out = '';
ok $parser->output_string( \$out );
ok $parser->select('/!.+');
ok $parser->parse_string_document($pod);
ok $out, q{=head1 NAME

perlfaq3 - Programming Tools

=head1 DESCRIPTION

This section of the FAQ answers questions related to programmer tools
and programming support.

=head1 COPYRIGHT

Copyright (c) 1997-1999

};


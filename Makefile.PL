# This -*- perl -*- script writes the Makefile for Pod::Simple
#

use strict;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME          => 'Pod::Simple',
    VERSION_FROM  => 'lib/Pod/Simple.pm',
    ABSTRACT_FROM => 'lib/Pod/Simple.pod',
    TEST_REQUIRES => {
        'Test::More'  => '0.88'
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Config'          => 0,
        'Cwd'             => 0,
        'File::Basename'  => 0,
        'File::Find'      => 0,
        'File::Spec'      => 0,
        'Pod::Escapes'    => '1.04',
        'Symbol'          => 0,
        'Text::Wrap'      => '98.112902',
        'if'              => 0,
        'integer'         => 0,
        'overload'        => 0,
        'strict'          => 0,
        'warnings'        => 0,
    },

    INSTALLDIRS => $] >= 5.009003 && $] <= 5.011000 ? 'perl' : 'site',

    LICENSE    => 'perl',
    AUTHOR     => 'Allison Randal <allison@perl.org>',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            homepage   => 'https://metacpan.org/pod/Pod::Simple',
            license    => 'http://dev.perl.org/licenses/',
            repository => {
                url  => 'https://github.com/perl-pod/pod-simple.git',
                web  => 'https://github.com/perl-pod/pod-simple',
                type => 'git',
            },
            bugtracker => {
                web    => 'https://github.com/perl-pod/pod-simple/issues',
                mailto => 'bug-pod-simple@rt.cpan.org',
            },
            x_MailingList => 'https://lists.perl.org/list/pod-people.html',
        },
        prereqs => {
            runtime => {
                recommends => {
                    'Encode' =>
                        '2.78',  # Pod::Simple's new default code page (1252) is
                        # pre-compiled in 2.78, which improves performance.
                },
            },
        },
    },

);

unless ( eval { ExtUtils::MakeMaker->VERSION('6.63_03') } ) {
  $WriteMakefileArgs{BUILD_REQUIRES} = {
      %{ delete $WriteMakefileArgs{TEST_REQUIRES} || {} },
      %{ $WriteMakefileArgs{BUILD_REQUIRES} || {} },
  };
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_01') } ) {
  $WriteMakefileArgs{PREREQ_PM} = {
      %{ delete $WriteMakefileArgs{BUILD_REQUIRES} || {} },
      %{ $WriteMakefileArgs{PREREQ_PM} || {} },
  };
}

WriteMakefile(%WriteMakefileArgs);

package MY;

sub libscan {           # Determine things that should *not* be installed
    my ( $self, $path ) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__

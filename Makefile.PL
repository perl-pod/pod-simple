# This -*- perl -*- script writes the Makefile for Pod::Simple
#
# Time-stamp: "2004-05-24 00:21:20 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5;

use strict;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
    NAME          => 'Pod::Simple',
    VERSION_FROM  => 'lib/Pod/Simple.pm',
    ABSTRACT_FROM => 'lib/Pod/Simple.pod',
    TEST_REQUIRES => {
        'Sub::Util' => 1.55,

        # RT#29439
        'Test' => 1.25,
    },
    PREREQ_PM => {
        'Text::Wrap'   => '98.112902',
        'Pod::Escapes' => '1.04',

        # And finally, things I don't have any particular version in mind for:
        map { ; $_ => 0 } qw[
            File::Spec File::Basename Cwd Config Carp overload Symbol strict
            if integer File::Find Test::More
            ]
    },

    INSTALLDIRS => $] >= 5.009003 && $] <= 5.011000 ? 'perl' : 'site',

    LICENSE    => 'perl',
    AUTHOR     => 'Allison Randal <allison@perl.org>',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            homepage   => 'http://search.cpan.org/dist/Pod-Simple/',
            license    => 'http://dev.perl.org/licenses/',
            repository => {
                url  => 'git://github.com/perl-pod/pod-simple.git',
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
                        2.78,  # Pod::Simple's new default code page (1252) is
                        # pre-compiled in 2.78, which improves performance.
                },
            },
        },
    },

);

package MY;

sub libscan {           # Determine things that should *not* be installed
    my ( $self, $path ) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__

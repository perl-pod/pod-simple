# This -*- perl -*- script writes the Makefile for Pod::Simple
#
# Time-stamp: "2003-11-01 21:15:13 AST"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5;

use strict;
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME		=> 'Pod::Simple',
     VERSION_FROM	=> 'lib/Pod/Simple.pm',
     ABSTRACT_FROM	=> 'lib/Pod/Simple.pod',
     PREREQ_PM	  	=> {
			     'Text::Wrap' => '98.112902',
			     'Pod::Escapes' => '1.03',
			   },
     # INSTALLDIRS        => 'perl',
    );


package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__

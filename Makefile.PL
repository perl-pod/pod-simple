# This -*- perl -*- script writes the Makefile for Pod::Simple
#
# Time-stamp: "2003-09-01 22:39:09 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5.006;  # because of all our utf8 stuff.

use strict;
use ExtUtils::MakeMaker;

WriteMakefile
    (
     NAME		=> 'Pod::Simple',
     VERSION_FROM	=> './lib/Pod/Simple.pm',
     ABSTRACT_FROM	=> './lib/Pod/Simple.pod',
     PREREQ_PM	  	=> {
			     'Text::Wrap' => '98.112902',
			     'Pod::Escapes' => '1.03',
			     'utf8' => '0',
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

# This -*- perl -*- script writes the Makefile for Pod::Simple
#
# Time-stamp: "2004-05-24 00:21:20 ADT"
#
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#

require 5;

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME		=> 'Pod::Simple',
  VERSION_FROM	=> 'lib/Pod/Simple.pm',
  ABSTRACT_FROM	=> 'lib/Pod/Simple.pod',
  # INSTALLDIRS        => 'perl',
  PREREQ_PM	  	=> {
   'Text::Wrap' => '98.112902',
   'Pod::Escapes' => '1.04',

   # And finally, things I don't have any particular version in mind for:
   map {; $_ => 0 } qw[
    File::Spec File::Basename Cwd Config Carp overload Symbol strict
    constant integer File::Find
   ]
  },
);


package MY;

sub libscan
{ # Determine things that should *not* be installed
    my($self, $path) = @_;
    return '' if $path =~ m/~/;
    $path;
}

__END__

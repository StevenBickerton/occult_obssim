#!/usr/bin/env perl
#
# original filename: TNO_Rmag.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed Apr 23, 2008  11:29:52 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/sandbox/analysis
#


use strict;
use warnings;
use File::Basename;

use OccSim::Constants;
use OccSim::Astrotools;

my $exe = basename($0);
my $usage = "Usage: $exe rad d_earth d_sun albedo phase G\n";

my ($rad, $d_earth, $d_sun, $albedo, $phase, $G) = @ARGV;
die $usage unless $albedo;

$phase = 0.0 unless $phase;
$G = 0.0 unless $G;

printf STDOUT "%.3f\n", reflectedVmag($rad, $d_earth, $d_sun, $albedo, $PI*$phase/180.0, $G);

exit 0;

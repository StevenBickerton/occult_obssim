#!/usr/bin/env perl
#
# original filename: getElong.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Jul 17, 2006  16:05:57 DST
#  Host: kuiper
#  Working Directory: /1/home/bickersj/sandbox/analysis
#

use strict;
use warnings;
use File::Basename;

use OccSim::Constants;
use OccSim::Astrotools;

my $exe = basename $0;
my $usage = "usage: $exe alpha delta date [time 1AM assumed]\n".
    "   eg. $exe 06:08:54.0 24:20:00.0 2005-12-02 02:00:00\n";
my ($alpha, $delta, $date, $time)  = @ARGV;
die $usage unless defined($date);

$time = "00:00:00" unless $time;

# get the julian day
my ($yr, $mon, $mday) = split /-/, $date;
my ($hr, $min, $sec) = split /:/, $time;
my $JD = calendar2JD($yr, $mon, $mday, $hr, $min, $sec);

# put the RA Dec into degrees format
my ($alphaD,$deltaD) = hms2degRADec($alpha,$delta);

# get the elongation
my $elong = getElongOfCoordsAtDate($alphaD, $deltaD, $JD);
my $elongReduced = ($elong>180.0) ? (360.0 - $elong) : $elong;

my ($lambda, $beta) = eq2ecl($alphaD, $deltaD, $JD);

# output the answer.
printf STDOUT "%.3f  (%.3f)  ecl-latitude: %.3f\n", $elong, $elongReduced, $beta;

exit 0;

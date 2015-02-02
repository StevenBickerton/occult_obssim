#!/usr/bin/env perl
#
# original filename: evalTarget.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Mon Jun 16, 2008  19:52:05 DST
#  Host: bender.astro.princeton.edu
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

my $exe = basename($0);
my $usage = 
  "Usage: $exe dist Av Ebmv lamlo lamhi aper QE rdnoise Hz photfile RA:dec:V:BmVcol FOV IOCOpowerform Nrun prefix\n";

#   1      2   3     4      5      6   7   8       9        0     1
my ($dist,$Av,$Ebmv,$lamlo,$lamhi,$ap,$QE,$rdnoise,$hz,$photfile,$columns,$FOV,$IOCOpowerform, $Nrun, $prefix) = @ARGV;
die $usage unless $FOV;
$Nrun = 0 unless $Nrun;
$IOCOpowerform = 0 unless $IOCOpowerform;
$prefix = "" unless $prefix;

my @AUs = (40,300);
# @AUs = (40);
# @AUs = (300);

my $cmd_makeStarDB = "./makeStarDB.pl $photfile $dist $Av $Ebmv $columns $FOV";
system($cmd_makeStarDB);

foreach my $AU (@AUs) {

  my $cmd_fresfile    = "./makeFresFiles.pl $dist $lamlo $lamhi $AU $Nrun";
  my $cmd_runkomplete = "./runKomplete.pl $dist $AU $hz $QE $rdnoise $Av $Ebmv $ap";
  my $cmd_getRate     = "./getRate.pl starDB.dat $dist $AU $ap $IOCOpowerform $prefix";
  my $cmd_fitRmin     = "./fitRminBmax.pl starDB.dat $dist $AU $ap $IOCOpowerform $prefix";
  my $cmd_getRates    = "./getRates.pl starDB.dat $dist $Av $AU $ap $IOCOpowerform $prefix";

  system($cmd_fresfile);
  system($cmd_runkomplete);
  #system($cmd_getRate); #depricated
  system($cmd_fitRmin);
  system($cmd_getRates);

}

exit 0;

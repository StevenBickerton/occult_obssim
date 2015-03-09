#!/usr/bin/env perl
#
# original filename: occrate.pl
#
# Steven Bickerton
#  Dept. of Astrophysical Sciences, Princeton University
#  bick@astro.princeton.edu
#  Created: Sun Feb  8, 2009  14:49:52 EST
#  Host: bender.astro.Princeton.EDU
#  Working Directory: /Users/bick/usr/src/analysis
#


use strict;
use warnings;
use File::Basename;
use Getopt::Std;

use OccSim::Constants;
use OccSim::Astrotools;
use OccSim::KBOdensity;
use OccSim::MBAdensity;
use OccSim::IOCOdensity;
use OccSim::Elong2v;

my $exe = basename($0);
my $usage = "Usage: $exe [options] lambda\n".
    "\n".
    "Options:\n".
    "  -r rad            - minimum occulter radius in Fsu\n".
    "  -s                - suppress header\n".
    "\n";

my %opt;
getopts("e:i:l:r:s", \%opt);

#my ($lambda) = @ARGV;
#die $usage unless $lambda;

my $lambda = ($opt{l}) ? $opt{l} : 5.5e-7;
my $elong_deg = ($opt{e}) ? $opt{e} : 180.0;
my $elong = $RAD * $elong_deg;
my $i = ($opt{i}) ? $RAD*$opt{i} : $RAD*0.0;
my $rad_fsu = ($opt{r}) ? $opt{r} : 0.5;

my %AU = ('OCO' => 300.0, 'KBO' => 40.0, 'MBA' => 2.5);

my ($q_kbo, $q_doh_kbo, $rknee_kbo) = (4.8, 2.35, 25000.0);
my ($Sigma_mba, $alpha_mba) = (210.0, 0.27);

# print a header
unless ($opt{s}) {
    printf STDOUT "# lambda=$lambda elong=$elong_deg incl=$i radius=$rad_fsu Fsu\n";
    printf STDOUT "#%-11s %12s %12s %12s\n", "Quant.", "OCO", "KBO", "MBA";
}


my %mu;
foreach my $pop ( keys %AU ) {
    
    my $AU = $AU{$pop};
    my $d = r2D($AU,$elong);
    my $fsu = sqrt($lambda*$d*$AU_M/2.0);
    my $b = 3.4 * $fsu;
    my $v = elongi2v($elong, $i, $AU);
    
    my $rad = $rad_fsu * $fsu;

    my $sigma;
    if ($pop =~ /OCO/) {
        $sigma = (IOCOdensity($rad))[0];
    } elsif ($pop =~ /KBO/) {
        $sigma = KBOdensity($rad, $rknee_kbo, $q_kbo, $q_doh_kbo);
    } elsif ($pop =~ /MBA/) {
        $sigma = MBAdensity($rad, $Sigma_mba, $alpha_mba);
    }
    $sigma *= 3600**2; # convert from arcsec^-2 to deg^-2
    
    $mu{$pop} = 2.0*$b*$v*$sigma * (180.0/($PI*$AU*$AU_M))**2;
    
}

# print the Fsu at each distance
printf STDOUT "%-12s ", "Fsu(m)";
foreach my $pop ( keys %AU) {
    my $AU = $AU{$pop};
    my $d = r2D($AU, $elong);
    printf STDOUT "%12.1f ", sqrt($lambda*$d*$AU_M/2.0);
}
printf STDOUT "\n";

# print the radius at each distance
printf STDOUT "%-12s ", "radius(m)";
foreach my $pop ( keys %AU) {
    my $AU = $AU{$pop};
    my $d = r2D($AU, $elong);
    printf STDOUT "%12.1f ", $rad_fsu*sqrt($lambda*$d*$AU_M/2.0);
}
printf STDOUT "\n";

# print the rate per second
printf STDOUT "%-12s ", "rate(s^-1)";
foreach my $pop ( keys %AU ) {
    printf STDOUT "%12.3g ", $mu{$pop};
}
printf STDOUT "\n";

# .. rate per year
printf STDOUT "%-12s ", "rate(yr^-1)";
foreach my $pop ( keys %AU ) {
    printf STDOUT "%12.3g ", $SECperYR*$mu{$pop};
}
printf STDOUT "\n";


# expectation time (sec)
printf STDOUT "%-12s ", "t_exp(s)";
foreach my $pop ( keys %AU ) {
    printf STDOUT "%12.3g ", 1.0/$mu{$pop};
}
printf STDOUT "\n";

# expectation time (yr)
printf STDOUT "%-12s ", "t_exp(yr)";
foreach my $pop ( keys %AU ) {
    printf STDOUT "%12.3g ", 1.0/$mu{$pop}/$SECperYR;
}
printf STDOUT "\n";

exit 0;

#!/usr/bin/env perl
#
# original filename: apOccRate.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Wed May 21, 2008  1:45:25 DST
#  Host: bender.local
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::Stardata;
use Local::KBOdensity;
use Local::Elong2v;

my $exe = basename($0);
my $usage = "Usage: $exe dist AU hz QE rdnoise Av Ebmv ap1 ap2 ap3 ...\n";

my ($dist, $AU, $hz, $QE, $rdnoise, $Av, $Ebmv, @apertures) = @ARGV;
die $usage unless $hz;

my $Evmr = 0.5*$Ebmv; # total kluge

my ($elong, $incl) = (180.0, 0.0);
my $photon_min = 5.0;
my $AUstr = sprintf "%04d", $AU;

my ($cyc, $nCyc, $corTh, $chiTh, $Noff, $norm) = (1, 10, 8.0, 2.0, 25, 0);

my $lambda = 5.5e-7; # hate to hardcode this, but we're using B+V after all.
my $fsu = sqrt($lambda*$AU*$AU_M/2.0);
my $vRet = elongi2v($RAD*$elong, $RAD*$incl, $AU);
my $event_duration = 3.4*$fsu/$vRet;    # duration of each event (seconds)
my $ts_duration = 1.0*20.0*($nCyc*$cyc)*$event_duration;  # use a 5% fill factor to avoid crowding


#my @apertures = map {0.01*(10 + 1.0*$_)} (1 .. 20);
#@apertures = (0.10, 0.15, 0.20, 0.30);

my @mktypes = ();
foreach my $mk ( glob("[OBAFGKM][0-9]V") ) {
  push @mktypes, [$mk, $star{$mk}{Teff}];
}
@mktypes = sort {$b->[1] <=> $a->[1]} @mktypes;


# - loop over each star 
foreach my $ref ( @mktypes ) {

  my ($mk, $Teff) = @$ref;
  
  my $Mv  = $star{$mk}{'Mv'};
  my $BmV = $star{$mk}{'BmV'};
  my $VmR = $star{$mk}{'VmR'};
  my $Mb  = $Mv + $BmV;
  my $Mr  = $Mv - $VmR;
  my $Ab = $Av + $Ebmv;
  my $Ar = $Av - $Evmr;

  my $distmod = 5.0*log10($dist) - 5.0;
  my $V = $Mv + $distmod + $Av;
  my $B = $Mb + $distmod + $Ab;
  my $R = $Mr + $distmod + $Ar;
  my $fluxB = mag2flux('B', $B); # phot per sec per m^2
  my $fluxV = mag2flux('V', $V);
  my $fluxR = mag2flux('R', $R);
  my $flux = $QE * ($fluxB + $fluxV + $fluxR);

  my $star_dir = $mk;
  chdir $star_dir;
  
  foreach my $aperture (@apertures) {
    
    # -- skip it unless enough flux to bother
    my $area = $PI * ($aperture/2.0)**2;
    my $photons = $flux * $area / $hz;
    next unless $photons > $photon_min;

    # -- get rms and make the timeseries
    my $rms = 1.0 / sqrt($photons);
    my $dt = 1.0 / $hz;
    my $Np = $ts_duration*$hz + 4096;

    my $binw = 20.0;
    #my $kernel = 'gauss';
    my $basename = sprintf "ts%05.3f", $aperture;
    my $rawfile = $basename . ".data";
    my $smthfile = $basename . ".norm.fits";
    my $tsfile = $basename . ".${AUstr}.fits";

    my $COUNTS= sprintf "%d", 1.0/$rms**2;
    my $TMAX = $dt*$Np;
    my $ts_cmd = "ran_poisson $COUNTS $Np $TMAX > $rawfile";
    print STDERR $ts_cmd."\n";
    system($ts_cmd);

    my $smth_cmd = "fftSmooth -b $rawfile 1:2 $binw";
    print STDERR $smth_cmd."\n";
    system($smth_cmd);
    rename $smthfile, $tsfile;
    
    # -- run komplete
    my $komppars = "params.komp";
    open(KPAR, ">$komppars");
    printf KPAR "# cyc NperCyc corrThr chiThr fresDir Noffset norm\n";
    printf KPAR "$cyc $nCyc $corTh $chiTh fresnelFiles${AUstr} $Noff $norm\n";
    close(KPAR);

    my $komp_cmd = "komplete -r $rdnoise $elong $incl $komppars $tsfile";
    system($komp_cmd);

  }
  chdir "../";

}

exit 0;

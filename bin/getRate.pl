#!/usr/bin/env perl
#
# original filename: getRate.pl
#
# Steven Bickerton
#  Dept. of Physics/Astronomy, McMaster University
#  bick@physics.mcmaster.ca
#  Made with makeScript, Thu May 22, 2008  10:51:24 DST
#  Host: captive-wireless-250-139.ncsa.uiuc.edu
#  Working Directory: /Users/bick/working/aperture_test
#


use strict;
use warnings;
use File::Basename;

use Local::Constants;
use Local::Astrotools;
use Local::KBOdensity;
use Local::IOCOdensity;
use Local::Elong2v;
use Local::Stardata;

my $exe = basename($0);
my $usage = "Usage: $exe stardb dist AU aperture OCOpowerform prefix\n";

my ($stardb, $dist, $AU0, $ap, $OCOpowerform, $prefix) = @ARGV;
die $usage unless $ap;
my $AUstr = sprintf "%04d", $AU0;
$OCOpowerform = 0 unless $OCOpowerform;

my $number = '[+-]?\d+\.?\d*[eE]?[+-]?\d+?';
my ($prefix_title, $prefix_entry);
if ($prefix) {
  ($prefix_title, $prefix_entry) = $prefix =~ /^(.*)($number)$/;
} else {
  ($prefix_title, $prefix_entry) = ('--', -1);
  $prefix = "";
}

die "OCOpowerform must be 0 (broken) or 1 (uniform)\n" 
  unless $OCOpowerform=~/^[01]$/;


my ($elong, $incl) = (180.0, 0.0);
my ($q, $q_doh, $rknee) = (4.6, 3.0, 25000.0);
my $min_nonzero = 20; #min # of nadd!=0 in .stat file
my ($lam) = 5.5e-7;
my $fsu = sqrt($lam * $AU0 * $AU_M/2.0);

# count the number of each star
my %mk;
open(STARDB, "$stardb");
while(<STARDB>) {
  next if /^\#/;
  my ($mk, $V, $BmV, $Teff, $Mv, $Rstar_rad, $flux) = split;
  if (-d "$mk") {
    if ($mk{$mk}) {
      $mk{$mk} += 1;
    } else {
      $mk{$mk} = 1;
    }
  }
}
close(STARDB);

my $header = sprintf "#%2s %5s %5s %7s %6s ".
  "%5s %10s  %4s %10s %7s  %4s %6s %6s %9s %9s  %5s %4s  %6s".
  "\n", "MK", "Teff", "Code", "RMS", "R*_Fsu",
  "aper", "rate1", "Nmk", "rateN", "rateN/y", "AU", "bmax", "rmin", "n_m2", "nSas", "vRet", "fsu", "$prefix_title";
print STDOUT $header;


# get the rates
my %outstrings;
my %rates;
my %n;
my %mklimit;

my @mktypes = ();
foreach my $mk ( glob("[OBAFGKM][0-9]V") ) {
  push @mktypes, [$mk, $star{$mk}{Teff}];
}
@mktypes = sort {$b->[1] <=> $a->[1]} @mktypes;

foreach my $ref ( @mktypes ) {

  my ($mk, $Teff) = @$ref;
  chdir $mk;

  foreach my $tsfile ( glob("ts*.fits") ) {

    my ($aperture, $AUts) = $tsfile =~ /ts(\d\.\d\d\d).(\d\d\d\d).fits/;
    next unless $aperture =~ /$ap/ and $AUts =~ /$AU0/;
    

    my ($dummy, $dummy2, $rms) = split /\s+/, `cstats -rs $tsfile`;
    my $Rstarproj = $AU0 * $AU_M * ($star{$mk}{'R'} * $Ro_M) / ($dist * $PC_M);
    my $RstarFsu = $Rstarproj / $fsu;

    # -- get b_max and r_min from .stat file
    my $statfile = ${tsfile}.".stats";
    my $nonzero = 0;
    open(STAT, "$statfile");
    while(<STAT>) {
      next if /^\#/;
      my @line = split;
      $nonzero += 1 if $line[4] > 0;
    }
    close(STAT);
    
    my ($rmin, $bmax, $vret, $rwid, $bwid, $r0, $b0, $recov_frac, $s, $rbreak)= 
      (-1, 0.0, 0.0, 0.0, 0.0, -1, 0.0, 0.0, 1.0, -1);
    if ($nonzero > $min_nonzero) {
      my $rb_cmd = "rmin_bmax_from_stats $statfile";
      ($rmin, $bmax, $vret, $rwid, $bwid, $r0, $b0, $recov_frac, $s, $rbreak) = split /\s+/, `$rb_cmd`;
    }
    
    # -- get the surface density for that size
    my $vRet = elongi2v($RAD*$elong, $RAD*$incl, $AU0);

    # -- get the 63 percent wait time
    my ($mu, $nSas, $n_ms) = (0.0, 0.0, 0.0);
    if ( $bmax =~ /$number/ and $rmin=~/$number/ and $rmin > 0 ) {

      # integrate the values  for the kUIPER BELT
      if ( abs($AU0 - 40.0) < 1 ) {
	$nSas = KBOdensity($rmin, $rknee, $q, $q_doh);
	my $nSas_prev = $nSas;
	my $n_rbin = 20;
	my $rmax = 2000.0 + 10.0*$rmin;
	my $b = $bmax;
	for my $i (1 .. $n_rbin) {
	  my $r = $i*($rmax-$rmin)/$n_rbin;
	  my $nSas_tmp = KBOdensity($r, $rknee, $q, $q_doh);
	  my $dnSas = $nSas_prev - $nSas_tmp;
	  my $dn_ms = $dnSas * (206265.0**2) / ($AU0 * $AU_M)**2 ;
	  $b = ($r < $rbreak) ? $bmax : $bmax + $s*($r-$rbreak);
	  $mu += 2.0 * $b * $vRet * $dn_ms * $recov_frac;
	  $nSas_prev = $nSas_tmp;
	}
	# add on something for all objects larger than $rmax
	$mu += 2.0 * $b * $vRet * KBOdensity($rmax, $rknee, $q, $q_doh) * 
	  (206265.0**2) / ($AU0 * $AU_M)**2;

      # integrate the values for the INNER OORT CLOUD
      } elsif ( abs($AU0 - 300) < 1 ) {
	($nSas) = (IOCOdensity($rmin))[$OCOpowerform];
	my $nSas_prev = $nSas;
	my $n_rbin = 20;
	my $rmax = 2000.0 + 10.0*$rmin;
	my $b = $bmax;
	for my $i (1 .. $n_rbin) {
	  my $r = $i*($rmax-$rmin)/$n_rbin;
	  my $nSas_tmp = (IOCOdensity($r))[$OCOpowerform];
	  my $dnSas = $nSas_prev - $nSas_tmp;
	  my $dn_ms = $dnSas * (206265.0**2) / ($AU0 * $AU_M)**2 ;
	  $b = ($r < $rbreak) ? $bmax : $bmax + $s*($r-$rbreak);
	  $mu += 2.0 * $b * $vRet * $dn_ms * $recov_frac;
	  $nSas_prev = $nSas_tmp;
	}
	# add on something for all objects larger than $rmax
	$mu += 2.0 * $b * $vRet * 
	  ((IOCOdensity($rmax))[$OCOpowerform] *
	  (206265.0**2) / ($AU0 * $AU_M)**2;

      }

    } else {
      ($rmin, $bmax, $vret, $rwid, $bwid, $r0, $b0, $recov_frac, $s, $rbreak)= 
	(-1, 0.0, 0.0, 0.0, 0.0, -1, 0.0, 0.0, 1.0, -1);
    }
    

    $mk{$mk} = 0 unless $mk{$mk};
    $rates{$aperture} += $mu * $mk{$mk};

    $n{$aperture} = 0 unless $n{$aperture};
    $n{$aperture} += $mk{$mk} if ($mu > 0);

    $mklimit{$aperture} = 0 unless $mklimit{$aperture};
    $mklimit{$aperture} = $star{$mk}{'Mv'} 
      if ($mu > 0 and ( $mklimit{$aperture} < $star{$mk}{'Mv'} ));

    # print rms, Rstar(Fsu)
    my $outstring = sprintf "$mk %5d %5.2f %7.4f %6.1f ".
      "$aperture %10.4g  %4d %10.4g %7.4f  %4d %6.1f %6.1f %9.3g %9.3g  %5.0f %.0f  %6.2g".
      "\n", $star{$mk}{'Teff'}, $star{$mk}{'code'}, $rms, $RstarFsu, 
      $mu, $mk{$mk}, $mu*$mk{$mk}, $mu*$mk{$mk}*86400*365.24, $AU0, $bmax, $rmin, $n_ms, $nSas, $vRet, $rbreak, $prefix_entry;

    my $ratefile = sprintf "../${prefix}starRates_${AUstr}_${aperture}";
    if ( $outstrings{$aperture} and length($outstrings{$aperture}) > 10 ) {
      open(RATE, ">>$ratefile");
      print RATE $outstring;
      close(RATE);
      $outstrings{$aperture} .= $outstring;
    } else {
      open(RATE, ">$ratefile");
      print RATE $header;
      print RATE $outstring;
      close(RATE);      
      $outstrings{$aperture} .= $outstring;
    }
    print STDOUT $outstring;

  }
  chdir "../";
}

my $distmod = 5.0*log10($dist) - 5.0;

my $head2 = sprintf "#%4s %10s %4s %5s %4s %10s  %9s  %6s\n",
  "Aper", "rate", "n*", "Vlim", "AU", "n/s", "n/yr", "$prefix_title";
print STDOUT $head2;

my @apertures = sort keys %rates;
foreach my $aperture (@apertures) {

  open(FULLRATE, ">${prefix}rate_${AUstr}_$aperture");
  print FULLRATE $head2 if ($aperture eq $apertures[0]);
  my $line = sprintf "$aperture %10.4g %4d %5.2f %4d ".
    "%10.4g  %9.3f  %6.2g".
    "\n", $rates{$aperture}, $n{$aperture}, 
      $mklimit{$aperture} + $distmod, $AU0,
      1.0/$rates{$aperture}, $rates{$aperture}*86400*365.24, $prefix_entry;
  print FULLRATE $line;
  close(FULLRATE);

  print STDOUT $line;

}

exit 0;

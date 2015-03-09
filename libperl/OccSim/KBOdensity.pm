#!/usr/bin/env perl
# Perl Module:  KBOdensity.pm
#
# Purpose: a Perl module  containing a subroutine to get the density of KBOs
#               per sqr arcsec, given a minimum size and slope of the size dist
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Thurs.  Sep 22 2005
package  OccSim::KBOdensity;

use strict;
use warnings;
use Carp;

use OccSim::Constants;
use OccSim::Astrotools;

require  Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( KBOdensity KBOprobability expectationTime m2arcsec
                     maxDensity pMax DEffective KBOpoisProb expectTimePois
                     Dmean);
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;

######################################################################
sub KBOdensity ($$$$) {

    my ($r_min, $r_knee, $q, $q_doh) = @_;

    my $DMax       = 2.0*1160.0;   # diameter of Pluto
    my $Do         = 2.0*$r_min/1000.0;
    my $Dk         = 2.0*$r_knee/1000.0;

    my $c     = 2;       # const for r^(-c)  ie. slope of radial density
                         # not the speed of light
    my $Ro    = 23.1;    # zero-point mag of cum. lum. Func.
    my $r     = 40.0;    # distance to the kuiper belt in AU
    my $C     = 18.8;    # from Eq. 1 above
    my $S     = 1.0;     # area of sky under study (in sqr.degrees)
    
    my $rMax  = 50.0;    # most distant KBOs (AU)
    my $rMin  = 30.0;    # nearest KBOs (AU)
    
    my $alpha = ($q - 1.0)/5.0;  # a redefinition based on $q
    
    # equation numbers from Gladman et al. 2001, AJ 122 1051
    # need to integrate  n(r,D) dr dD = A r**(-c) D**(-q) dr dD   (eqn 4)

    # solve for the coefficient A  (eqn 9)
    my $x = 3.0 - 2.0*$q - $c;
    my $A = 5*$S*$alpha*10**($alpha*($C-$Ro))*$x / ($rMax**$x - $rMin**$x);
    
    # integral over the range in AU of the KB ==> int r^-c = r^(-c+1) / (-c+1)
    my $coefr = -$c+1.0;
    my $r_int = ( $rMax**$coefr - $rMin**$coefr ) / $coefr;
    
    # integral over the range in KBO size     ==> int D^-q = D^(-q+1) / (-q+1)
    my $coefD = 1.0 - $q;

    # $Do should actually be $Dk according to Gladman2001, but in this
    #   case, it represents any limiting point greater than the Diameter
    #   that defines the knee.
    my $D_int = $Do**($coefD) / (-$coefD);

    # this is more in keeping with Gladman 2001.
    my $D2_int = ( $Dk**($q_doh-$q) * $Do**(1.0-$q_doh) )/ (-$coefD);

    # put these together (choose which D_int to use depending on 
    #   whether we're asked for a point above or below the knee.
    my $n = $A * $r_int * ( ($r_knee<=$r_min) ? ($D_int) : ($D2_int) );   

    # $n is still in number/sqrDeg
    my $nSam = $n/3600.0;            # this is in number/sqrArcMin
    my $nSas = $nSam/3600.0;         # this in in number/sqrArcSec

    return $nSas;
}



sub DEffective ($$$$$$$) {
    my ($D,$AU,$lambda,$RStar,$Dk,$qL,$qS) = @_;   # D in metres
    my $fresnel_scale = sqrt($lambda*$AU*$AU_M/2.0);

    # from Nihei 2007
    #  - but with D transitioning between D and Dmean at 2Fsu
    my $Dmean = Dmean($D, $Dk, $qL, $qS);
    #trans x, a, b, x0, width
    #my $Dinterp = transition($D,$D,$Dmean,
    #2.0*$fresnel_scale,$fresnel_scale/1.0);
    my $Dinterp = $Dmean;
    my $r_fs = 0.5*$Dinterp/$fresnel_scale;
    my $RStar_fs = $RStar/$fresnel_scale;
    my $omega = 2.0 * ( (sqrt(3.0))**1.5 + $r_fs**1.5 )**(2.0/3.0) + 
      2.0*$RStar_fs;
    my $DEff = $omega*$fresnel_scale;

    return $DEff;
}


sub DEmpirical ($) {
    my ($D) = @_;  # D in metres

    my $r = $D/2.0;
    my $r_emp = 300.0 + 3.0*$r;

    my $D_emp = 2.0 * $r_emp;
    return $D_emp;
}

sub m2arcsec ($$) {

    my ($size, $distance_AU) = @_;  # size in metres, $dist in AU
    return  ($size / ($distance_AU*$AU_M) ) * $ARCSECperRAD;

}



# see my notes (pg 133) for details on probability calcs.
# see also pg 170 of notes for some changes.

sub KBOprobability ($$$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)

    my ($nSas, $Dmin, $vRet, $AU, $lambda, $t, $RStar) = @_;  

    my $DEff = DEmpirical($Dmin);
    #my $DEff = DEffective($Dmin,$AU,$lambda,$RStar);     # in metres
    my $DMinAS = m2arcsec($DEff, $AU);    # in arcsec
    
    
    my $ASperM = (1.0 * $ARCSECperRAD / ($AU * $AU_M));
    my $vRet_ASperS = $vRet* $ASperM;   # to as/s  x (as/km)
 
    ##  probabilities for a single object per sqr arcsec ##

    # Astrip in m^2
    my $Astrip = $DMinAS * $vRet_ASperS * 1.0;  # * 1.0 for 1.0 second
    my $Abox = 1.0;                             # arcsec^2
    my $p_1obj_1sec = $Astrip / $Abox;          # prob of occult in 1 second
    
    # prob of seeing nothing in 1 sec with 1 obj per sqr arcsec
    my $p_null_1obj_1sec = 1 - $p_1obj_1sec;   
    # prob of seeing nothing in 1 sec with n objects per square arcsec
    my $p_null_Nobj_1sec = $p_null_1obj_1sec**$nSas;
    # prob of seeing nothing in t sec
    my $p_null_Nobj_tsec = $p_null_Nobj_1sec**$t; 

    # prob of _not_ observing _nothing_ with N obj/sqr arcsec after t sec 
    #  ie.  the probability of 1 or more events
    my $p_oneOrMore_Nobj_tsec = 1 - $p_null_Nobj_tsec;     

    return $p_oneOrMore_Nobj_tsec;

}


sub expectationTime ($$) {

    # p       = probability per unit time
    # percent = confidence probability of something
    my ($p, $percent) = @_;

    # throw an error if necessary
    if ($percent < 0 or $percent > 1.0) {
        carp("percent: $percent not in range 0 < p < 1.0 ... using 0.95\n");
        $percent = 0.95;
    }

    # convert to the percent of seeing nothing.
    my $percent_nothing = 1.0 - $percent;
    

    # units here are time corresponding to units given for $p
    #  ie, if $p is prob/hour, then this is expected hours
    #  percent_nothing = (1-p)^n  (n is number of time units)
    my $expectationTime = log($percent_nothing) / log (1.0 - $p);

    return $expectationTime;
}



sub pMax ($$) {

    # t       = duration of observation (seconds)
    # percent = confidence probability of something

    my ($t, $percent) = @_;

    # throw an error if necessary
    if ($percent < 0 or $percent > 1.0) {
        carp("percent: $percent not in range 0 < p < 1.0 ... using 0.95\n");
        $percent = 0.95;
    }

    # convert to the percent of seeing nothing.
    my $percent_nothing = 1.0 - $percent;
    
    # units here are time corresponding to units given for $p
    #  ie, if $p is prob/hour, then this is expected hours
    #  percent_nothing = (1-p)^n  (n is number of time units)
    my $p = 1.0 - $percent_nothing**(1.0/$t);

    return $p;
}


# see my notes (pg 133) for details on probability calcs.
# see also pg 170 of notes for some changes.

sub maxDensity ($$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)

    my ($p_oneOrMore_Nobj_1sec, $Dmin, $vRet, $AU, $lambda, $RStar) = @_;  

    my $DEff = DEmpirical($Dmin);
    #my $DEff = DEffective($Dmin,$AU,$lambda,$RStar);     # in metres
    my $DMinAS = m2arcsec($DEff, $AU);    # in arcsec
    
    
    my $ASperM = (1.0 * $ARCSECperRAD / ($AU * $AU_M));
    my $vRet_ASperS = $vRet* $ASperM;   # to as/s  x (as/km)
 
    ##  probabilities for a single object per sqr arcsec ##

    # Astrip in m^2
    my $Astrip = $DMinAS * $vRet_ASperS * 1.0;  # * 1.0 for 1.0 second
    my $Abox = 1.0;                             # arcsec^2
    my $p_1obj_1sec = $Astrip / $Abox;          # prob of occult in 1 second
    
    # prob of seeing nothing in 1 sec with 1 obj per sqr arcsec
    my $p_null_1obj_1sec = 1.0 - $p_1obj_1sec;   
    my $p_null_Nobj_1sec = 1.0 - $p_oneOrMore_Nobj_1sec;

    # prob of seeing nothing in 1 sec with n objects per square arcsec
    #my $p_null_Nobj_1sec = $p_null_1obj_1sec**$nSas;
    my $nSas = log($p_null_Nobj_1sec) / log($p_null_1obj_1sec);

    return $nSas;

}



############  new calcs using Poisson stats ##################
sub KBOpoisProb ($$$$$$$) {
    
    # nSAS = number per square arcsec
    # Dmin = min diameter in metres
    # vRet = retrograd velocity (m/s)
    # AU   = semi-maj axis of KBO orbit in AU
    # t    = duration of observation (seconds)
    my ($nSas, $bmax, $vRet, $AU, $lambda, $t, $RStar) = @_; 

    my $bmaxAS = m2arcsec($bmax, $AU);
    my $vRetAS = m2arcsec($vRet, $AU);
    my $p = 1.0 - $EXP**(-2.0*$bmaxAS*$vRetAS*$t*$nSas);    
    return $p;
}


sub expectTimePois ($$$$$) {

    # bmax    = max detectable impact param (arcsec)
    # vRet    = retrograde velocity         (arcsec/sec)
    # nSas    = density  (arcsec^-2)
    # Pconf   = confidence probability of something
    my ($bmax, $vRet, $nSas, $AU, $Pconf) = @_;

    my $bmaxAS = m2arcsec($bmax, $AU);
    my $vRetAS = m2arcsec($vRet, $AU);

    # throw an error if necessary
    if ($Pconf < 0 or $Pconf > 1.0) {
        carp("percent: $Pconf not in range 0 < p < 1.0 ... using 0.95\n");
        $Pconf = 0.95;
    }

    my $expectationTime = log(1.0 - $Pconf) / (-2.0*$bmaxAS*$vRetAS*$nSas);
    return $expectationTime;
}

sub Dmean($$$$) {
  my ($Do, $Dk, $qL, $qS) = @_;

  my $tolerance = 1.0e-6;
  my $Dmean = $Do;
  if ( abs($qS - 2.0) < $tolerance ) {
      $Dmean = ( (1.0 - $qL) / (2.0 - $qL) + log($Dk/$Do) ) * $Do;
  } else {
      $Dmean = ( ( (1.0-$qL)/(2.0-$qL) - 
                   (1.0-$qS)/(2.0-$qS) )*($Do/$Dk)**($qS-2.0) +
                 (1.0-$qS)/(2.0-$qS) ) * $Do;
  }
  return $Dmean;
}

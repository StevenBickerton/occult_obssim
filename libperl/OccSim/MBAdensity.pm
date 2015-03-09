#!/usr/bin/env perl
#
#

package OccSim::MBAdensity;

use strict;
use warnings;
use Math::Trig;

#use Getopt::Long;
#   my ($q_small, $q_large, $r_break, $r_max, $mass, $width) =
#     (3.0, 4.5, 25, 2.5e3, 3.0, 45.0);
#   GetOptions(
# 	     "q_small:f" => \$q_small, # help=Slope of the small-size past break
# 	     "q_large:f" => \$q_large, # help=Slope of the large-size past break
# 	     "r_break:f" => \$r_break, # help=Break radius, in kilometers
# 	     "r_max:f" => \$r_max,     # help=Radius of largest object to consider
# 	     "mass:f" => \$mass,       # help="Mass of disk, in Earth masses"
# 	     "width:f" => \$width      # help="Width of the particle belt"
# 	    );
    

use OccSim::Constants;
use OccSim::Astrotools;
use OccSim::Elong2v;

require  Exporter;
our @ISA       = qw( Exporter );
our @EXPORT    = qw( MBAdensity );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


sub MBAdensity($$$) {

    my ($rad_mba, $Sigma, $alpha) = @_;

    my $VmR_mba = 0.4;
    my $albedo = 0.04;
    my $elong = $PI;
    my $r_orb_mba = 2.5;
    my $d_mba = r2D($r_orb_mba, $elong);
    my ($phase,$G) = (asin($d_mba/$r_orb_mba*sin($elong)), 0.2);
    my $mV_mba = reflectedVmag($rad_mba, $d_mba, $r_orb_mba, $albedo, $phase, $G);
    my $mR_mba = $mV_mba - $VmR_mba;
    my $nSd_mba = $Sigma * 10**($alpha * ($mR_mba-23.0));
    my $n_sas = $nSd_mba / 3600.0**2;

    return ($n_sas);
}
  

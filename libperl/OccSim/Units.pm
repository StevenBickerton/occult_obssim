#!/usr/bin/env perl
# Perl Module:  Units.pm
#
# Purpose: a Perl module  containing subroutines to take a value in standard
#          units, and convert it to an appropriate unit based on its magnitude.
#          (eg.  10^6 seconds = 11 days)
# Author: Steve Bickerton, McMaster University
#         bick@physics.mcmaster.ca
#         Fri. Sep. 23, 2005
# Functions:   timeUnits, distanceUnits, angleUnits
package  OccSim::Units;

use strict;
use warnings;

use Carp;
use Math::Trig;

use lib "$ENV{HOME}/libperl";
use OccSim::Constants;

require  Exporter;

our @ISA       = qw( Exporter );
our @EXPORT    = qw( timeUnits distanceUnits angleUnits massUnits dataUnits );
our @EXPORT_OK = qw();
our @EXPORT_TAGS = ( ALL => [ @EXPORT_OK ], );
our $VERSION   = 1.00;


#  private function ... decide how many decimals to use in the format
sub makeFormat ($) {
    
    my ($value) = @_;
    
    my ($low, $mid, $high) = (10.0,100.0,10000.0);
    
    my $format = "%d";
    if ($value < $low ) {
        $format = "%.2f";
    } elsif ($value >= $low && $value < $mid) {
        $format = "%.1f";
    } elsif ($value >= $mid && $value < $high) {
        $format = "%.0f";
    } elsif ($value >= $high) {
        $format = "%.1e";
    }

    return $format;
};




#  private function ... take the current units and convert them to a standard
sub convertToStandard ($$$) {
    
    my ($value, $unit_given, $ranges_ref) = @_;

    my $value_standard = $value;
    foreach my $unit_test (keys %$ranges_ref) {
        my %ranges = %$ranges_ref;
        my ($low, $high) = @{ $ranges{$unit_test} };	
        if ($unit_given eq $unit_test) {
            $value_standard = $value*$low;
        }
    }
    return $value_standard;
}


# private function ... decide which range the value is in and convert it.
sub convertToNewUnits ($$) {
    
    my ($value, $ranges_ref) = @_;

    my $string = "--";
    foreach my $unit (keys %$ranges_ref) {
        my %ranges = %$ranges_ref;
        my ($low, $high) = @{ $ranges{$unit} };	
        my $format = makeFormat($value/$low);
        (my $printUnit = $unit) =~ s/X//;
        
        $string = sprintf "$format %s", $value/$low, $printUnit
            # if its in between high and low
            if (  (  ($value >= $low)   &&  ( $value<$high )    ) ||
                  # if its above the highest value
                  (  ($value >= $low)   &&  ( $high<0      )    ) ||
                  # if its below the lowest value
                  (  ($value < $low )   &&  ( $unit=~/X$/  )    )     );
        
    }
    return $string;
}




# -------------------------------------------------------
#
# function: distanceUnits ()
#
# Purpose: To convert a value to a string with an appropriate distance unit
#          appended (based on order of magnitude).
#-----------------------------------------------


sub distanceUnits ($$) {

    my ($dist,$unit) = @_;


    if ($unit eq 'ly') {
        $dist /= $LYperPC;
        $unit = 'pc';
    }
    
    my %ranges = (
        fmX=> [1e-15,             1e-12       ],
        fm => [1e-15,             1e-12       ],
        pm => [1e-12,             1e-9        ],
        nm => [1e-9,              1e-6        ],
        um => [1e-6,              1e-3        ],
        mm => [1e-3,              1           ],
        m  => [1,                 1e3         ],
        km => [1e3,               1e11        ],
        AU  => [1e11,             $PC_M       ],
        pc  => [$PC_M,            1e3*$PC_M   ],
        kpc  => [1e3*$PC_M,       1e6*$PC_M   ],
        Mpc  => [1e6*$PC_M,       1e9*$PC_M   ],
        Gpc  => [1e9*$PC_M,       -1          ],
        );
    

    my $dist_m       = convertToStandard($dist, $unit, \%ranges);
    my $distString   = convertToNewUnits($dist_m, \%ranges);
    return $distString;
}


# -------------------------------------------------------
#
# function: angleUnits ()
#
# Purpose: To convert a value to a string with an appropriate angular unit
#          appended (based on order of magnitude).
#
#-----------------------------------------------


sub angleUnits ($$) {
    
    my ($angle, $unit) = @_;
    
    my %ranges = (		  
        uasX =>[1e-6,               1e-3          ],
        uas => [1e-6,               1e-3          ],
        mas => [1e-3,               1.0           ],
        as  => [1.0,                60.0          ],
        am  => [60.0,               3600.0        ],
        deg => [3600.0,             -1            ],
        rad => [206264.8062,        0             ],
        );
    
    # Note: radians has max=0 ... it can be used as input, but will never
    #    produce a 'success' on the output string test ... who thinks in rads?
    
    my $angle_ARCSEC     = convertToStandard($angle, $unit, \%ranges);
    my $angleString      = convertToNewUnits($angle_ARCSEC, \%ranges);
    return $angleString;
}


# -------------------------------------------------------
#
# function: timeUnits ()
#
# Purpose: To convert a value to a string with an appropriate time unit
#          appended (based on order of magnitude).
#
#-----------------------------------------------


sub timeUnits ($$) {

    my ($time, $unit) = @_;   # assumed in seconds

    my %ranges = (
        fsX=> [1e-15,             1e-12       ],
        fs => [1e-15,             1e-12       ],
        ps => [1e-12,             1e-9        ],
        ns => [1e-9,              1e-6        ],
        us => [1e-6,              1e-3        ],
        ms => [1e-3,              1           ],
        s  => [1,                 60          ],
        m  => [60,                3600        ],
        h  => [3600,              $SECperDAY  ],
        d  => [$SECperDAY,        $SECperWK   ],
        w  => [$SECperWK,         $SECperMONTH],
        l  => [$SECperMONTH,      $SECperYR   ],
        y  => [$SECperYR,         $SECperMYR  ],
        My => [$SECperMYR,        $SECperGYR  ],
        Gy => [$SECperGYR,        $HT_SEC ],
        HT => [$HT_SEC,           -1          ],
    );
    
    #print $unit. " " . $time. " ".$ranges{'w'}[0];
    my $time_s     = convertToStandard($time, $unit, \%ranges);
    my $timeString = convertToNewUnits($time_s, \%ranges);
    return $timeString;
}




# -------------------------------------------------------
#
# function: massUnits ()
#
# Purpose: To convert a value to a string with an appropriate mass unit
#          appended (based on order of magnitude).
#
#-----------------------------------------------


sub massUnits ($$) {

    my ($mass, $unit) = @_;   # assumed in seconds

    my %ranges = (
		  fgX=> [1e-15,             1e-12       ],
		  fg => [1e-15,             1e-12       ],
		  pg => [1e-12,             1e-9        ],
		  ng => [1e-9,              1e-6        ],
		  ug => [1e-6,              1e-3        ],
		  mg => [1e-3,              1           ],
		  g  => [1,                 1e3          ],
		  kg  => [1e3,              1e6        ],
		  T  => [1e6,               1e9         ],
		  kT  => [1e9,              $M1_CGS         ],
		  M1  => [$M1_CGS,          $Mc_CGS         ], # 1km ice ball
		  Mc  => [$Mc_CGS,          $Mm_CGS         ], # Ceres
		  Mm  => [$Mm_CGS,          $Me_CGS        ],  # Moon
		  Me  => [$Me_CGS,          $Mj_CGS        ],  # earth
		  Mj  => [$Mj_CGS,          $Mo_CGS        ],  # Jupiter
		  Mo  => [$Mo_CGS,          -1           ],
		  );

    my $mass_g     = convertToStandard($mass, $unit, \%ranges);
    my $massString = convertToNewUnits($mass_g, \%ranges);
    return $massString;
}




sub dataUnits ($$) {
    my ($data, $unit) = @_;
    my %ranges = (
        B   => [1,         2**10   ],
        KB  => [2**10,     2**20   ],
        MB  => [2**20,     2**30   ],
        GB  => [2**30,     2**40   ],
        TB  => [2**40,     2**50   ],
        PB  => [2**50,     2**60   ]
        );
    my $data_g     = convertToStandard($data, $unit, \%ranges);
    my $dataString = convertToNewUnits($data_g, \%ranges);
    return $dataString;
}




#!/usr/bin/env bash
#
# Steven Bickerton
# Dept. of Physics/Astronomy, McMaster University
# bick@physics.mcmaster.ca
# Made with makeScript, Tue May 20, 2008  18:41:17 DST
# Host: bender.local
# Working Directory: /Users/bick/working/aperture_test


function usage()
{
    echo "Usage: $0"
}

if [ $# -ne 0 ]; then
    usage
    exit 1;
fi

set -x


# target data
RAWPHOT=data/star_catalog.dat
Vcol=11
BmVcol=13
RAcol=18   #degrees
Deccol=19  #degrees

# target params
DIST=1100 # sarajedini 2004
Ebmv=0.255 #sung 1999
Av=0.79    # 3.1 * Ebmv

# scope params
HZ=50
THRU=0.7 # QE=0.85, other=0.85
RDNOISE=5 
LAMLO=4.0e-7
LAMHI=7.0e-7 # used only to make diffraction templates

# diameter of primary in metres
APERTURES="0.10 0.15 0.20 0.30 0.50 0.70 1.00 1.50 2.00"
#APERTURES="0.15 0.20 0.30 0.50"
APERTURES="0.17"

#FOVs="0.1 0.2 0.3 0.4"
FOVs="0.4"
FOV="0.4"

RDNOISEs="1 10 20 30 40 50"
RDNOISEs="10"

IOCOpowerform=0 # 0 broken (pessimistic), 1 uniform (optimistic)
Nrun=0

for RDNOISE in $RDNOISEs
do
    PREFIX="rdnoise${RDNOISE}"
    PREFIX="doh2.5"
    PREFIX=""
    for APER in $APERTURES
    do
        evalTarget.pl $DIST $Av $Ebmv $LAMLO $LAMHI $APER $THRU $RDNOISE $HZ $RAWPHOT $RAcol:$Deccol:$Vcol:$BmVcol $FOV $IOCOpowerform $Nrun $PREFIX
    done
done

 

#!/usr/bin/env bash

for f in $(seq 99)
do
    ff=$(printf "%02d" $f)
    B=bundle$ff
    if [ ! -d bundle$ff ]; then
        echo "Making directory $B"
        mkdir $B
        break
    fi
done

for f in [OBAFGKM][0-9]V *rate_* *starRates_* starDB.dat mk.dat
do
    echo "Bundling $f to $B"
    mv $f $B/
done


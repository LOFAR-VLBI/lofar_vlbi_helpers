#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=subtract --exclusive --constraint="rome|intel"

echo "Job landed on $(hostname)"

MS=$1

SIMG=$( python ../parse_settings.py --SIMG )
SING_BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $SING_BIND $SIMG /home/lofarvwf-jdejong/scripts/lofar-highres-widefield/utils/sub-sources-outside-region.py \
--boxfile boxfile.reg \
--column DATA_DI_CORRECTED \
--freqavg 1 \
--timeavg 1 \
--ncpu 24 \
--prefixname sub6asec \
--noconcat \
--keeplongbaselines \
--nophaseshift \
--chunkhours 0.5 \
--onlyuseweightspectrum \
--nofixsym \
--mslist $MS

mv sub6asec* ../

echo "SUBTRACT END"
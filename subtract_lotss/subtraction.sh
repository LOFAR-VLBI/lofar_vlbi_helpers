#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=subtract --exclusive --constraint="rome|intel"

echo "Job landed on $(hostname)"

MS=$1

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.3.4_x86-64_generic_avx512_ddfpublic.sif
SING_BIND=$( python $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $SING_BIND $SIMG /project/lofarvwf/Software/lofar_facet_selfcal/sub-sources-outside-region.py \
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
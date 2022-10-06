#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=subtract --exclusive

echo "Job landed on $(hostname)"

MS=$1

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG /home/lofarvwf-jdejong/scripts/lofar-highres-widefield/utils/sub-sources-outside-region.py \
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
--ddfbootstrapcorrection \
--onlyuseweightspectrum \
--mslist $MS

mv sub6asec* ../

echo "SUBTRACT END"
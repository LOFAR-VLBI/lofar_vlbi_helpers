#!/bin/bash
#SBATCH -c 6
#SBATCH --job-name=selfcal
#SBATCH --constraint=intel

#SINGULARITY SETTINGS
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts
SIMG=/home/lofarvwf-jdejong/singularities/lofar_sksp_v4.0.1_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

MSIN=$1

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_facet_selfcal/facetselfcal.py \
-i scalarphasediff \
--forwidefield \
--phaseupstations='core' \
--msinnchan=120 \
--avgfreqstep=2 \
--skipbackup \
--uvmin=20000 \
--soltype-list="['scalarphasediff']" \
--solint-list="['10min']" \
--nchan-list="[6]" \
--docircular \
--uvminscalarphasediff=0 \
--stop=2 \
--soltypecycles-list="[0]" \
--imsize=1600 \
--skymodelpointsource=1.0 \
--helperscriptspath=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal \
--helperscriptspathh5merge=/home/lofarvwf-jdejong/scripts/lofar_helpers \
--stopafterskysolve \
${MSIN}

#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=test_subtract

SING_IMAGE=/home/lofarvwf-jdejong/singularities/lofar_sksp_fedora31_ddf_fixed.sif
SING_BIND=/project/lofarvwf/Share/jdejong

MS_IN=$1

#singularity exec -B ${SING_BIND} ${SING_IMAGE} DPPP msin=${MS_IN} msout=avg_${MS_IN} steps=[av] msout.storagemanager=dysco steps=[av] av.type=averager av.freqstep=16 av.timestep=16
#singularity exec -B ${SING_BIND} ${SING_IMAGE} DPPP msin=sub6asec_${MS_IN} msout=avg_sub6asec_${MS_IN} steps=[av] msout.storagemanager=dysco steps=[av] av.type=averager av.freqstep=16 av.timestep=16

wsclean \
-no-update-model-required \
-minuv-l 80 \
-size 8192 8192 \
-reorder \
-weight briggs \
-0.5 clean-border 1 \
-parallel-reordering 4 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-pol i -use-wgridder \
-name testimage \
-scale 3arcsec \
-nmiter 10 \
-niter 100000 \
-maxuv-l 20e3 \
avg_${MS_IN}

wsclean \
-no-update-model-required \
-minuv-l 80 \
-size 8192 8192 \
-reorder \
-weight briggs \
-0.5 clean-border 1 \
-parallel-reordering 4 \
-mgain 0.75 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-pol i -use-wgridder \
-name testimage \
-scale 3arcsec \
-nmiter 10 \
-niter 100000 \
-maxuv-l 20e3 \
avg_sub6asec_${MS_IN}
#!/bin/bash

#TODO: add BDA

#SINGULARITY SETTINGS
SING_BIND=$PWD
SING_IMAGE_WSCLEAN=lofar_sksp_v4.0.1_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

OUT_DIR=DI0.3image
mkdir -p ${OUT_DIR}
cd ${OUT_DIR}

echo "Copy data..."

cp -r /net/rijn10/data2/jurjendejong/ELAIS/L816272/imaging/applieddata/applycal*.ms .

echo "...Finished copying"

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 45000 45000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 0.6asec_I \
-scale 0.2arcsec \
-taper-gaussian 0.6asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.6 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-mem 25 \
-channels-out 6 \
-join-channels \
-fit-spectral-pol 3 \
-deconvolution-channels 3 \
-j 30 \
-use-idg \
-grid-with-beam \
-use-differential-lofar-beam \
applycal*.ms

echo "----------FINISHED WSCLEAN----------"

echo "COMPLETED JOB"

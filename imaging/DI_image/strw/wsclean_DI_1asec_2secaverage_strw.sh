#!/bin/bash

#SINGULARITY SETTINGS
SING_BIND=$PWD
SING_IMAGE_WSCLEAN=/net/achterrijn/data1/sweijen/software/containers/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

OUT_DIR=DI1.2image
mkdir -p ${OUT_DIR}
cd ${OUT_DIR}

echo "Copy data"

#cp -r ../DD_1asec_old/DATA/* .
#cp -r ../DD_1asec_old/master_merged.h5 .


echo "...Finished copying"

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 3 \
-auto-threshold 1.0 \
-pol i \
-name 1.2asec_I \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 50000 \
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
-dd-psf-grid 3 3 \
bdaavg_applycal*.ms

echo "----------FINISHED WSCLEAN----------"

echo "COMPLETED JOB"

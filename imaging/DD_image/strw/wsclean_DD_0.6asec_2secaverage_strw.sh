#!/bin/bash

#SINGULARITY SETTINGS
SING_BIND=$PWD
SING_IMAGE_WSCLEAN=/net/achterrijn/data1/sweijen/software/containers/lofar_sksp_v4.0.2_x86-64_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

echo "Copy data"

cp -r DATA/* .

echo "...Finished copying"

echo "----------START WSCLEAN----------"

singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} \
wsclean \
-update-model-required \
-gridder \
-minuv-l 80.0 \
-size 45000 45000 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 0.6image \
-scale 0.2arcsec \
-taper-gaussian 0.6asec \
-niter 50000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions facets.reg \
-apply-facet-solutions master_merged.h5 amplitude000,phase000 \
-parallel-gridding 6 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 6 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
-dd-psf-grid 3 3 \
bdaavg*.ms

echo "----------FINISHED WSCLEAN----------"

echo "COMPLETED JOB"

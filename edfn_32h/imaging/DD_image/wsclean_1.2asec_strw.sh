#!/bin/bash

#SINGULARITY SETTINGS
#SING_BIND=/tmp,/dev/shm,/net/krommerijn,/net/nieuwerijn,/net/rijn,/net/rijn1,/net/rijn2,/net/rijn3,$
#SIMG=$( python3 $HOME/parse_settings.py --SIMG )

FACET=facets.reg

H5='merged_L816272.h5 merged_L686962.h5 merged_L769393.h5 merged_L798074.h5'
MS_VECTOR='L816272_concat.ms L686962_concat.ms L769393_concat.ms L798074_concat.ms'

echo "----------START WSCLEAN----------"

wsclean \
-update-model-required \
-gridder wgridder \
-minuv-l 80.0 \
-size 22500 22500 \
-weighting-rank-filter 3 \
-reorder \
-weight briggs -1.5 \
-parallel-reordering 6 \
-mgain 0.65 \
-data-column DATA \
-auto-mask 2.5 \
-auto-threshold 1.0 \
-pol i \
-name 1.2image \
-scale 0.4arcsec \
-taper-gaussian 1.2asec \
-niter 150000 \
-log-time \
-multiscale-scale-bias 0.7 \
-parallel-deconvolution 2600 \
-multiscale \
-multiscale-max-scales 9 \
-nmiter 9 \
-facet-regions ${FACET} \
-apply-facet-solutions ${H5// /,} amplitude000,phase000 \
-parallel-gridding 2 \
-mem 50 \
-apply-facet-beam \
-facet-beam-update 600 \
-use-differential-lofar-beam \
-channels-out 6 \
-deconvolution-channels 3 \
-join-channels \
-fit-spectral-pol 3 \
-dd-psf-grid 3 3 \
${MS_VECTOR}


echo "----FINISHED----"

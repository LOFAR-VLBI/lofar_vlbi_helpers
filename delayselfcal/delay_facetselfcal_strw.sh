#!/bin/bash

SIMG=/net/lofar1/data1/sweijen/software/LOFAR/singularity/lofar_sksp_ddf_rijnX.sif
BIND=/tmp,/dev/shm,/disks/paradata,/data1,/net/lofar1,/net/rijn,/net/nederrijn/,/net/bovenrijn,/net/botlek,/net/para10,/net/lofar2,/net/lofar3,/net/lofar4,/net/lofar5,/net/lofar6,/net/lofar7,/disks/ftphome,/net/krommerijn,/net/voorrijn,/net/achterrijn,/net/tussenrijn,/net/ouderijn,/net/nieuwerijn,/net/lofar8,/net/lofar9,/net/rijn8,/net/rijn7,/net/rijn5,/net/rijn4,/net/rijn3,/net/rijn2

MSIN=$1

singularity exec -B $BIND $SIMG \
wsclean \
-no-update-model-required \
-minuv-l 80.0 \
-size 1600 1600 \
-reorder \
-weight briggs -0.2 \
-clean-border 1 \
-parallel-reordering 4 \
-mgain 0.8 \
-data-column CORRECTED_DATA \
-padding 1.4 \ds9
-join-channels \
-channels-out 6 \
-auto-mask 2.5 \
-auto-threshold 0.5 \
-taper-gaussian 1.2arcsec \
-fit-spectral-pol 3 \
-pol i \
-baseline-averaging 6.135923151542564 \
-use-wgridder \
-name selfcal_allstations4_LBCS_phaseuptry1_1.2arcsectaper000 \
-scale 0.075arcsec \
-nmiter 12 \
-niter 15000 \
${MSIN}
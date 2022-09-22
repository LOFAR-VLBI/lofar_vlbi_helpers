#!/bin/bash

SIMG=/net/lofar1/data1/sweijen/software/LOFAR/singularity/lofar_sksp_ddf_rijnX.sif
BIND=/tmp,/dev/shm,/disks/paradata,/data1,/net/lofar1,/net/rijn,/net/nederrijn/,/net/bovenrijn,/net/botlek,/net/para10,/net/lofar2,/net/lofar3,/net/lofar4,/net/lofar5,/net/lofar6,/net/lofar7,/disks/ftphome,/net/krommerijn,/net/voorrijn,/net/achterrijn,/net/tussenrijn,/net/ouderijn,/net/nieuwerijn,/net/lofar8,/net/lofar9,/net/rijn8,/net/rijn7,/net/rijn5,/net/rijn4,/net/rijn3,/net/rijn2

MSIN=$1

singularity exec -B $BIND $SIMG \
python /net/rijn/data2/rvweeren/LoTSS_ClusterCAL/facetselfcal.py \
--imsize=1600 \
-i selfcal_round1_LBCS \
--pixelscale=0.075 \
--uvmin=20000 \
--skymodelpointsource=1.0 \
--soltype-list="['scalarphasediff','scalarphase','scalarcomplexgain']" \
--soltypecycles-list="[0,0,3]" \
--solint-list="['2min','32s','40min']" \
--nchan-list="[1,1,1]" \
--smoothnessconstraint-list="[5.0,0.75,10.0]" \
--antennaconstraint-list="['alldutch',None,None]" \
--forwidefield \
--avgfreqstep=5 \
--avgtimestep=4 \
--docircular \
--phaseupstations=core \
--skipbackup ${MSIN}

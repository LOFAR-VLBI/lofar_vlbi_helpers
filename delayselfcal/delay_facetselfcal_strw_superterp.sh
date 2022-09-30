#!/bin/bash

#COMPARE THIS OUTPUT WITH DELAY_FACETSELFCAL_STRW_6.SH

SIMG=/net/lofar1/data1/sweijen/software/LOFAR/singularity/lofar_sksp_ddf_rijnX.sif
BIND=/tmp,/dev/shm,/disks/paradata,/data1,/net/lofar1,/net/rijn,/net/nederrijn/,/net/bovenrijn,/net/botlek,/net/para10,/net/lofar2,/net/lofar3,/net/lofar4,/net/lofar5,/net/lofar6,/net/lofar7,/disks/ftphome,/net/krommerijn,/net/voorrijn,/net/achterrijn,/net/tussenrijn,/net/ouderijn,/net/nieuwerijn,/net/lofar8,/net/lofar9,/net/rijn8,/net/rijn7,/net/rijn5,/net/rijn4,/net/rijn3,/net/rijn2

MSIN=$1

singularity exec -B $BIND $SIMG \
python /net/rijn/data2/rvweeren/LoTSS_ClusterCAL/facetselfcal.py \
--imsize=1600 \
-i selfcal_round_superterp_LBCS \
--pixelscale=0.075 \
--uvmin=10000 \
--skymodelpointsource=0.22 \
--soltype-list="['scalarphasediff','scalarphase','scalarcomplexgain','complexgain','fulljones']" \
--soltypecycles-list="[0,0,1,1,1]" \
--solint-list="['8min','32s','20min','40min','80min']" \
--nchan-list="[1,1,1,1,1]" \
--smoothnessconstraint-list="[10.0,1.25,7.5,15.0,5.0]" \
--antennaconstraint-list="['alldutch',None,None,None,None]" \
--forwidefield \
--avgfreqstep=5 \
--avgtimestep=4 \
--docircular \
--phaseupstations='superterp' \
--useaoflagger \
--uvminscalarphasediff=0 \
--makeimage-ILTlowres-HBA \
--makeimage-fullpol \
--no-beamcor \
--stop=5 \
--skipbackup ${MSIN}

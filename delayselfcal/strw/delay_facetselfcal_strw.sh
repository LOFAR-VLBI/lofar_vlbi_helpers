#!/bin/bash

SIMG=$( python ../parse_settings.py --SIMG )
BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

MSIN=$1

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_facet_selfcal/facetselfcal.py \
--imsize=1600 \
-i selfcal_allstations4_LBCS_final \
--pixelscale=0.075 \
--uvmin=20000 \
--robust=-1.5 \
--uvminim=1500 \
--skymodel=7C1604+5529.skymodel \
--soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarphase','scalarcomplexgain','fulljones','scalarcomplexgain']" \
--soltypecycles-list="[0,0,0,0,0,0,0]" \
--solint-list="['8min','32s','32s','2min','20min','20min','40min']" \
--nchan-list="[1,1,1,1,1,1]" \
--smoothnessconstraint-list="[10.0,1.25,10.0,20.,7.5,5.0,7.5]" \
--normamps=False --smoothnessreffrequency-list="[120.,120.,120.,120,0.,0.,0.]" \
--antennaconstraint-list="['alldutch',None,None,None,None,'alldutch',None]" \
--forwidefield \
--avgfreqstep=5 \
--avgtimestep=4 \
--docircular \
--skipbackup \
--uvminscalarphasediff=0 \
--makeimage-ILTlowres-HBA \
--makeimage-fullpol \
--resetsols-list="[None,'alldutch','core',None,None,None,None]" \
--stop=1 \
${MSIN}
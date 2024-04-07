#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=dical -t 24:00:00

#############
#UPDATE THESE
SKYMODEL=/project/lofarvwf/Share/jdejong/output/ELAIS/7C1604+5529.skymodel
#############

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

#SCRIPTS
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )

singularity exec -B $SING_BIND $SIMG python $lofar_facet_selfcal \
--imsize=1600 \
-i selfcal_allstations_LBCS_4sets_default \
--pixelscale=0.075 \
--uvmin=20000 \
--robust=-1.5 \
--uvminim=1500 \
--skymodel=$SKYMODEL \
--soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarphase','scalarcomplexgain','fulljones','scalarcomplexgain']" \
--soltypecycles-list="[0,0,0,0,0,0,0]" \
--solint-list="['8min','32s','32s','2min','20min','20min','40min']" \
--nchan-list="[1,1,1,1,1,1]" \
--smoothnessconstraint-list="[10.0,1.25,10.0,20.,7.5,5.0,7.5]" \
--normamps=False \
--smoothnessreffrequency-list="[120.,120.,120.,120,0.,0.,0.]" \
--antennaconstraint-list="['core',None,None,None,None,'alldutch',None]" \
--forwidefield \
--avgfreqstep='488kHz' \
--avgtimestep='32s' \
--docircular \
--skipbackup \
--uvminscalarphasediff=0 \
--makeimage-ILTlowres-HBA \
--makeimage-fullpol \
--resetsols-list="[None,'alldutch','core',None,None,None,None]" \
--stop=1 \
--stopafterskysolve \
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers \
*.ms

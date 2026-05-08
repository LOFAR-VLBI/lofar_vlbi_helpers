#!/bin/bash
#SBATCH -c 16 -t 6:00:00

set -euo pipefail

######################
#### UPDATE THESE ####
######################

MSIN=$(realpath $1) #output MS from delay-calibration.cwl
SKYMODEL=$(realpath $2) #/project/lofarvwf/Share/jdejong/output/ELAIS/7C1604+5529.skymodel

######################
######################

RUNDIR=${TMPDIR}/dical_${SLURM_JOB_ID}
OUTDIR=${PWD}/dical

mkdir -p ${RUNDIR}
mkdir -p ${OUTDIR}

# ACCESS RUNDIR
cd $RUNDIR

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

# GET DATA
cp ${SKYMODEL} $RUNDIR
cp -r ${MSIN} $RUNDIR

# GET SOFTWARE
wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v5.4.1_znver2_znver2.sif

git clone https://github.com/rvweeren/lofar_facet_selfcal.git
cd lofar_facet_selfcal
git checkout c4688da
cd ..

# RUN SCRIPT
singularity exec -B $PWD flocs_v5.4.1_znver2_znver2.sif python lofar_facet_selfcal/facetselfcal.py \
--imsize=1600 \
-i DI_calibration \
--pixelscale=0.075 \
--uvmin=20000 \
--robust=-1.5 \
--uvminim=1500 \
--skymodel=${SKYMODEL##*/} \
--soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarphase','scalarcomplexgain','fulljones']" \
--soltypecycles-list="[0,0,0,0,0,0]" \
--solint-list="['8min','16s','32s','2min','20min','20min']" \
--nchan-list="[1,1,1,1,1,1]" \
--smoothnessconstraint-list="[10.0,1.25,10.0,20.,7.5,5.0]" \
--normamps=False \
--smoothnessreffrequency-list="[120.,120.,120.,120,0.,0.]" \
--antennaconstraint-list="['core',None,None,None,None,'alldutch']" \
--forwidefield \
--avgfreqstep='244kHz' \
--avgtimestep='16s' \
--docircular \
--skipbackup \
--uvminscalarphasediff=0 \
--makeimage-ILTlowres-HBA \
--makeimage-fullpol \
--resetsols-list="[None,'alldutch','core',None,None,None]" \
--stop=1 \
--stopafterskysolve \
$(basename ${MSIN})

# OUTPUT
rm -rf lofar_facet_selfcal
rm -rf lofar_helpers
rm -rf *.ms
rm *-000?-*
cp -r * $OUTDIR

#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=dical -t 10:00:00

##########################

#UPDATE THESE
SKYMODEL=/project/lofarvwf/Share/jdejong/output/ELAIS/7C1604+5529.skymodel
FACETSELFCAL=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal
LOFARHELPERS=/project/lofarvwf/Software/lofar_helpers

##########################

RUNDIR=$TMPDIR/dical_${SLURM_JOB_ID}
OUTDIR=$PWD
mkdir -p $RUNDIR

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

# COPY TO RUNDIR
cp $SIMG $RUNDIR
cp $SKYMODEL $RUNDIR
cp -r *.ms $RUNDIR
cp -r $FACETSELFCAL $RUNDIR
mkdir $RUNDIR/lofar_helpers
cp -r $LOFARHELPERS/h5_merger.py $RUNDIR/lofar_helpers

cd $RUNDIR

# RUN SCRIPT
singularity exec -B $PWD ${SIMG##*/} python lofar_facet_selfcal/facetselfcal.py \
--imsize=1600 \
-i DI_selfcal \
--pixelscale=0.075 \
--uvmin=20000 \
--robust=-1.5 \
--uvminim=1500 \
--skymodel=${SKYMODEL##*/} \
--soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarphase','scalarcomplexgain','fulljones']" \
--soltypecycles-list="[0,0,0,0,0,0]" \
--solint-list="['8min','32s','32s','2min','20min','20min']" \
--nchan-list="[1,1,1,1,1]" \
--smoothnessconstraint-list="[10.0,1.25,10.0,20.,7.5,5.0]" \
--normamps=False \
--smoothnessreffrequency-list="[120.,120.,120.,120,0.,0.]" \
--antennaconstraint-list="['core',None,None,None,None,'alldutch']" \
--forwidefield \
--avgfreqstep='488kHz' \
--avgtimestep='32s' \
--docircular \
--skipbackup \
--uvminscalarphasediff=0 \
--makeimage-ILTlowres-HBA \
--makeimage-fullpol \
--resetsols-list="[None,'alldutch','core',None,None,None]" \
--stop=1 \
--stopafterskysolve \
--helperscriptspath=$RUNDIR/lofar_facet_selfcal \
--helperscriptspathh5merge=$RUNDIR/lofar_helpers \
*.ms

# OUTPUT
rm -rf lofar_facet_selfcal
rm -rf lofar_helpers
rm -rf *.ms
rm *-000?-*
cp -r * $OUTDIR

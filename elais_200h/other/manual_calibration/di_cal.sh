#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=dical -t 10:00:00

##########################

#UPDATE THESE
SKYMODEL=/project/wfedfn/Share/petley/output/EDFN/delay_cal_models
BASENAME=J174713+653236_final_model
FACETSELFCAL=/project/wfedfn/Software/lofar_facet_selfcal
LOFARHELPERS=/project/wfedfn/Software/lofar_helpers

##########################

NAME=$1

RUNDIR=$TMPDIR/dical_${SLURM_JOB_ID}
OUTDIR=$PWD
mkdir -p $RUNDIR

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

# COPY TO RUNDIR
cp $SIMG $RUNDIR
cp $SKYMODEL/*-model.fits $RUNDIR
cp -r *.ms $RUNDIR
cp -r $FACETSELFCAL $RUNDIR
mkdir $RUNDIR/lofar_helpers
cp -r $LOFARHELPERS/h5_merger.py $RUNDIR/lofar_helpers

cd $RUNDIR


# Get channels out of averaged MS and pass to facetselfcal.py


# Python Script
# 1. Get the expected number of channels after averaging
# 2. Check the starting freq is 120.262 
# 3. If shifted add dummy.ms to go down to that value
# 4. If missing whole first block then relabel the model images

# RUN SCRIPT
singularity exec -B $PWD ${SIMG##*/} python lofar_facet_selfcal/facetselfcal.py \
--imsize=1600 \
-i DI_${NAME} \
--pixelscale=0.075 \
--uvmin=40000 \
--wscleanskymodel=${BASENAME} \
--channelsout=12 \
--fitspectralpol=9 \
--multiscale \
--robust=-1.5 \
--uvminim=1500 \
--soltype-list="['scalarphasediff','scalarphase','scalarphase','scalarcomplexgain','scalarcomplexgain','scalarcomplexgain','fulljones']" \
--soltypecycles-list="[0,0,0,0,0,0,0]" \
--solint-list="['4min','32s','32s','15min','4min','2hr','20min']" \
--nchan-list="[1,1,1,1,1,1,1]" \
--smoothnessconstraint-list="[15.0,1.5,10.0,10.,30.,2.0,5.0]" \
--normamps=False \
--smoothnessreffrequency-list="[120.,120.,120.,0.,0.,0.,0.]" \
--antennaconstraint-list="['alldutch',None,None,None,None,None,'alldutch']" \
--smoothnessspectralexponent-list="[-2,-1,-1,0,0,0,0]" \
--forwidefield \
--avgfreqstep='488kHz' \
--avgtimestep='32s' \
--docircular \
--skipbackup \
--useaoflagger \
--uvminscalarphasediff=0 \
--makeimage-fullpol \
--makeimage-ILTlowres-HBA \
--resetsols-list="[None,'alldutch','core',None,None,None,None]" \
--stopafterskysolve \
--stop=1 \
--fix-model-frequencies \
--helperscriptspath=$RUNDIR/lofar_facet_selfcal \
--helperscriptspathh5merge=$RUNDIR/lofar_helpers \
*.ms

# Other args
#--makeimage-fullpol \
#--stopafterskysolve \

# OUTPUT
rm -rf lofar_facet_selfcal
rm -rf lofar_helpers
rm -rf *.ms
cp -r * $OUTDIR

#!/bin/bash
#SBATCH -c 30

INP=$1 # for instance: ILTJ160559.98+545405.6

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )
lofar_helpers=$( python3 $HOME/parse_settings.py --lofar_helpers )
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --lofar_facet_selfcal )

mkdir -p $INP
cd $INP

for LNUM in L686906 L686920 L686934 L686948 L686962 L686976 L686990 L687004 L760853 L769393 L769407 L769421 L769435 L798074 L816272 L833466; do
 INP_FOLDER=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/${LNUM}/ddcal/splitdir_selection/outdir
 cp -r ${INP_FOLDER}/${INP}*.ms ${INP}_${LNUM}.ms
 singularity exec -B $BIND $SIMG python ${lofar_helpers}/ms_helpers/remove_flagged_stations.py --overwrite ${INP}_${LNUM}.ms
done

mkdir first_run
cp -r ILTJ*_L686962.ms first_run
cd first_run

singularity exec -B $BIND $SIMG \
python $facet_selfcal \
-i selfcal \
--skipbackup \
--imsize=1600 \
--resetsols-list="['alldutch',None,None]" \
--smoothnessreffrequency-list=[120.,120.,0.] \
--phaseupstations=core \
--soltype-list="['scalarphase','scalarphase','scalaramplitude']" \
--solint-list="['64sec','128sec','40min']" \
--nchan-list=[1,1,1] \
--smoothnessconstraint-list=[10.,30.,7.5] \
--soltypecycles-list=[0,0,3] \
--stop=11 \
--forwidefield \
--avgtimestep=2 \
--parallelgridding=6 \
--paralleldeconvolution=1024 \
--fitspectralpol=5 \
--multiscale \
--helperscriptspath=$lofar_facet_selfcal \
--helperscriptspathh5merge=$lofar_helpers \
ILTJ*_L686962.ms

cp selfcal_010*model.fits ../
cd ../

singularity exec -B $BIND $SIMG \
python $lofar_facet_selfcal \
-i selfcal \
--skipbackup \
--imsize=1600 \
--resetsols-list="['alldutch',None,None]" \
--smoothnessreffrequency-list=[120.,120.,0.] \
--phaseupstations=core \
--soltype-list="['scalarphase','scalarphase','scalaramplitude']" \
--solint-list="['64sec','128sec','40min']" \
--nchan-list=[1,1,1] \
--smoothnessconstraint-list=[10.,30.,7.5] \
--soltypecycles-list=[0,0,0] \
--stop=8 \
--forwidefield \
--avgtimestep=2 \
--parallelgridding=6 \
--paralleldeconvolution=1024 \
--fitspectralpol=5 \
--multiscale \
--wscleanskymodel=selfcal_010 \
--helperscriptspath=$lofar_facet_selfcal \
--helperscriptspathh5merge=$lofar_helpers \
ILTJ*_L??????.ms

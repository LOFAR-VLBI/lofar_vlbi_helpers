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
 singularity exec -B $BIND $SIMG python $lofar_helpers/ms_helpers/remove_flagged_stations.py --overwrite ${INP}_${LNUM}.ms
done


singularity exec -B $BIND $SIMG \
python $facet_selfcal \
-i selfcal \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--makeimage-fullpol \
--helperscriptspath=$lofar_facet_selfcal \
--helperscriptspathh5merge=$lofar_helpers \
*.ms

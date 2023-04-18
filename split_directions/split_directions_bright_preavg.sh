#!/bin/bash
#SBATCH -N 1 -c 5 --job-name=split_directions

#List with L-numbers --> TEXT FILE WITH L-NUMBERS FOR EACH LINE
L_LIST=$1
#Catalogue with sources --> FITS FILE WITH SOURCE CATALOGUE
CATALOG=$2

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers
export PROJPATH=/project/lofarvwf/Share/jdejong/output/ELAIS/
export RESULTS_DIR=$PWD
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.3_znver2_znver2_noavx512_aocl4_cuda_ddf.sif

echo "Job landed on $(hostname)"

echo "-----------------STARTED SPLIT DIRECTIONS-----------------"

while read -r LNUM; do

  # WHEN YOU RUN WITH SKYMODEL
  SOLUTIONS=${PROJPATH}/ALL_L/delayselfcal/merged_skyselfcalcyle000_linearfulljones_${LNUM}_120_168MHz_averaged.ms.avg.h5

  echo "Copy applycal ms"
  for MS in ${PROJPATH}/${LNUM}/subtract/subtract_lotss/sub6asec_${LNUM}*.ms; do

    #Make calibrator parsets
    singularity exec -B $PWD,/project $SIMG python ${SCRIPTS}/split_directions/make_directions_parsets.py \
    --catalog ${CATALOG} --prefix ${LNUM} --ms ${MS} --h5 ${SOLUTIONS} --brighter \
    --selection P35307 P50980 P40952 P27648 P31553 P54920 P22459 P44832 P50716 P52238 P53426 P37145 \
    --preavg

    echo "Made parsets for ${MS}"

  done

done <$L_LIST

# RUN PARSETS
sbatch ${SCRIPTS}/split_directions/phaseshift_batch_small.sh


echo "-----------------FINISHED SPLIT DIRECTIONS-----------------"

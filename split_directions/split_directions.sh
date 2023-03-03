#!/bin/bash
#SBATCH -N 1 -c 5 --job-name=split_directions

#List with L-numbers --> TEXT FILE
L_LIST=$1
#Catalogue with sources --> FITS FILE
CATALOG=$2

SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export RESULTS_DIR=$PWD
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo "Job landed on $(hostname)"

echo "-----------------STARTED SPLIT DIRECTIONS-----------------"

while read -r LNUM; do

  #WHEN YOU RUN WITH SKYMODEL
  SOLUTIONS=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/delayselfcal/merged_selfcalcyle000_linearfulljones_${LNUM}_120_168MHz_averaged.ms.avg.h5

  echo "Copy applycal ms"
  for MS in /project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/subtract/subtract_lotss/sub6asec_${LNUM}*.ms; do

    #Make calibrator parsets
    singularity exec -B $PWD,/project $SIMG python ${SCRIPTS}/split_directions/make_directions_parsets.py --catalog ${CATALOG} --prefix ${LNUM} --ms ${MS} --h5 ${SOLUTIONS}
    echo "Made parsets for ${LNUM}"

  done

#  sbatch ${SCRIPTS}/split_directions/phaseshift_batch1.sh ${LNUM}
#  sbatch ${SCRIPTS}/split_directions/phaseshift_batch2.sh ${LNUM}
#  sbatch ${SCRIPTS}/split_directions/phaseshift_batch3.sh ${LNUM}

done <$L_LIST

#Run parsets


echo "-----------------FINISHED SPLIT DIRECTIONS-----------------"

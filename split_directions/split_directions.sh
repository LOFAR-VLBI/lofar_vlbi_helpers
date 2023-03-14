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
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo "Job landed on $(hostname)"

echo "-----------------STARTED SPLIT DIRECTIONS-----------------"

while read -r LNUM; do

  #WHEN YOU RUN WITH SKYMODEL
  SOLUTIONS=${PROJPATH}/ALL_L/delayselfcal/merged_selfcalcyle000_linearfulljones_${LNUM}_120_168MHz_averaged.ms.avg.h5

  echo "Copy applycal ms"
  for MS in ${PROJPATH}/${LNUM}/subtract/subtract_lotss/sub6asec_${LNUM}*.ms; do

    #Make calibrator parsets
    singularity exec -B $PWD,/project $SIMG python ${SCRIPTS}/split_directions/make_directions_parsets.py --catalog ${CATALOG} --prefix ${LNUM} --ms ${MS} --h5 ${SOLUTIONS}
    echo "Made parsets for ${MS}"

  done

done <$L_LIST

PARSET_COUNT=$(ls *.parset | wc -l)
BATCHES=$(($V1 / 1000))
for B in `seq ${BATCHES}`; do
  sbatch ${SCRIPTS}/split_directions/phaseshift_batch.sh $((${B} * 1000))
done

#Run parsets

echo "-----------------FINISHED SPLIT DIRECTIONS-----------------"

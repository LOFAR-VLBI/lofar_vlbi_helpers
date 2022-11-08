#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=split_directions

#List with L-numbers
L_LIST=$1
#Catalogue with sources
CATALOG=$2

SCRIPTS=/home/lofarvwf-jdejong/scripts/prefactor_helpers

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export RESULTS_DIR=$PWD
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo "Job landed on $(hostname)"

echo "-----------------STARTED SPLIT DIRECTIONS-----------------"

while read -r LNUM; do
  #Check if special case
  H5=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/delayselfcal/merged_selfcalcyle000_linearfulljones_${LNUM}_120_168MHz_averaged.ms.avg.h5
  cp ${H5} .
  if [[ "$LNUM" =~ ^(L798074|L816272|)$ ]]; then
      #make calibrator parsets
      singularity exec -B $PWD,/project $SIMG python ${SCRIPTS}/split_directions/make_calibrator_parsets.py --catalog ${CATALOG} --already_averaged_data --prefix ${LNUM}
  else
      singularity exec -B $PWD,/project $SIMG python ${SCRIPTS}/split_directions/make_calibrator_parsets.py --catalog ${CATALOG} --h5 ${H5} ${LNUM}
  fi
  echo "Made parsets for ${LNUM}"
  for P in ${LNUM}*.parset; do
    for MS in sub6asec_${LNUM}*.ms; do
      #Launch sbatch script
		  sbatch ${SCRIPTS}/split_directions/applycal_phaseshift.sh ${P} ${MS} ${H5}
		  echo "Launched script for ${P} and ${MS}"
    done
  done
done <$L_LIST

echo "-----------------FINISHED SPLIT DIRECTIONS-----------------"
#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=applycal_submitter

#SCRIPT TO APPLY SOLUTIONS ON SUBBANDS (IMPORTANT FOR DI IMAGING)

#list with L numbers
L_LIST=$1

SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers
DELAYPATH=/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/delayselfcal

echo "Job landed on $(hostname)"

while read -r LNUM; do

  PATH_MS=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/subtract/subtract_lotss

  for MS in ${PATH_MS}/sub6asec_${LNUM}*.ms
  do
    sbatch ${SCRIPTS}/applycal/applycal.sh ${MS} ${DELAYPATH}/merged_skyselfcalcyle000_linearfulljones_${LNUM}_120_168MHz_averaged.ms.avg.h5
  done

done <$L_LIST
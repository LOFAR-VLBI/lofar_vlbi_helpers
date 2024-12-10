#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=applycal_submitter

#SCRIPT TO APPLY SOLUTIONS ON SUBBANDS (IMPORTANT FOR DI IMAGING)

#INPUT H5 FILE
H5=$1

cp ${H5} .

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

PATH_MS=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss
SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers

for FILE in ${PATH_MS}/sub6asec_${OBSERVATION}*.ms
do
  sbatch ${SCRIPTS}/applycal/applycal.sh ${FILE} ${H5##*/}
done

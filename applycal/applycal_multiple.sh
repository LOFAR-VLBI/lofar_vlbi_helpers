#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=applycal_submitter

#Run this script in folder with sub6asec MS files

#INPUT H5 FILE
H5=$1

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

PATH=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss/

for FILE in ${PATH}/sub6asec_${OBSERVATION}*.ms
do
  sbatch applycal.sh ${FILE} ${H5}
done
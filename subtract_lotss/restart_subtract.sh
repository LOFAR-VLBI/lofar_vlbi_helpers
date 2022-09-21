#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi
echo "SUBTRACT START ${OBSERVATION}"


DIR=subtract_lotss/

cd ${DIR}

for FILE in ${OBSERVATION}*
do
  cd ${FILE}
  echo L*.pre-cal.ms > mslist.txt
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh mslist.txt
  cd ../
done

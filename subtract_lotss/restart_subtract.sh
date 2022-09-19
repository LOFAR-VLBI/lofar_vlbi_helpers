#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi
echo "SUBTRACT START ${OBSERVATION}"

cd subtract_lotss

for FILE in ${OBSERVATION}*.msdpppconcat_subrun
do
  echo "Subtract ${FILE}"
  if [[ ${FILE} =~ $re_subband ]]; then SUBBAND=${BASH_REMATCH}; fi
  mv ${FILE} ${SUBBAND}_subrun
  mv ${SUBBAND}_subrun/${SUBBAND}.msdpppconcat ${SUBBAND}_subrun/${SUBBAND}.pre-cal.ms
  cd ${SUBBAND}_subrun
  echo ${SUBBAND}.pre-cal.ms > mslist.txt
  rm -rf SOLSDIR/*.msdpppconcat
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh mslist.txt
  cd ../
done
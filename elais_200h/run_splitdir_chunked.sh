#!/bin/bash
#SBATCH -t 1:00:00 -c 1

CSV=$1

#GET SCRIPT RUN DIRECTORY

#if [ -n "${SLURM_ARRAY_JOB_ID}" ] && [ -n "${SLURM_ARRAY_TASK_ID}" ]; then
#  SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $2}')
#  export SCRIPT_DIR=$(dirname "${SCRIPT}")
#else
#  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#fi

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/elais_128h

source ${SCRIPT_DIR}/other/chunk_csv.sh $CSV


# Loop through each CSV chunk file with an index
ENUMERATE=1
for CSV_CHUNK in chunk*.csv; do

  # Create run folder
  RUNFOLDER=chunk_${ENUMERATE}
  mkdir -p ${RUNFOLDER}
  mv ${CSV_CHUNK} ${RUNFOLDER}
  cd ${RUNFOLDER}

  # Submit the job with sbatch
  sbatch ${SCRIPT_DIR}/run_splitdir.sh $(realpath "${CSV_CHUNK}")
  cd ../

  # Increment the enumeration counter
  ((ENUMERATE++))
done
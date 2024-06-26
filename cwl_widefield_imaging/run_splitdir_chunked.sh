#!/bin/bash

LNUM=$1
CSV=$2

#GET SCRIPT RUN DIRECTORY

if [ -n "${SLURM_ARRAY_JOB_ID}" ] && [ -n "${SLURM_ARRAY_TASK_ID}" ]; then
  SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $2}')
  export SCRIPT_DIR=$(dirname "${SCRIPT}")
else
  export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

source ${SCRIPT_DIR}/other/chunk_csv.sh $CSV

# Initialize the enumeration counter
ENUMERATE=1

# Loop through each CSV chunk file with an index
for CSV_CHUNK in chunk*.csv; do
  # Define the run folder using the enumeration counter
  RUNFOLDER=chunk_${ENUMERATE}

  # Create the run folder if it doesn't exist
  mkdir -p ${RUNFOLDER}
  cp ${CSV_CHUNK} ${RUNFOLDER}
  cd ${RUNFOLDER}

  # Submit the job with sbatch, passing necessary arguments
  sbatch ${SCRIPT_DIR}/run_splitdir.sh ${LNUM} $(realpath "${CSV_CHUNK}")
  cd ../

  # Increment the enumeration counter
  ((ENUMERATE++))
done
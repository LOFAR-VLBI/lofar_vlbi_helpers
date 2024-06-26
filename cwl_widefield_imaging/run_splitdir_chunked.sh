#!/bin/bash

LNUM=$1
CSV=$2

#GET SCRIPT RUN DIRECTORY
if [ -n "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" ] ; then
SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $TARHTML}')
export SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
export SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

source ${SCRIPT_DIR}/other/chunk_csv.sh $CSV

for CSV_CHUNK in chunk*.csv; do
  sbatch ${SCRIPT_DIR}/run_splitdir.sh ${LNUM} ${CSV}
done
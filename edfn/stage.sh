#!/bin/bash

SASID=$1

if [[ -n ${SLURM_SUBMIT_DIR:-} ]]; then
    SCRIPT=$(scontrol show job "${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}" | awk -F= '/Command=/{print $TARHTML}')
    export SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fi
source $SCRIPT_DIR/setup.sh

mkdir -p L${SASID}

cd $MASTERDIR/L${SASID}

singularity exec $SING_IMG python $SOFTWARE_DIR/flocs-lta/flocs_lta/flocs_search_lta.py \
    --sasid "$SASID" \
    --project ALL \
    --stage

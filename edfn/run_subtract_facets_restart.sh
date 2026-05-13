#!/bin/bash
#SBATCH -p infinite -c 1

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

source ${VENV}/bin/activate

export TOIL_SLURM_ARGS="--export=ALL -t 72:00:00 -p normal,infinite"
export APPTAINER_CLEANENV=1

BAD_NODES=$( source ${SCRIPT_DIR}/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="${TOIL_SLURM_ARGS} --exclude=${BAD_NODES}"
fi

WORKDIR=$PWD/workdir
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

ulimit -S -n 8192

# RUN TOIL
toil-cwl-runner \
--no-read-only \
--retryCount 5 \
--singularity \
--disableCaching \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--disableAutoDeployment True \
--bypass-file-store \
--batchSystem slurm \
--cleanWorkDir onSuccess \
--eval-timeout 4000 \
--no-cwl-default-ram \
--stats \
--cwl-min-ram "8Gi" \
--restart \
${VLBI_DATA_ROOT}/workflows/dd-calibration.cwl input.json

########################

deactivate

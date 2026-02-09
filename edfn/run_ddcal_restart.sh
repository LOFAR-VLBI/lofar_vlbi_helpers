#!/bin/bash
#SBATCH --output=ddcal_%j.out
#SBATCH --error=ddcal_%j.err
#SBATCH -p infinite

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

VENV=/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/.venv


source ${VENV}/bin/activate

export APPTAINER_BIND="${APPTAINER_BIND},/project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal:/opt/lofar/pyenv-py3/lib/python3.12/site-packages/facetselfcal"

export TOIL_SLURM_ARGS="--export=ALL -t 72:00:00"

BAD_NODES=$( source /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="${TOIL_SLURM_ARGS} --exclude=${BAD_NODES}"
fi
ulimit -S -n 8192

# RUN TOIL
toil-cwl-runner \
--no-read-only \
--retryCount 3 \
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
--restart \
${VLBI_DATA_ROOT}/workflows/dd-calibration.cwl input.json

########################

deactivate

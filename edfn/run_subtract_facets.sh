#!/bin/bash
#SBATCH -p infinite -c 1

######################
####### INPUT ########
######################

MSDATA=$(realpath "../applycal")
MODELS=$(realpath "../1asec")
H5FACETS=$(realpath "../ddcal/h5parm_output/merged.h5")
SCRATCH='true'

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

export TOIL_SLURM_ARGS="--export=ALL -t 48:00:00 -p normal,infinite"

BAD_NODES=$( source ${SCRIPT_DIR}/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="${TOIL_SLURM_ARGS} --exclude=${BAD_NODES}"
fi

# Make JSON file
JSON="input.json"

jq -n \
  --arg models "$MODELS" \
  --arg h5 "$H5FACETS" \
  --arg scratch "$SCRATCH" \
  --args '
    {
      msin: [$ARGS.positional[] | {class: "Directory", path: .}],
      model_image_directory: {class: "Directory", path: $models},
      h5parm: {class: "File", path: $h5}
    }
    + (if $scratch == "true" then {tmpdir: "/tmp"} else {} end)
  ' "$MSDATA"/*.ms > "$JSON"

########################

# MAKE TOIL RUNNING STRUCTURE
WORKDIR=$PWD/workdir
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

mkdir -p $WORKDIR
mkdir -p $OUTPUT
mkdir -p $LOGDIR

########################

ulimit -S -n 8192

# Activate env
source ${VENV}/bin/activate

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
${VLBI_DATA_ROOT}/workflows/facet_subtract.cwl $JSON

########################

deactivate

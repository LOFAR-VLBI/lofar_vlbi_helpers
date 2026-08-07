#!/bin/bash
#SBATCH -p infinite,normal -c 1

######################
######## INPUT #######
######################

# Directory with facet MS
MSDATA=$(realpath "./")
POLYGONS=$(realpath "./")

export TOIL_SLURM_ARGS="--export=ALL -t 12:00:00 -p infinite,normal"

RES=1.2
PIXSCALE=0.4

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

# Make JSON file
JSON="input.json"

jq -n \
  --arg resolution "$RES" \
  --argjson pixel_scale "$PIXSCALE" \
  --args '
    {
      msin: [$ARGS.positional[] | select(endswith(".ms")) | {class: "Directory", path: .}],
      facet_polygons: [$ARGS.positional[] | select(endswith(".reg")) | {class: "File", path: .}],
      $resolution,
      $pixel_scale,
      ncpu: 4
    }
  ' "$MSDATA"/*.ms "$POLYGONS"/*.reg > "$JSON"

########################

# Make folders for running toil
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs

mkdir -p $OUTPUT

########################

source ${VENV}/bin/activate

# RUN TOIL
toil-cwl-runner \
--no-read-only \
--retryCount 1 \
--singularity \
--disableCaching \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--jobStore ${JOBSTORE} \
--disableAutoDeployment True \
--batchSystem slurm \
--cleanWorkDir onSuccess \
--eval-timeout 4000 \
--stats \
--workDir /tmp \
${VLBI_DATA_ROOT}/workflows/facet_imaging.cwl input.json

########################

deactivate

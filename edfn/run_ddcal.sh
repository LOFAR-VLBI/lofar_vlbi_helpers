#!/bin/bash
#SBATCH -p infinite -c 1

######################
######## INPUT #######
######################

# Catalogue
CAT=$(realpath $1)
#/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/lofar_10sqdeg_edfpos_v4.1_gt5.fits
# Directory with MS subbands with in-field solutions applied
MSDATA=$(realpath "../applycal")

export TOIL_SLURM_ARGS="--export=ALL -t 12:00:00 -p infinite,normal"

FLUXCUT=0.025 #25 mJy
NN_MODEL=$PWD/cortexchange

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

# Make JSON file
JSON="input.json"

jq -n \
  --arg cat "$CAT" \
  --argjson fluxcut "$FLUXCUT" \
  --arg nn_model "$NN_MODEL" \
  --args '
    {
      msin: [$ARGS.positional[] | {class: "Directory", path: .}],
      source_catalogue: {class: "File", path: $cat},
      peak_flux_cut: $fluxcut,
      model_cache: $nn_model
    }
  ' "$MSDATA"/*.ms > "$JSON"

########################

# Make folders for running toil
WORKDIR=$PWD/workdir
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

mkdir -p $WORKDIR
mkdir -p $OUTPUT
mkdir -p $LOGDIR

########################

source ${VENV}/bin/activate

# Download model

python /project/lofarvwf/Software/lofar_facet_selfcal/submods/source_selection/download_neural_network.py --cache_directory cortexchange
ulimit -S -n 8192

# RUN TOIL

toil-cwl-runner \
--no-read-only \
--retryCount 6 \
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
${VLBI_DATA_ROOT}/workflows/dd-calibration.cwl input.json

########################

deactivate

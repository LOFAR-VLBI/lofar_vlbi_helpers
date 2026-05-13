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

# Add MS
json="{\"msin\":["
for file in "$MSDATA"/*.ms; do
    json="$json{\"class\": \"Directory\", \"path\": \"$file\"},"
done
json="${json%,}]}"
echo "$json" > "$JSON"

# Add source_catalogue file
jq --arg path "$CAT" \
   '. + {
     "source_catalogue": {
       "class": "File",
       "path": $path
     }
   }' "$JSON" > temp.json && mv temp.json "$JSON"

jq --argjson FLUXCUT "$FLUXCUT" '. + {"peak_flux_cut": $FLUXCUT}' "$JSON" > temp.json && mv temp.json "$JSON"
jq --arg NN_MODEL "$NN_MODEL" '. + {model_cache: $NN_MODEL}' "$JSON" > temp.json && mv temp.json "$JSON"

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

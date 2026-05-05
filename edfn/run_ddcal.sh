#!/bin/bash
#SBATCH -p infinite

######################
######## INPUT #######
######################

CAT=$(realpath $1)
DUTCHSOL=$(realpath $2)
MSDATA=$(realpath "../applycal")
FLUXCUT=0.04 #25 mJy
NN_MODEL=$PWD/cortexchange

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing

export TOIL_SLURM_ARGS="--export=ALL -t 72:00:00 -p normal,infinite"

BAD_NODES=$( source /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="${TOIL_SLURM_ARGS} --exclude=${BAD_NODES}"
fi

# Activate env
VENV=/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/.venv
source ${VENV}/bin/activate

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

# Add dutch solutions
jq --arg path "$DUTCHSOL" \
   '. + {
     "dd_dutch_solutions": {
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

# Download model
python /project/lofarvwf/Software/lofar_facet_selfcal/submods/source_selection/download_neural_network.py --cache_directory cortexchange
ulimit -S -n 8192

# RUN TOIL
toil-cwl-runner \
--no-read-only \
--retryCount 4 \
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

#!/bin/bash
#SBATCH --output=1asec_%j.out
#SBATCH --error=1asec_%j.err
#SBATCH -p infinite

######################
######## INPUT #######
######################

# h5parm solutions
SOLS=$(realpath $1)
# Directory with MS subbands with in-field solutions applied
MSDATA=$(realpath "../applycal")

export TOIL_SLURM_ARGS="--export=ALL -t 72:00:00"

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing
VENV=/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/.venv
source ${VENV}/bin/activate
export APPTAINER_BIND="${APPTAINER_BIND},/project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal:/opt/lofar/pyenv-py3/lib/python3.12/site-packages/facetselfcal"
export APPTAINER_BIND="${APPTAINER_BIND},/project/lofarvwf/Software/pilot/scripts:/opt/lofar/VLBI-cwl/scripts"

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
jq --arg path "$SOLS" \
   '. + {
     "dd_solutions": {
       "class": "File",
       "path": $path
     }
   }' "$JSON" > temp.json && mv temp.json "$JSON"

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
--stats \
${VLBI_DATA_ROOT}/workflows/image_intermediate_resolution.cwl input.json

########################

deactivate

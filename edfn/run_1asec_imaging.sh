#!/bin/bash
#SBATCH -p infinite -c 64

######################
######## INPUT #######
######################

# h5parm solutions
SOLS=$(realpath $1)
# Directory with MS subbands with in-field solutions applied
MSDATA=$(realpath "../applycal")

######################
######################

# SETUP ENVIRONMENT
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn
source $SCRIPT_DIR/setup.sh --no-git --no-sing
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
jq --arg path "$SOLS" \
   '. + {
     "dd_solutions": {
       "class": "File",
       "path": $path
     }
   }' "$JSON" > temp.json && mv temp.json "$JSON"

ncpu=64
jq --argjson ncpu "$ncpu" '. + {"ncpu": $ncpu}' "$JSON" > temp.json && mv temp.json "$JSON"

########################

FINALOUT=$PWD/outdir
mkdir -p $FINALOUT
cp input.json $TMPDIR

cd $TMPDIR

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
singularity exec ${SING_IMG} \
toil-cwl-runner \
--no-read-only \
--retryCount 3 \
--disableCaching \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--disableAutoDeployment True \
--cleanWorkDir onSuccess \
--eval-timeout 4000 \
--no-container \
--stats \
--bypass-file-store \
--preserve-entire-environment \
--coordinationDir $PWD \
${VLBI_DATA_ROOT}/workflows/image_intermediate_resolution.cwl input.json

########################

toil stats jobstore > ${FINALOUT}/stats.txt
cp ${TMPDIR}/*/*.log ${FINALOUT}
cp -r ${LOGDIR} ${FINALOUT}
cp -r ${OUTPUT} ${FINALOUT}
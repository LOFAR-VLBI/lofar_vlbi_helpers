#!/bin/bash
#SBATCH -p infinite

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

json="{\"msin\":["
for file in "$MSDATA"/*.ms; do
    json="$json{\"class\": \"Directory\", \"path\": \"$file\"},"
done
json="${json%,}]}"
echo "$json" > "$JSON"

MODELPATH=$MAINFOLDER/modelims
mkdir -p $MODELPATH
cp $MODELS/*model-fpb.fits $MODELPATH

jq --arg path "$MODELPATH" \
   '. + {"model_image_folder": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

jq --arg path "$PWD/merged.h5" \
   '. + {"h5parm": {"class": "File", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

if [ "$SCRATCH" = "true" ]; then
  jq '. + {tmpdir: "/tmp"}' "$JSON" > temp.json && mv temp.json "$JSON"
fi

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

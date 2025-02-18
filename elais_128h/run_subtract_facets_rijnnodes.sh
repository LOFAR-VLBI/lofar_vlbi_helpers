#!/bin/bash

######################
#### UPDATE THESE ####
######################

SIMG=/net/achterrijn/data1/sweijen/software/containers/lofar_sksp_rijnX.sif
BIND=/net/rijn,/net/rijn8,$PWD,/net/rijn2,/net/rijn10,/net/achterrijn

if [[ $PWD =~ L[0-9]{6} ]]; then LNUM=${BASH_REMATCH[0]}; fi

MAINFOLDER=$PWD

export MSDATA=$MAINFOLDER/applycal
export H5FACETS=$MAINFOLDER/merged_in.h5
export MODELPATH=$MAINFOLDER/modelims

######################
######################

# SETUP ENVIRONMENT


mkdir -p software
cd software
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal
git clone -b facet_subtract https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
cd ../

export LINC_DATA_ROOT=$PWD/software/LINC
export VLBI_DATA_ROOT=$PWD/software/VLBI_cwl
export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH
export APPTAINER_BIND=$SING_BIND
export TOIL_CHECK_ENV=True

########################

# Define the output JSON file
JSON="input.json"

# Start the JSON structure for 'msin'
json="{\"msin\":["

# Loop through each file in the MSDATA folder and append to the JSON structure
for file in "$MSDATA"/*.ms; do
    json="$json{\"class\": \"Directory\", \"path\": \"$file\"},"
done

# Remove the trailing comma and close the JSON array and object
json="${json%,}]}"  # Remove the last comma and add the closing brackets

# Save the initial JSON structure to the file
echo "$json" > "$JSON"

# Add 'lofar_helpers' with 'class' and 'path'
jq --arg path "$PWD/software/lofar_helpers" \
   '. + {"lofar_helpers": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

# Add 'lofar_helpers' with 'class' and 'path'
jq --arg path "$PWD/software/lofar_facet_selfcal" \
   '. + {"facetselfcal": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

# Add 'model_image_folder' with 'class' and 'path'
jq --arg path "$MODELPATH" \
   '. + {"model_image_folder": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

chmod 755 -R software

singularity exec -B $BIND \
$SIMG python software/lofar_helpers/h5_merger.py \
-in $H5FACETS \
-out $PWD/merged.h5 \
--add_ms_stations \
-ms $(find "$MSDATA" -maxdepth 1 -name "*.ms" | head -n 1) \
--h5_time_freq 1

# Add 'h5parm' with 'class' and 'path'
jq --arg path "$PWD/merged.h5" \
   '. + {"h5parm": {"class": "File", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

jq '. + {"ncpu": 16}' "$JSON" > temp.json && mv temp.json "$JSON"

########################

# MAKE TOIL RUNNING STRUCTURE

# make folder for running toil
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
singularity exec -B $BIND $SIMG \
toil-cwl-runner \
--no-read-only \
--retryCount 2 \
--no-container \
--disableCaching \
--writeLogsFromAllJobs True \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--disableAutoDeployment True \
--bypass-file-store \
--preserve-entire-environment \
--clean onSuccess \
--no-compute-checksum \
software/VLBI_cwl/workflows/facet_subtract.cwl $JSON

########################

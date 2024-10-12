#!/bin/bash
#SBATCH --output=predim_%j.out
#SBATCH --error=predim_%j.err


### INPUT ###
export MSDATA=$(realpath $1)
export H5FACETS=$(realpath $2)
export MODELS=$(realpath $3)

######################
#### UPDATE THESE ####
######################

export TOIL_SLURM_ARGS="--export=ALL -p normal --constraint=rome"

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong"
VENV=/home/lofarvwf-jdejong/venv

######################
######################

# SETUP ENVIRONMENT

MAINFOLDER=$PWD

# set up software
mkdir -p software
cd software
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal
git clone -b facet_subtract https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v5.3.0_znver2_znver2.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

CONTAINERSTR=$(singularity --version)
if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
  export APPTAINER_CACHEDIR=$PWD/singularity
  export APPTAINER_TMPDIR=$APPTAINER_CACHEDIR/tmp
  export APPTAINER_PULLDIR=$APPTAINER_CACHEDIR/pull
  export APPTAINER_BIND=$SING_BIND
else
  export SINGULARITY_CACHEDIR=$PWD/singularity
  export SINGULARITY_TMPDIR=$SINGULARITY_CACHEDIR/tmp
  export SINGULARITY_PULLDIR=$SINGULARITY_CACHEDIR/pull
  export SINGULARITY_BIND=$SING_BIND
fi

export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export TOIL_CHECK_ENV=True

########################

# Define the output JSON file
JSON="input.json"

# Start the JSON structure for 'msin'
json="{\"msin\":["

# Loop through each file in the MSDATA folder and append to the JSON structure
for file in "$MSDATA"/*; do
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
   '. + {"selfcal": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

# Add 'h5parm' with 'class' and 'path'
jq --arg path "$H5FACETS" \
   '. + {"h5parm": {"class": "File", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

# Add 'model_image_folder' with 'class' and 'path'
jq --arg path "$MODELS" \
   '. + {"model_image_folder": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

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

source ${VENV}/bin/activate

########################

# RUN TOIL
toil-cwl-runner \
--no-read-only \
--retryCount 0 \
--singularity \
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
--batchSystem slurm \
--clean onSuccess \
--no-compute-checksum \
software/VLBI_cwl/workflows/facet_subtract.cwl $JSON
#--tmpdir-prefix ${TMPD}_interm/ \

########################

cd $MAINFOLDER
rm -rf tmpdir*/*.ms

deactivate

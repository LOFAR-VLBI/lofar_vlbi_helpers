#!/bin/bash
#SBATCH --output=predim_%j.out
#SBATCH --error=predim_%j.err
#SBATCH -p infinite

######################
#### UPDATE THESE ####
######################

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public"
VENV=/project/lofarvwf/Software/venv
SING_IMAGE=https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v5.4.1_znver2_znver2.sif

if [[ $PWD =~ L[0-9]{6} ]]; then LNUM=${BASH_REMATCH[0]}; fi

export TOIL_SLURM_ARGS="--export=ALL -p normal -t 12:00:00 --job-name ${LNUM}_subtract"
export MSDATA=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/${LNUM}/applycal
export MODELS=/project/lofarvwf/Share/jdejong/output/ELAIS/${LNUM}/${LNUM}/ddcal/selfcals/imaging
export H5FACETS=${MODELS}/merged.h5

export SCRATCH='true'

######################
######################

# SETUP ENVIRONMENT

MAINFOLDER=$PWD

# set up software
source ${VENV}/bin/activate

mkdir -p software
cd software
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal
git clone -b facet_subtract https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
git clone https://github.com/LOFAR-VLBI/lofar_vlbi_helpers
cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget $SING_IMAGE -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

export LINC_DATA_ROOT=$PWD/software/LINC
export VLBI_DATA_ROOT=$PWD/software/VLBI_cwl

export APPTAINER_CACHEDIR=$PWD/singularity
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts:$PWD/software/lofar_vlbi_helpers/elais_128h/advanced_facet_subtract/scripts
export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:$PWD/software/lofar_vlbi_helpers/elais_128h/advanced_facet_subtract/scripts:\$PYTHONPATH
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


MODELPATH=$MAINFOLDER/modelims
mkdir -p $MODELPATH
#cp $MODELS/*model.fits $MODELPATH
#cp $MODELS/*model-pb.fits $MODELPATH
cp $MODELS/*model-fpb.fits $MODELPATH

# Add 'model_image_folder' with 'class' and 'path'
jq --arg path "$MODELPATH" \
   '. + {"model_image_folder": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

chmod 755 -R singularity
chmod 755 -R software

singularity exec singularity/$SIMG python software/lofar_helpers/h5_merger.py \
-in $H5FACETS \
-out $PWD/merged.h5 \
--add_ms_stations \
-ms $(find "$MSDATA" -maxdepth 1 -name "*.ms" | head -n 1) \
--h5_time_freq 1

# Add 'h5parm' with 'class' and 'path'
jq --arg path "$PWD/merged.h5" \
   '. + {"h5parm": {"class": "File", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

#SELECTION WAS ALREADY DONE
if [ "$SCRATCH" = "true" ]; then
  jq --arg copy_to_local_scratch "$SCRATCH" '. + {copy_to_local_scratch: true}' "$JSON" > temp.json && mv temp.json "$JSON"
fi

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
--batchSystem slurm \
--bypass-file-store \
--clean onSuccess \
--cleanWorkDir onSuccess \
--setEnv PATH=$APPTAINERENV_PREPEND_PATH:\$PATH \
--setEnv PYTHONPATH=$APPTAINERENV_PYTHONPATH \
software/lofar_vlbi_helpers/elais_128h/advanced_facet_subtract/workflows/facet_subtract.cwl $JSON

########################

cd $MAINFOLDER

deactivate

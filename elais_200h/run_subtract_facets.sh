#!/bin/bash
#SBATCH --output=predim_%j.out
#SBATCH --error=predim_%j.err
#SBATCH -p infinite

set -euo pipefail

######################
#### UPDATE THESE ####
######################

VENV=/project/lofarvwf/Software/venv
export SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public"
export TOIL_SLURM_ARGS="--export=ALL -p normal -t 12:00:00"
export MSDATA=$(realpath applycal)
export MODELS=$(realpath 1asec_imaging)
export H5FACETS=$(realpath ddcal/outdir/merged.h5)

export SCRATCH='true'

######################
######################

# SETUP ENVIRONMENT

MAINFOLDER=$PWD

# set up software
source ${VENV}/bin/activate

mkdir -p software
cd software

git clone https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
cd VLBI_cwl
git checkout 98ff43f
cd ..

cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v6.0.0.alpha_cascadelake_cascadelake.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

export VLBI_DATA_ROOT=$PWD/software/VLBI_cwl
export APPTAINER_CACHEDIR=$PWD/singularity
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
export APPTAINERENV_PREPEND_PATH=$VLBI_DATA_ROOT/scripts
export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:\$PYTHONPATH
export APPTAINER_BIND=$SING_BIND
export TOIL_CHECK_ENV=True

########################

# Make JSON file
JSON="input.json"

json="{\"msin\":["
for file in "$MSDATA"/*.ms; do
    json="$json{\"class\": \"Directory\", \"path\": \"$file\"},"
done
json="${json%,}]}"
echo "$json" > "$JSON"

jq --arg path "${MODELS}" \
   '. + {"model_image_folder": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

jq --arg path "${H5FACETS}" \
   '. + {"h5parm": {"class": "File", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

if [ "$SCRATCH" = "true" ]; then
  jq '. + {tmpdir: "/tmp"}' "$JSON" > temp.json && mv temp.json "$JSON"
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
software/VLBI_cwl/workflows/facet_subtract.cwl $JSON

########################

cd $MAINFOLDER

deactivate

#!/bin/bash
#SBATCH --output=ddcal_%j.out
#SBATCH --error=ddcal_%j.err
#SBATCH -p infinite

######################
######## INPUT #######
######################

# Catalogue
CAT=$(realpath $1)
# Directory with MS subbands with in-field solutions applied
MSDATA=$(realpath $2)

export TOIL_SLURM_ARGS="--export=ALL -t 36:00:00"

FLUXCUT=0.25 #250 mJy (too large)
SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public"
VENV=/project/lofarvwf/Software/venv

######################
######################

# SETUP ENVIRONMENT

# set up software
source ${VENV}/bin/activate

mkdir -p software
cd software
git clone -b ddcal_widefield https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
git clone https://github.com/jurjen93/lofar_helpers.git
git clone https://github.com/rvweeren/lofar_facet_selfcal.git
git clone https://git.astron.nl/RD/LINC.git

mkdir scripts
cp LINC/scripts/* scripts
cp VLBI_cwl/scripts/* scripts
SCRIPTS_PATH=$PWD/scripts
chmod 755 ${SCRIPTS_PATH}/*
SING_BIND=${SING_BIND}",${SCRIPTS_PATH}:/opt/lofar/DynSpecMS"
PYPATH=${PWD}/VLBI_cwl/scripts:${PWD}/LINC/scripts:\$PYTHONPATH
PTH=${PWD}/VLBI_cwl/scripts:${PWD}/LINC/scripts:\$PATH
cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v5.5.1_znver2_znver2.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

export LINC_DATA_ROOT=$PWD/software/LINC
export VLBI_DATA_ROOT=$PWD/software/VLBI_cwl

export APPTAINER_CACHEDIR=$PWD/singularity
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export APPTAINERENV_LINC_DATA_ROOT=$LINC_DATA_ROOT
export APPTAINERENV_VLBI_DATA_ROOT=$VLBI_DATA_ROOT
export APPTAINERENV_PREPEND_PATH=$LINC_DATA_ROOT/scripts:$VLBI_DATA_ROOT/scripts
export APPTAINERENV_PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH
export APPTAINER_BIND=$SING_BIND
export TOIL_CHECK_ENV=True

########################

# Make JSON file
JSON="input.json"

# Add MS
json="{\"msin\":["
for file in "$MSDATA"/*.ms; do
    json="$json{\"class\": \"Directory\", \"path\": \"$file\"},"
done
json="${json%,}]}"
echo "$json" > "$JSON"

jq --arg path "$PWD/software/lofar_helpers" \
   '. + {"lofar_helpers": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

jq --arg path "$PWD/software/lofar_facet_selfcal" \
   '. + {"facetselfcal": {"class": "Directory", "path": $path}}' \
   "$JSON" > temp.json && mv temp.json "$JSON"

# Add source_catalogue file
jq --arg path "$CAT" \
   '. + {
     "source_catalogue": {
       "class": "File",
       "path": $path
     }
   }' "$JSON" > temp.json && mv temp.json "$JSON"

jq --argjson FLUXCUT "$FLUXCUT" '. + {"peak_flux_cut": $FLUXCUT}' "$JSON" > temp.json && mv temp.json "$JSON"

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
--setEnv PATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PATH \
--setEnv PYTHONPATH=$VLBI_DATA_ROOT/scripts:$LINC_DATA_ROOT/scripts:\$PYTHONPATH \
software/VLBI_cwl/workflows/dd-calibration.cwl input.json

########################

deactivate

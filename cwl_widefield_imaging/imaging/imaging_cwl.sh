#!/bin/bash
#SBATCH --output=predim_%j.out
#SBATCH --error=predim_%j.err

######################
#### UPDATE THESE ####
######################

export TOIL_SLURM_ARGS="--export=ALL --job-name facetpredict -p normal --constraint=rome"

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong"
CONFIG=/project/lofarvwf/Share/jdejong/output/ELAIS/delaysolve_config.txt

MSDATA=$1
H5FACETS=$2
MODELS=$3

VENV=/home/lofarvwf-jdejong/venv

######################
######################

# SETUP ENVIRONMENT

# set up software
mkdir -p software
cd software
git clone https://github.com/jurjen93/lofar_helpers.git
cd ../

# set up singularity
SIMG=vlbi-cwl.sif
mkdir -p singularity
wget https://lofar-webdav.grid.sara.nl/software/shub_mirror/tikk3r/lofar-grid-hpccloud/amd/flocs_v5.0.0_znver2_znver2_aocl_cuda.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

CONTAINERSTR=$(singularity --version)
if [[ "$CONTAINERSTR" == *"apptainer"* ]]; then
  export APPTAINER_CACHEDIR=$PWD/singularity
  export APPTAINER_TMPDIR=$APPTAINER_CACHEDIR/tmp
  export APPTAINER_PULLDIR=$APPTAINER_CACHEDIR/pull
  export APPTAINER_BIND=$SING_BIND
  export APPTAINERENV_PYTHONPATH=$PYPATH
  export APPTAINERENV_PATH=$PTH
else
  export SINGULARITY_CACHEDIR=$PWD/singularity
  export SINGULARITY_TMPDIR=$SINGULARITY_CACHEDIR/tmp
  export SINGULARITY_PULLDIR=$SINGULARITY_CACHEDIR/pull
  export SINGULARITY_BIND=$SING_BIND
  export SINGULARITYENV_PYTHONPATH=$PYPATH
  export SINGULARITYENV_PYTHONPATH=$PTH
fi

export SING_USER_DEFINED_PATH=$PTH
export CWL_SINGULARITY_CACHE=$APPTAINER_CACHEDIR
export TOIL_CHECK_ENV=True
export LINC_DATA_ROOT=$PWD/software/LINC

########################

singularity exec singularity/$SIMG \
python software/flocs/runners/create_ms_list.py \
VLBI \
split-directions \
--configfile=$CONFIG \
--h5merger=$PWD/software/lofar_helpers \
--selfcal=$PWD/software/lofar_facet_selfcal \
--delay_solset=$SOLSET \
--ms_suffix ".ms" \
$MSDATA

#SELECTION WAS ALREADY DONE
jq '. + {"lofar_helpers": $PWD/software/lofar_helpers}' mslist_VLBI_split_directions.json > temp.json && mv temp.json mslist_VLBI_split_directions.json
jq '. + {"h5parm": $H5FACETS}' mslist_VLBI_split_directions.json > temp.json && mv temp.json mslist_VLBI_split_directions.json
jq '. + {"model_image_folder": $MODELS}' mslist_VLBI_split_directions.json > temp.json && mv temp.json mslist_VLBI_split_directions.json

########################

# MAKE TOIL RUNNING STRUCTURE

# make folder for running toil
WORKDIR=$PWD/workdir
OUTPUT=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

mkdir -p ${TMPD}_interm
mkdir -p $WORKDIR
mkdir -p $OUTPUT
mkdir -p $LOGDIR

source ${VENV}/bin/activate

########################

# RUN TOIL

#GET ORIGINAL SCRIPT DIRECTORY
if [ -n "${SLURM_JOB_ID:-}" ] ; then
SCRIPT=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

toil-cwl-runner \
--no-read-only \
--retryCount 2 \
--singularity \
--disableCaching \
--writeLogsFromAllJobs True \
--logFile full_log.log \
--writeLogs ${LOGDIR} \
--outdir ${OUTPUT} \
--tmp-outdir-prefix ${TMPD}/ \
--jobStore ${JOBSTORE} \
--workDir ${WORKDIR} \
--tmpdir-prefix ${TMPD}_interm/ \
--disableAutoDeployment True \
--bypass-file-store \
--preserve-entire-environment \
--batchSystem slurm \
--cleanWorkDir onSuccess \
${SCRIPT_DIR}/wide_field_imaging_only_predict.cwl mslist_VLBI_split_directions.json

########################

deactivate

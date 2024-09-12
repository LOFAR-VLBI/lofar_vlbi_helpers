#!/bin/bash
#SBATCH --output=splitdir_%j.out
#SBATCH --error=splitdir_%j.err

CSV=$1

######################
#### UPDATE THESE ####
######################

export TOIL_SLURM_ARGS="--export=ALL --job-name splitdir -p normal --constraint=rome"

SING_BIND="/project,/project/lofarvwf/Software,/project/lofarvwf/Share,/project/lofarvwf/Public,/home/lofarvwf-jdejong"
CAT=${CSV}
if [[ $PWD =~ L[0-9]{6} ]]; then LNUM=${BASH_REMATCH[0]}; fi
SOLSET=/project/lofarvwf/Share/jdejong/output/ELAIS/ALL_128h/all_dicalsolutions/merged_${LNUM}_linear.h5
CONFIG=/project/lofarvwf/Share/jdejong/output/ELAIS/delaysolve_config.txt
DD_SELECTION=true #or true?

VENV=/home/lofarvwf-jdejong/venv

SUBTRACTDATA=$(realpath "../../subtract")

######################
######################

# SETUP ENVIRONMENT

# set up software
mkdir -p software
cd software
git clone -b dd_selection https://git.astron.nl/RD/VLBI-cwl.git VLBI_cwl
git clone https://github.com/tikk3r/flocs.git
git clone https://github.com/jurjen93/lofar_helpers.git
git clone -b source_selection https://github.com/rvweeren/lofar_facet_selfcal.git
git clone https://git.astron.nl/RD/LINC.git
git clone https://github.com/revoltek/losoto
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
--do_selfcal=false \
--image_cat=$CAT \
--linc=$PWD/software/LINC \
--delay_solset=$SOLSET \
--ms_suffix ".ms" \
$SUBTRACTDATA

#SELECTION WAS ALREADY DONE
jq --arg dd_selection "$DD_SELECTION" '. + {dd_selection: $dd_selection}' mslist_VLBI_split_directions.json > temp.json && mv temp.json mslist_VLBI_split_directions.json

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
--disableAutoDeployment True \
--bypass-file-store \
--preserve-entire-environment \
--batchSystem slurm \
--cleanWorkDir onSuccess \
software/VLBI_cwl/workflows/split-directions.cwl mslist_VLBI_split_directions.json

########################

deactivate

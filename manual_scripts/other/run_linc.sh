#!/bin/bash
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err
#SBATCH -p infinite

############################
####### UPDATE THESE #######
############################

# INPUT DATA
DATADIR=$(realpath $1)
SOLUTIONS=$(realpath $2)

SING_BIND=/project/lofarvwf
VENV=/project/lofarvwf/Software/venv

######################
######################

#SLURM SETTINGS
export TOIL_SLURM_ARGS="--export=ALL -t 12:00:00"

# SETUP SOFTWARE
mkdir -p software
cd software
git clone https://git.astron.nl/RD/LINC.git
git clone https://github.com/tikk3r/flocs
export FLOCSDIR=$(realpath flocs)
export LINC_DATA_ROOT=$(realpath LINC)
cd ../

# SETUP APPTAINER
SIMG=astronrd_linc.sif
mkdir -p singularity
wget https://public.spider.surfsara.nl/project/lofarvwf/fsweijen/containers/flocs_v5.6.0_znver2_znver2.sif -O singularity/$SIMG
mkdir -p singularity/pull
cp singularity/$SIMG singularity/pull/$SIMG

export APPTAINER_CACHEDIR=$PWD/singularity
export CWL_SINGULARITY_CACHE=${APPTAINER_CACHEDIR}
export APPTAINER_PULLDIR=${APPTAINER_CACHEDIR}/pull
export APPTAINER_TMPDIR=${APPTAINER_CACHEDIR}/tmp
export APPTAINERENV_LINC_DATA_ROOT=${LINC_DATA_ROOT}
export APPTAINERENV_PREPEND_PATH=${LINC_DATA_ROOT}/scripts
export APPTAINERENV_PYTHONPATH=${LINC_DATA_ROOT}/scripts:\$PYTHONPATH
export APPTAINER_BIND=${SING_BIND}
export SINGULARITYENV_PREPEND_PATH=${LINC_DATA_ROOT}/scripts
export TOIL_CHECK_ENV=True

########################

# MAKE JSON FILE
apptainer exec -B ${SING_BIND} singularity/${SIMG} \
python ${FLOCSDIR}/runners/create_ms_list.py \
LINC target \
--output_fullres_data \
--min_unflagged_fraction 0.1 \
--cal_solutions ${SOLUTIONS} \
${DATADIR}

########################

# SETUP TOIL ENVIRONMENT
WORKDIR=$PWD/workdir
OUTDIR=$PWD/outdir
JOBSTORE=$PWD/jobstore
LOGDIR=$PWD/logs
TMPD=$PWD/tmpdir

mkdir -p $WORKDIR
mkdir -p $OUTDIR
mkdir -p $LOGDIR

########################

# RUN TOIL
source ${VENV}/bin/activate # version 7.0.0?

toil-cwl-runner \
--no-read-only \
--singularity \
--bypass-file-store \
--moveExports \
--jobStore=${JOBSTORE} \
--logFile=${OUTDIR}/job_output.txt \
--workDir=${WORKDIR} \
--outdir=${OUTPUT} \
--retryCount=2 \
--writeLogs=${LOGSDIR} \
--tmp-outdir-prefix=${TMPD}/ \
--disableAutoDeployment=True \
--eval-timeout=4000 \
--preserve-environment ${APPTAINERENV_PYTHONPATH} ${SINGULARITYENV_PREPEND_PATH} ${APPTAINERENV_LINC_DATA_ROOT} ${APPTAINER_BIND} ${APPTAINER_PULLDIR} ${APPTAINER_TMPDIR} ${APPTAINER_CACHEDIR} \
--batchSystem=slurm \
${LINC_DATA_ROOT}/workflows/HBA_target_VLBI.cwl mslist_LINC_target.json

deactivate

########################

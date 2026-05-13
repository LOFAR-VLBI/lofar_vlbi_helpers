#!/bin/bash
#SBATCH -J LINTar -p infinite

######################
######## INPUT #######
######################

DATA=$PWD/data
CAL_SOLUTIONS=$(realpath $1)

######################
######################

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers

source $SCRIPT_DIR/edfn/setup.sh --no-git --no-sing
export SIMG_CACHE_DIR=/project/lofarvwf/Share/jdejong/output/EUCLID/edfn/singularity_linc
export SING_IMG=${SIMG_CACHE_DIR}/pull/astronrd_linc_latest.sif
export APPTAINER_PULLDIR=${SIMG_CACHE_DIR}/pull
export APPTAINER_CACHEDIR=${SIMG_CACHE_DIR}

ulimit -S -n 8192

# Ensure < 168 MHz
singularity exec $SIMG_CACHE_DIR/${SIMG}.sif \
python ${SCRIPT_DIR}/elais_200h/download_scripts/removebands.py \
--freqcut 168 --datafolder ${DATA}

# Fix losoto bug
export APPTAINER_BIND="${APPTAINER_BIND},${VENV}/bin/losoto:/opt/lofar/pyenv-py3/bin/losoto"
export APPTAINER_BIND="${APPTAINER_BIND},${VENV}/bin/H5parm_collector.py:/opt/lofar/pyenv-py3/bin/H5parm_collector.py"

source ${VENV}/bin/activate
flocs-run linc target \
--slurm-time "15:00:00" \
--slurm-queue "normal" \
--slurm-account lofarvwf \
--runner toil \
--scheduler slurm \
--output-fullres-data \
--cal-solutions ${CAL_SOLUTIONS} \
${DATA}
deactivate

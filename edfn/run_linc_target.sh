#!/bin/bash
#SBATCH -J LINTar -p infinite

DATA=$PWD/data
CAL_SOLUTIONS=$(abspath $1)

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

# Ensure < 168 MHz
singularity exec $SIMG_CACHE_DIR/${SIMG}.sif \
python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py \
--freqcut 168 --datafolder ${DATA}

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

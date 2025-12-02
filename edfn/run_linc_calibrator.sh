#!/bin/bash
#SBATCH -c 31
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

#SINGULARITY SETTINGS
SIMG=/project/lofarvwf/Software/singularity/flocs_v5.2.0_znver2_znver2.sif

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

# Ensure < 168 MHz
singularity exec $SING_IMG python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py --freqcut 168 --datafolder data

# Run LINC calibrator
source ${VENV}/bin/activate
flocs-run linc calibrator data
deactivate

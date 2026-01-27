#!/bin/bash
#SBATCH -c 1 -p short -t 4:00:00
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

singularity exec $SIMG_CACHE_DIR/${SIMG}.sif python ~/scripts/lofar_vlbi_helpers/elais_200h/download_scripts/removebands.py --freqcut 168 --datafolder data

# Run LINC calibrator
source ${VENV}/bin/activate
flocs-run linc calibrator \
--slurm-time "1:00:00" \
--slurm-queue "normal" \
--slurm-account lofarvwf \
--runner cwltool \
--scheduler slurm data
deactivate

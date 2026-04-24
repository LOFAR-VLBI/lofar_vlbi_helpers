#!/bin/bash
#SBATCH -c 1
#SBATCH --output=delay_%j.out
#SBATCH --error=delay_%j.err
#SBATCH -p infinite

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/lirgs

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

source ${VENV}/bin/activate
flocs-run vlbi delay-calibration \
--slurm-time "72:00:00" \
--slurm-queue "normal" \
--slurm-account lofarvwf \
--runner toil \
--scheduler slurm \
--ms-suffix "dp3concat" \ #VERIFY
--do-auto-delay-selection \
$(realpath ../target/LINC_target_*/results_LINC_target/results)
deactivate

#!/bin/bash
#SBATCH -c 1 -p infinite,normal

CATALOGUE=$1

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/targets
MODELCACHE=/project/lofarvwf/Software/modelcache/cortexchange

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

source ${VENV}/bin/activate
flocs-run vlbi dd-calibration \
--slurm-time "72:00:00" \
--slurm-queue "normal" \
--slurm-account lofarvwf \
--runner toil \
--scheduler slurm \
--ms-suffix "dp3concat" \
--delay-solset $(realpath ../delaycal/*VLBI_delay-calibration*/results_VLBI_delay-calibration/merged*.h5) \
--source-catalogue $(realpath ${CATALOGUE}) \
--no-validate \
--no-dd-selection \
--model-cache ${MODELCACHE} \
$(realpath ../target/LINC_target_*/results_LINC_target/results)
deactivate

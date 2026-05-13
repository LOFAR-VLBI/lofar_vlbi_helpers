#!/bin/bash
#SBATCH -p infinite -c 1

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

BAD_NODES=$( source ${SCRIPT_DIR}/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="--exclude=${BAD_NODES}"
fi

source ${VENV}/bin/activate

python ../../run_plot_field.py --ms ../target/*LINC_target_*/results_LINC_target/results/*.dp3concat

flocs-run vlbi delay-calibration \
--slurm-time "96:00:00" \
--slurm-queue "normal" \
--slurm-account lofarvwf \
--runner toil \
--scheduler slurm \
--ddf-solsdir $(realpath ../ddf/SOLSDIR) \
--ddf-rundir $(realpath ../ddf) \
--do-subtraction \
--do-validation \
--ms-suffix "dp3concat" \
--apply-delay-solutions \
--do-auto-delay-selection \
--delay-calibrator $(realpath delay_calibrators.csv) \
$(realpath ../target/*LINC_target_*/results_LINC_target/results)
deactivate

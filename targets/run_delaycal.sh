#!/bin/bash
#SBATCH -c 1 -p infinite,normal

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/targets
STARTDIR=$PWD

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

source ${VENV}/bin/activate

python ../../run_plot_field.py --ms ../target/LINCrun/LINC_target_L*/results_LINC_target/results/*.ms

BAD_NODES=$( source /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="--exclude=${BAD_NODES}"
fi

export APPTAINER_BIND="${APPTAINER_BIND},/project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal:/opt/lofar/pyenv-py3/lib/python3.12/site-packages/facetselfcal"

sleep 10

source ${VENV}/bin/activate
flocs-run vlbi delay-calibration \
--slurm-time "96:00:00" \
--slurm-queue "normal,infinite" \
--slurm-account lofarvwf \
--runner toil \
--scheduler slurm \
--model-image $(realpath VLASS*.fits) \
--do-validation \
--ms-suffix "dp3concat" \
--delay-calibrator $(realpath delay_calibrators.csv) \
$(realpath ../target/LINCrun/LINC_target_*/results_LINC_target/results)
deactivate

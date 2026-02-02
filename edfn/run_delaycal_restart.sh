#!/bin/bash
#SBATCH -c 1
#SBATCH --output=delay_%j.out
#SBATCH --error=delay_%j.err
#SBATCH -p infinite

SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

ulimit -S -n 8192

BAD_NODES=$( source /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/detect_bad_slurm_nodes.sh )

if [[ -n "${BAD_NODES}" ]]; then
    export TOIL_SLURM_ARGS="--exclude=${BAD_NODES}"
fi

export APPTAINER_BIND="${APPTAINER_BIND},/project/lofarvwf/Software/lofar_facet_selfcal/facetselfcal.py:/opt/lofar/pyenv-py3/bin/facetselfcal"

source ${VENV}/bin/activate
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
--restart \
--ms-suffix "dp3concat" \
--apply-delay-solutions \
--do-auto-delay-selection \
--delay-calibrator $(realpath delay_calibrators.csv) \
$(realpath ../target/LINC_target_*/results_LINC_target/results)
deactivate

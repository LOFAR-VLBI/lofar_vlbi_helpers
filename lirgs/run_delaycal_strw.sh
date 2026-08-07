#!/bin/bash

rm /net/rijn10/data2/jurjendejong/LIRGS/singularity/pull/node_alpine.sif

export LINC_DATA_ROOT=/net/rijn10/data2/jurjendejong/LIRGS/LINC
export VLBI_DATA_ROOT=/net/rijn10/data2/jurjendejong/LIRGS/pilot

export SIMG_CACHE_DIR=/net/rijn10/data2/jurjendejong/LIRGS/singularity
export CWL_SINGULARITY_CACHE=${SIMG_CACHE_DIR}
export APPTAINER_PULLDIR=${SIMG_CACHE_DIR}/pull
export APPTAINER_CACHEDIR=${SIMG_CACHE_DIR}
export APPTAINERENV_PREPEND_PATH=${LINC_DATA_ROOT}/scripts:${VLBI_DATA_ROOT}/scripts
export APPTAINERENV_PYTHONPATH=${VLBI_DATA_ROOT}/scripts:${LINC_DATA_ROOT}/scripts:\$PYTHONPATH
export APPTAINER_BIND=/net/rijn10

source /net/rijn10/data2/jurjendejong/LIRGS/venv3.12/bin/activate

python /project/lofarvwf/Share/jdejong/output/EUCLID/edfn/run_plot_field.py --ms ../data/*pre-cal.ms

flocs-run vlbi delay-calibration \
--runner cwltool \
--scheduler singleMachine \
--ms-suffix "dp3concat" \
--delay-calibrator $(realpath delay_calibrators.csv) \
$(realpath ../data)
deactivate

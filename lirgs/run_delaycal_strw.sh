#!/bin/bash

export LINC_DATA_ROOT=$(realpath LINC)
export VLBI_DATA_ROOT=$(realpath pilot)

ulimit -S -n 8192

source /net/rijn10/data2/jurjendejong/LIRGS/venv/bin/activate
flocs-run vlbi delay-calibration \
--runner cwltool \
--scheduler singleMachine \
--ms-suffix "dp3concat" \
$(realpath ../target/LINC_target_*/results_LINC_target/results)
deactivate

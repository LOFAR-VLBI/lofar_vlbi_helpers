#!/bin/bash
#SBATCH -p short

RA=$1
DEC=$2
STAGE_PRODUCTS=$3
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

source ${VENV}/bin/activate

flocs-lta search-position \
--ra ${RA} \
--dec ${DEC} \
--max-radius 1.25 \
--min-duration 0.9 \
--freq-start 115 \
--freq-end 170 \
--stage-products ${STAGE_PRODUCTS}

deactivate

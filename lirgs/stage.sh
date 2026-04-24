#!/bin/bash
#SBATCH -p short

RA=$1
DEC=$2
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/lirgs

source $SCRIPT_DIR/setup.sh --no-git --no-sing

singularity exec /project/lofarvwf/Share/jdejong/output/test_lotss_subtract/singularity/pull/vlbi-cwl_latest.sif \
python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_search_lta.py \
--ra ${RA} \
--dec ${DEC} \
--max-radius 1.25 \
--min-duration 0.9 \
--freq_start 115 \
--freq_end 170 \
--stage-products "both"

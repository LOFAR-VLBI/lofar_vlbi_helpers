#!/bin/bash

SASID=$1
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

source $SCRIPT_DIR/setup.sh --no-git --no-sing

mkdir -p L${SASID}

cd $MASTERDIR/L${SASID}

singularity exec $SING_IMG python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_search_lta.py \
--sasid $SASID \
--project ALL \
--stage

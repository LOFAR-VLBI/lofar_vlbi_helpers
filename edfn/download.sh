#!/bin/bash

STAGE_ID=$1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source $SCRIPT_DIR/setup.sh --no-git --no-sing

cd $MASTERDIR/L${STAGE_ID}

singularity exec $SING_IMG python $SOFTWARE_DIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID

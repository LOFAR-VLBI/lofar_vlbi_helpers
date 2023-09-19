#!/bin/bash
#SBATCH -N 1 -c 8 -t 72:00:00

#SINGULARITY SETTINGS
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SING_BIND=$( python3 $SCRIPT_DIR/parse_settings.py --BIND )
SIMG=$( python3 $SCRIPT_DIR/parse_settings.py --SIMG )

DATA=$1

printf "Run LINC calibrator from $SCRIPT_DIR on Data in $DATA"
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_calibrator.sh -d $DATA

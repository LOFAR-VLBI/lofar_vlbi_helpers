#!/bin/bash
#SBATCH -N 1 -c 8 -t 72:00:00

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

DATA=$1

singularity exec -B ${SING_BIND} ${SIMG} run_LINC_calibrator.sh -d $DATA
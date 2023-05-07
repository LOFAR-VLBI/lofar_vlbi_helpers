#!/bin/bash
#SBATCH -N 1 -c 6 --job-name=single_job

PARSET=$1

#SINGULARITY
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

#RUN
singularity exec -B $SING_BIND ${SIMG} DP3 ${PARSET}

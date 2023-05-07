#!/bin/bash
#SBATCH -N 1 -c 2 --job-name=concat_parset

PARSET=$1

#SINGULARITY
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

#RUN
singularity exec -B $SING_BIND $SIMG DP3 ${PARSET}

mv ${PARSET} concat_parsets

#!/bin/bash
#SBATCH -c 6 --job-name=phaseshift --array=0-10 --constraint=amd

#SINGULARITY
SING_BIND=$( python $HOME/parse_settings.py --BIND )
SIMG=$( python $HOME/parse_settings.py --SIMG )
echo "SINGULARITY IS $SIMG"

echo "Job landed on $(hostname)"

pattern="*.parset"
files=( $pattern )
N=${SLURM_ARRAY_TASK_ID}

#RUN
singularity exec -B $SING_BIND $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"

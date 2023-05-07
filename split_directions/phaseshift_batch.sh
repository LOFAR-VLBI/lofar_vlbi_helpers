#!/bin/bash
#SBATCH -c 6 --job-name=phaseshift --array=0-4999%1000 --constraint=amd

#SINGULARITY
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

OFFSET=$1 # OFFSET BECAUSE SLURM CAN ONLY HAVE MAX 1000

echo "Job landed on $(hostname)"

pattern="*MHz*.parset"
files=( $pattern )
N=$(( ${SLURM_ARRAY_TASK_ID}+${OFFSET} ))

#RUN
singularity exec -B $SING_BIND $SIMG DP3 ${files[${N}]}
echo "Launched script for ${files[${N}]}"

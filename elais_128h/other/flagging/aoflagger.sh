#!/bin/bash
#SBATCH -c 15 --job-name=aoflagger --array=0-23 --constraint=amd -t 10:00:00

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

pattern="*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

singularity exec -B $PWD ${SIMG} aoflagger ${MS}

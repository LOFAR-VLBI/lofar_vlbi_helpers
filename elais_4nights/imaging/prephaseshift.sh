#!/bin/bash
#SBATCH -c 5
#SBATCH --array=0-100
#SBATCH -t 10:00:00

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

pattern="avg*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

singularity exec -B $SING_BIND $SIMG DP3 \
msin=${MS} \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout.overwrite=True \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps] \
ps.type=phaseshifter \
ps.phasecenter=[16h11m00.00000,54d57m00.0000]

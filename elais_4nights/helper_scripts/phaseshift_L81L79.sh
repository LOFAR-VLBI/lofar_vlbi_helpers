#!/bin/bash
#SBATCH -c 5
#SBATCH --array=0-25

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

pattern="../avg*L81*.ms"
MS_FILES=( $pattern )
MS=${MS_FILES[${SLURM_ARRAY_TASK_ID}]}

singularity exec -B $SING_BIND $SIMG DP3 \
msin=${MS} \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout=PS_SB_${SLURM_ARRAY_TASK_ID} \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps] \
ps.type=phaseshifter \
ps.phasecenter=[16h11m00.00000,54d57m00.0000]

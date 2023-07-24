#!/bin/bash
#SBATCH -c 5

NIGHT=$1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

singularity exec -B $SING_BIND $SIMG DP3 \
msin=avg_applycal_sub6asec_${NIGHT}* \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout=concat_${NIGHT}.ms \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[]
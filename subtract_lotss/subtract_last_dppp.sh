#!/bin/bash
#SBATCH -N 1 -c 31 --job-name=subtract

OBSERVATION=$1

SIMG=$( python ../parse_settings.py --SIMG )
SING_BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

echo "Start last command"
singularity exec -B $SING_BIND $SIMG DPPP msin=${OBSERVATION} \
msout.writefullresflag=False steps=[average] average.timestep=1 average.freqstep=1 msin.weightcolumn=WEIGHT_SPECTRUM \
msout.storagemanager=dysco msout=sub6asec_${OBSERVATION}.sub.shift.avg.ms \
msin.datacolumn=DATA_SUB
echo "Finished"
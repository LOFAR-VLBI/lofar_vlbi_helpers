#!/bin/bash
#SBATCH -N 1 -c 31 --job-name=subtract

OBSERVATION=$1

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo "Start last command"
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DPPP msin=${OBSERVATION} \
msout.writefullresflag=False steps=[average] average.timestep=1 average.freqstep=1 msin.weightcolumn=WEIGHT_SPECTRUM \
msout.storagemanager=dysco msout=sub6asec_${OBSERVATION}.sub.shift.avg.ms \
msout.storagemanager.databitrate=4 msout.storagemanager.weightbitrate=8 msin.datacolumn=DATA_SUB
echo "Finished"
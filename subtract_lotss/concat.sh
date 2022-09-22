#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=concat

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 \
msin=sub6asec*.ms \
msin.datacolumn=DATA \
msout=${OBSERVATION}_120_168MHz_averaged.ms \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps,avg] \
ps.type=phaseshifter \
ps.phasecenter=[16h06m07.61855,55d21m35.4166] \
avg.type=averager \
avg.freqstep=8 \
avg.timestep=4

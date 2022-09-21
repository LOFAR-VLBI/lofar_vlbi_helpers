#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_main

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DPPP \
msin=sub6asec_L*.ms \
msin.datacolumn=DATA \
msout=TargetName_120_168MHz_averaged.ms \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[ps, av] \
ps.type=phaseshift \
ps.phasecenter=[16h06m07.61855,55d21m35.4166] \
av.type=averager \
av.freqstep=8 \
av.timestep=4

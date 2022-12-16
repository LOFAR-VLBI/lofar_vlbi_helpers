#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=concat

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

#ls sub6asec*.ms -1d > "mslist.txt"

# check input
#singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
#python /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/check_missing_freqs_in_ms.py --ms sub6asec*.ms --make_dummies

MS_VECTOR=[$(cat  mslist.txt |tr "\n" ",")]

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 \
msin=${MS_VECTOR} \
msin.orderms=False \
msin.missingdata=True \
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

# check output
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
python /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/check_missing_freqs_in_ms.py --ms ${OBSERVATION}_120_168MHz_averaged.ms
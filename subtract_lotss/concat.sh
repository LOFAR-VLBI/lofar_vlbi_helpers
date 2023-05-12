#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=concat

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

SIMG=$( python $HOME/parse_settings.py --SIMG )
SING_BIND=$( python $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

ls sub6asec*.ms -1d > "mslist.txt"

#TODO:upgrade this script (dummy now in wrong order)
# check input
#singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
#python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py --ms sub6asec*.ms --make_dummies

MS_VECTOR=[$(cat  mslist.txt |tr "\n" ",")]

singularity exec -B $SING_BIND $SIMG DP3 \
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
avg.freqresolution='97656.25kHz' \
avg.timeresolution=4

# check output
singularity exec -B $SING_BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py --ms ${OBSERVATION}_120_168MHz_averaged.ms --make_dummies

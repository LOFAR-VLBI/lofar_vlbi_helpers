#!/bin/bash
#SBATCH -c 10

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

singularity exec -B $SING_BIND $SIMG python /project/lofarvwf/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--msin sub6asec*.ms \
--time_res 4 \
--freq_res '97656.25Hz' \
--phase_center '[16h06m07.61855,55d21m35.4166]' \
--msout ${OBSERVATION}_DI.concat.ms

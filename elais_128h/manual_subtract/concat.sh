#!/bin/bash
#SBATCH -c 18 -t 12:00:00

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

singularity exec -B $SING_BIND $SIMG python /project/wfedfn/Software/lofar_helpers/ms_helpers/concat_with_dummies.py \
--msin sub6asec_L720380*.ms \
--time_res 8 \
--freq_res '97656.25Hz' \
--phase_center '[17h53m31.44,66d27m25.20]' \
--msout J175331+662725_DI.concat.ms

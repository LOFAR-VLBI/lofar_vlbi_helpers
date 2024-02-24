#!/bin/bash
#SBATCH -c 5
#SBATCH --job-name=concat

#INPUT
NIGHT=$1

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v4.0.2_znver2_znver2_noavx512_ddf_10_02_2023.sif

singularity exec -B $SING_BIND $SIMG python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py \
--ms avg_*${NIGHT}*.ms --make_dummies --output_name ${NIGHT}_list.txt

MS_VECTOR=[$(cat  ${NIGHT}_list.txt |tr "\n" ",")]

singularity exec -B $SING_BIND $SIMG DP3 \
msin=${MS_VECTOR} \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout=concat_${NIGHT}.ms \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[]

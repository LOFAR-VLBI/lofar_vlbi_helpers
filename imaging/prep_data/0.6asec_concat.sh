#!/bin/bash
#SBATCH -c 10
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_0.6

NIGHT=$1

echo $SLURM_JOB_NAME

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

OUT_DIR=$PWD
cd ${OUT_DIR}

singularity exec -B $SING_BIND $SIMG python \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/extra_scripts/check_missing_freqs_in_ms.py \
--ms avg0.6*${NIGHT}*.ms \
--make_dummies --output_name ${NIGHT}_list.txt

MS_VECTOR=[$(cat  ${NIGHT}_list.txt |tr "\n" ",")]

echo "Start concat..."

#Averaging
singularity exec -B ${SING_BIND} ${SIMG} DP3 \
msin=${MS_VECTOR} \
msout=concat_${NIGHT}.ms \
msin.datacolumn=DATA \
msout.storagemanager=dysco \
msout.writefullresflag=False \
msin.orderms=False \
msin.missingdata=True \
steps=[]

echo "...Finished concat"

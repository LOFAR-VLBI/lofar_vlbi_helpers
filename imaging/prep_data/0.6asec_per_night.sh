#!/bin/bash
#SBATCH -c 6
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

echo "Copy data from applycal folder..."

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/applycal*${NIGHT}*.ms .

echo "...Finished copying from applycal folder"

echo "Average data in DPPP..."

for MS in applycal*.ms
do
  #Averaging
  singularity exec -B ${SING_BIND} ${SIMG} DP3 \
  msin=${MS} \
  msout=avg_${MS} \
  msin.datacolumn=DATA \
  msout.storagemanager=dysco \
  msout.writefullresflag=False \
  steps=[avg] \
  avg.type=averager \
  avg.freqstep=2 \
  avg.timeresolution=2

  rm -rf ${MS}

done

echo "... Finished averaging data in DPPP"

#MSLIST
#ls -1 -d applycal* > mslist.txt
#
#MS_VECTOR=[$(cat  mslist.txt |tr "\n" ",")]
#
#echo "Concat data..."

#CONCAT
#singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
#msin=${MS_VECTOR} \
#msin.orderms=False \
#msin.missingdata=True \
#msin.datacolumn=DATA \
#msout=${OBSERVATION}_120_168MHz_applied_bda.ms \
#msout.storagemanager=dysco \
#msout.writefullresflag=False \
#steps=[bda] \
#bda.type=bdaaverager \
#bda.maxinterval=64. \
#bda.timebase=4000000

echo "...Finished concat"

# CHECK OUTPUT
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
python ../../extra_scripts/check_missing_freqs_in_ms.py \
--ms avg*


mkdir DATA
cp -r *.ms DATA

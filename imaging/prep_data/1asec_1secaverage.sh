#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=intel
#SBATCH -p infinite
#SBATCH --job-name=prep_1asec_1sec

echo $SLURM_JOB_NAME

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/home/lofarvwf-jdejong/singularities/idgtest_23_02_2022.sif

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

OUT_DIR=$PWD
cd ${OUT_DIR}

echo "Copy data from applycal folder..."

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/apply_delaycal/applycal*.ms .

echo "...Finished copying from applycal folder"

echo "Average data in DPPP..."

for MS in applycal*.ms
do
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
  msin=${MS} \
  msout=avg_${MS} \
  msin.datacolumn=DATA \
  msout.storagemanager=dysco \
  msout.writefullresflag=False \
  steps=[avg] \
  avg.type=averager \
  avg.freqstep=4 \
  avg.timestep=4

  rm -rf ${MS}

done

echo "... Finished averaging data in DPPP"

#MSLIST
ls -1 -d avg_applycal* > mslist.txt

MS_VECTOR=[$(cat  mslist.txt |tr "\n" ",")]

echo "Concat data..."

#CONCAT
singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
msin=${MS_VECTOR} \
msin.orderms=False \
msin.missingdata=True \
msin.datacolumn=DATA \
msout=${OBSERVATION}_120_168MHz_averaged_applied.ms \
msout.storagemanager=dysco \
msout.writefullresflag=False \
steps=[] \

echo "...Finished concat"

# check output
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
python /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/check_missing_freqs_in_ms.py \
--ms ${OBSERVATION}_120_168MHz_averaged_applied.ms

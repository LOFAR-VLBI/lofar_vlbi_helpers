#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_bda_0.3asec_2sec

echo $SLURM_JOB_NAME

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

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
  #Averaging
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN} DP3 \
  msin=${MS} \
  msout=avg_${MS} \
  msin.datacolumn=DATA \
  msout.storagemanager=dysco \
  msout.writefullresflag=False \
  steps=[avg] \
  avg.type=averager \
  avg.freqstep=4 \
  avg.timestep=2

#  rm -rf ${MS}

  #Baseline-dependent-averaging
  singularity exec -B ${SING_BIND} ${SING_IMAGE_WSCLEAN}  DP3 \
  msin=avg_${MS} \
  msout=bdaavg_${MS} \
  steps=[bda] \
  bda.type=bdaaverager \
  bda.maxinterval=64. \
  bda.timebase=1000000

  rm -rf avg_${MS}

done

echo "... Finished averaging data in DPPP"

#MSLIST
#ls -1 -d avg_* > mslist.txt
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
#msout=${OBSERVATION}_120_168MHz_averaged_applied_bda.ms \
#msout.storagemanager=dysco \
#msout.writefullresflag=False \
#steps=[bda] \
#bda.type=bdaaverager \
#bda.maxinterval=64. \
#bda.timebase=1000000

echo "...Finished concat"

# check output
#singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
#python /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/check_missing_freqs_in_ms.py \
#--ms ${OBSERVATION}_120_168MHz_averaged_applied_bda.ms

rm -rf applycal*

mkdir DATA
cp -r *.ms DATA
#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --job-name=prep_1asec_1sec

echo $SLURM_JOB_NAME

#SINGULARITY SETTINGS
SING_BIND=/project/lofarvwf/Share/jdejong,/home
SING_IMAGE_WSCLEAN=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif


OUT_DIR=$PWD
cd ${OUT_DIR}

echo "Copy data from applycal folder..."

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/apply_delaycal/applycal*.ms .

echo "...Finished copying from applycal folder"

echo "Average data in DPPP..."

#Average to 4seconds and 4ch/SB
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
  avg.timeresolution=4

  rm -rf ${MS}

done

echo "... Finished averaging data in DPPP"

#MSLIST
ls -1 -d avg_applycal* > mslist.txt

mkdir DATA
cp -r *.ms DATA
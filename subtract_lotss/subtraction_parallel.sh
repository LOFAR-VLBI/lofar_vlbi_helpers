#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

RUNDIR=$1
DIR=${RUNDIR}/subtract_lotss/

cd ${DIR}

for FILE in L*.ms
do
  echo "${FILE}"
  mkdir ${FILE}_output
  cp image_full* ${FILE}_output
  cp image_dirin_SSD_m.npy.ClusterCat.npy ${FILE}_output
  cp DDS3* ${FILE}_output
  cp boxfile.reg ${FILE}_output
  cp cutoutmask.fits ${FILE}_output
  cp -r SOLSDIR ${FILE}_output
  cp -r ${FILE} ${FILE}_output
  cd ${FILE}_output
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh $FILE
done
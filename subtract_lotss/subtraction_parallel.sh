#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

OBSERVATION=$1

mkdir -p subtract_lotss
DIR=subtract_lotss/
DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/

cd ${DIR}

for FILE in ${OBSERVATION}*.ms
do
  echo "${FILE}"
  mkdir ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy ${FILE}_suboutput
  cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz ${FILE}_suboutput
  cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz ${FILE}_suboutput
  cp boxfile.reg ${FILE}_suboutput
  cp cutoutmask.fits ${FILE}_suboutput
  cp -r SOLSDIR ${FILE}_suboutput
  mv ${FILE} ${FILE}_suboutput
  cd ${FILE}_suboutput
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh ${FILE}
  cd ../
done






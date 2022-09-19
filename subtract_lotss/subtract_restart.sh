#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

echo "SUBTRACT START ${OBSERVATION}"

DIR=subtract_lotss/
DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/

cp -r Input/*msdpppconcat subtract_lotss

cd ${DIR}

rm -r ${OBSERVATION}*_suboutput

for FILE in ${OBSERVATION}*.msdpppconcat
do
  echo "${FILE}"
  mkdir -p ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits ${FILE}_suboutput
  cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy ${FILE}_suboutput
  cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz ${FILE}_suboutput
  cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz ${FILE}_suboutput
  cp boxfile.reg ${FILE}_suboutput
  cp cutoutmask.fits ${FILE}_suboutput
  cp -r ${DDF_OUTPUT}/SOLSDIR ${FILE}_suboutput
  mv -r ${FILE} ${FILE}_suboutput
  cd ${FILE}_suboutput
  echo ${FILE} > mslist.txt
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh mslist.txt
  cd ../
done


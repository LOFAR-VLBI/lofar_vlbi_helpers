#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi
echo echo "SUBTRACT START ${OBSERVATION}"

DIR=subtract_lotss/
DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/

cd ${DIR}

for FILE in ${OBSERVATION}*.ms
do
  echo "Subtract ${FILE}"
  mkdir -p ${FILE}_subrun
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel ${FILE}_subrun
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits ${FILE}_subrun
  cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy ${FILE}_subrun
  cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz ${FILE}_subrun
  cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz ${FILE}_subrun
  cp /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/boxfile.reg ${FILE}_subrun
  #cp cutoutmask.fits ${FILE}_subrun
  cp -r ${DDF_OUTPUT}/SOLSDIR ${FILE}_subrun
  mv /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/Input/${FILE} ${FILE}_subrun
  cd ${FILE}_subrun
  echo ${FILE} > mslist.txt
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh mslist.txt
  cd ../
done

#Refresh the Input
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/delaycal/Delay-Calibration/L*.msdpppconcat /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/Input
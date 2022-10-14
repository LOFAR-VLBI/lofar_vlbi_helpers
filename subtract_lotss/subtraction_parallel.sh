#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_distribute

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi
echo "SUBTRACT START ${OBSERVATION}"

mkdir -p subtract_lotss

DIR=subtract_lotss/
DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/
DELAYCAL_RESULT=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/delaycal/Delay-Calibration

cd ${DIR}

MAX_PARALLEL=4
nroffiles=$(ls ${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat | wc -w)
setsize=$(( nroffiles/MAX_PARALLEL + 1 ))
ls -1 ${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat | xargs -n "$setsize" | while read file; do
  cp -r ${file} . &
done
wait

for FILE in ${OBSERVATION}*.msdpppconcat
do
  echo "Subtract ${FILE}"
  if [[ ${FILE} =~ $re_subband ]]; then SUBBAND=${BASH_REMATCH}; fi
  mkdir -p ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/${OBSERVATION}crossmatch-results-2.npy ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/${OBSERVATION}freqs.npy ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz ${SUBBAND}_subrun
  cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz ${SUBBAND}_subrun
  cp /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/boxfile.reg ${SUBBAND}_subrun
  #cp cutoutmask.fits ${SUBBAND}_subrun
  cp -r ${DDF_OUTPUT}/SOLSDIR ${SUBBAND}_subrun
  mv ${FILE} ${SUBBAND}_subrun/${SUBBAND}.pre-cal.ms
  cd ${SUBBAND}_subrun
  echo ${SUBBAND}.pre-cal.ms > mslist.txt
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh mslist.txt
  cd ../
done

#!/bin/bash
#SBATCH -N 1 -c 8 --job-name=subtract_main

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
re_subband="([^.]+)"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

DELAYCAL_RESULT=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/delaycal/Delay-Calibration
DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf/
DIR=subtract_lotss

mkdir -p subtract_lotss

echo "Make boxfile: boxfile.reg with /home/lofarvwf-jdejong/scripts/lofar-highres-widefield/utils/make_box.py"

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG python \
/home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/make_box.py \
${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat 2.5

cd ${DIR}

echo "COPY DATA ${OBSERVATION}"

MAX_PARALLEL=8
nroffiles=$(ls ${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat | wc -w)
setsize=$(( nroffiles/MAX_PARALLEL + 1 ))
ls -d ${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat | xargs -n "$setsize" | while read file; do
  cp -r ${file} . &
done
wait

echo "SUBTRACT START ${OBSERVATION}"

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
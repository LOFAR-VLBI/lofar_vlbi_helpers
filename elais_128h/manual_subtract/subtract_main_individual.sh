#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=subtract -t 24:00:00

echo "Job landed on $(hostname)"

re_subband="([^.]+)"

FILE=$1

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

DDF_OUTPUT=$(realpath "../ddf")
RESULT=$PWD/concatted_ms

echo "Subtract ${FILE}"
SUBBAND=${FILE##*/}
mkdir -p ${SUBBAND}_subrun
cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.DicoModel ${SUBBAND}_subrun
cp ${DDF_OUTPUT}/image_full_ampphase_di_m.NS.mask01.fits ${SUBBAND}_subrun
cp ${DDF_OUTPUT}/image_dirin_SSD_m.npy.ClusterCat.npy ${SUBBAND}_subrun
cp ${DDF_OUTPUT}/DDS3_full_*_merged.npz ${SUBBAND}_subrun
cp ${DDF_OUTPUT}/DDS3_full_*_smoothed.npz ${SUBBAND}_subrun
cp /project/lofarvwf/Share/jdejong/output/ELAIS/boxfile.reg ${SUBBAND}_subrun
cp -r ${DDF_OUTPUT}/SOLSDIR ${SUBBAND}_subrun
cp -r ${FILE} ${SUBBAND}_subrun
cd ${SUBBAND}_subrun
echo ${SUBBAND} > mslist.txt
sbatch /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/cwl_widefield_imaging/manual_subtract/subtraction.sh ${SUBBAND}
cd ../

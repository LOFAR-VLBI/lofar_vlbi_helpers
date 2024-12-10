#!/bin/bash
#SBATCH -N 1 -c 16 -t 120:00:00 --constraint=intel --job-name=delay-calibration

echo Job landed on $(hostname)

INPUT_DATA=$1#"Delay-Calibration/L??????_SB001_uv_*t_???MHz.msdpppconcat"
OUTPUT_FILE=$2#"/project/lofarvwf/Share/rtimmerman/CDGS54/concat/LBCS_120_168MHz_averaged.ms"
COORDS="14h21m18.55,53d03m28.0"

SIMG="/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.4_x86-64_generic_avx512_ddf.sif"

if [ ! -z $COORDS ]
then
    echo ADDING PHASESHIFT TO COORDINATES $COORDS
    PHASESHIFT_STEP="ps,"
    PHASESHIFT_TASK="\nps.type=phaseshift\nps.phasecenter=[$COORDS]\n"
else
    echo NO PHASESHIFT REQUIRED
    PHASESHIFT_STEP=""
    PHASESHIFT_TASK=""
fi

echo RETRIEVING TEMPLATE PARSET ...

cp /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/prefactor_pipeline/dppp_phaseup.parset .

sed -i "s%INPUT_DATA%$INPUT_DATA%g" dppp_phaseup.parset
sed -i "s?OUTPUT_FILE?$OUTPUT_FILE?g" dppp_phaseup.parset
sed -i "s?PHASESHIFT_STEP?$PHASESHIFT_STEP?g" dppp_phaseup.parset
sed -i "s?PHASESHIFT_TASK?$PHASESHIFT_TASK?g" dppp_phaseup.parset

echo "EXECUTING PHASEUP"

singularity exec -B $PWD,/project $SIMG DPPP dppp_phaseup.parset

echo "PERFORMING FINAL CLEANUP"

rm -rf dppp_phaseup.parset

echo "PHASEUP FINISHED"

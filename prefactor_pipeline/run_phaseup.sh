#!/bin/bash
#SBATCH -N 1 -c 16 -t 120:00:00 --constraint=intel --job-name=delay-calibration

echo "Job landed on $(hostname)"

export OUTPUT_FILE=/project/lofarvwf/Share/rtimmerman/CDGS54/concat/LBCS_120_168MHz_averaged.ms
export INPUT_DATA=Delay-Calibration/L823948_SB001_uv_131F5D695t*.msdpppconcat
export COORDS="14h21m18.55,53d03m28.0"

export SIMG=/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.4_x86-64_generic_avx512_ddf.sif

if [-z $COORDS]
then
    export PHASESHIFT_STEP = "ps,"
    export PHASESHIFT_TASK = "ps.type=phaseshift ps.phasecenter=[$COORDS]"
else
    export PHASESHIFT_STEP = ""
    export PHASESHIFT_TASK = ""
fi

echo "RETRIEVING TEMPLATE PARSET ..."

cp ~/scripts/prefactor_helpers/prefactor_pipeline/dppp_phaseup.parset .

sed -i "s?INPUT_DATA?$INPUT_DATA?g" dppp_phaseup.parset
sed -i "s?OUTPUT_FILE?$OUTPUT_FILE?g" dppp_phaseup.parset
sed -i "s?PHASESHIFT_STEP?$PHASESHIFT_STEP?g" dppp_phaseup.parset
sed -i "s?PHASESHIFT_TASK?$PHASESHIFT_TASK?g" dppp_phaseup.parset

#singularity exec -B $PWD,/project $SIMG DPPP dppp_phaseup.parset 

#rm -rf dppp_phaseup.parset

echo "... done"
echo "PHASEUP FINISHED"

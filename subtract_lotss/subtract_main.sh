#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=subtract_main

echo "Job landed on $(hostname)"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

DELAYCAL_RESULT=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/delaycal/Delay-Calibration
SIMG=/project/lofarvwf/Software/singularity/testpatch_lofar_sksp_v3.4_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

mkdir -p Input

echo "Copy input data to Input"

cp -r ${DELAYCAL_RESULT}/${OBSERVATION}*.msdpppconcat Input

mkdir -p subtract_lotss

echo "Make boxfile: boxfile.reg with /home/lofarvwf-jdejong/scripts/lofar-highres-widefield/utils/make_box.py"

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG /home/lofarvwf-jdejong/scripts/lofar-highres-widefield/utils/make_box.py msfile Input/*.msdpppconcat 2.5

echo "SUBTRACT SETUP FINISHED"

sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction_parallel.sh
#!/bin/bash
#SBATCH -N 1 -c 16 --constraint=intel --job-name=subtract

DELAYCAL_RESULT=$1

export RUNDIR=$PWD
export SIMG=/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.5_cascadelake_cascadelake_avx512_cuda11_3_ddf.sif

mkdir Input
cp -r DELAYCAL_RESULT/L*.msdpppconcat Input

sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" subtract_lotss.parset

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG genericpipeline.py -d -c pipeline.cfg subtract_lotss.parset

echo "... done"
echo "SUBTRACT FINISHED"
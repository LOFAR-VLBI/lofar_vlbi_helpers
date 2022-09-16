#!/bin/bash
#SBATCH -N 1 -c 16 --job-name=subtract

echo "Job landed on $(hostname)"

export DELAYCAL_RESULT=$1
export RUNDIR=$PWD
export DDF_OUTPUT=$2
export SIMG=/project/lofarvwf/Software/singularity/testpatch_lofar_sksp_v3.4_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

mkdir -p Input

cp -r ${DELAYCAL_RESULT}/L*.msdpppconcat Input

cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/prefactor_pipeline/pipeline.cfg .
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtract_lotss.parset .

sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" subtract_lotss.parset
sed -i "s?DDF_OUTPUT?$DDF_OUTPUT?g" subtract_lotss.parset

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG CleanSHM.py
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG genericpipeline.py -d -c pipeline.cfg subtract_lotss.parset

echo "... done"
echo "SUBTRACT SETUP FINISHED"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $RUNDIR =~ $re ]]; then LNUM=${BASH_REMATCH}; fi
echo echo "SUBTRACT START ${LNUM}"

sbatch subtraction_parallel.sh ${LNUM}
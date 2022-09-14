#!/bin/bash
#SBATCH -N 1 -c 16 --constraint=intel --job-name=subtract

echo "Job landed on $(hostname)"

export DELAYCAL_RESULT=$1
export RUNDIR=$PWD
export DDF_OUTPUT=$2
export SIMG=/project/lofarvwf/Software/singularity/testpatch_lofar_sksp_v3.4_cascadelake_cascadelake_avx512_mkl_cuda_ddf.sif

#mkdir -p Input
#mkdir -p subtract_lotss
#mkdir -p subtract_lotss/SOLSDIR

#cp -r ${DDF_OUTPUT}/SOLSDIR/* subtract_lotss/SOLSDIR
#cp -r ${DELAYCAL_RESULT}/L*.msdpppconcat Input
#cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/prefactor_pipeline/pipeline.cfg .
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/continue_subtract_lotss.parset .

#singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts python /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/change_folder_name.py --path $PWD/subtract_lotss/SOLSDIR

sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" continue_subtract_lotss.parset
sed -i "s?DDF_OUTPUT?$DDF_OUTPUT?g" continue_subtract_lotss.parset

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG CleanSHM.py
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG genericpipeline.py -d -c pipeline.cfg continue_subtract_lotss.parset

echo "... done"
echo "SUBTRACT FINISHED"
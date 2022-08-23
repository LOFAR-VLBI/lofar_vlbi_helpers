#!/bin/bash
#SBATCH -N 1 -c 16 --constraint=intel --job-name=delay-calibration

#Example command:
#~/scripts/prefactor_helpers/prefactor_pipeline/run_DC.sh /project/lofarvwf/Share/jdejong/output/ELAIS/L798074/target /project/lotss/Public/jdejong/ELAIS/L798074/ddf
#in ../delaycal

CORES=16

echo "Job landed on $(hostname)"
echo "GENERIC PIPELINE STARTING"

export RUNDIR=$PWD
export RESULTS_DIR=$1
export DDF_OUTPUT=$2
export SIMG=/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.5_cascadelake_cascadelake_avx512_cuda11_3_ddf.sif

cd $RUNDIR

echo "RETRIEVING INPUT DATA ..."
# Run the pipeline
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/prefactor_pipeline/pipeline.cfg .
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/prefactor_pipeline/Delay-Calibration.parset .

sed -i "s?DDF_OUTPUT?$DDF_OUTPUT?g" Delay-Calibration.parset
sed -i "s?CORES?$CORES?g" Delay-Calibration.parset
sed -i "s?RESULTS_DIR?$RESULTS_DIR?g" Delay-Calibration.parset
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG genericpipeline.py -d -c pipeline.cfg Delay-Calibration.parset

echo "... done"
echo "GENERIC PIPELINE FINISHED"

#!/bin/bash
#SBATCH -N 1 -c 16 --constraint=intel --job-name=delay-calibration -p infinite --exclusive

CORES=16

echo "Job landed on $(hostname)"
echo "GENERIC PIPELINE STARTING"

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

export RUNDIR=$PWD
export RESULTS_DIR=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/target
export DDF_OUTPUT=/project/lotss/Public/jdejong/ELAIS/${OBSERVATION}/ddf
export SIMG=/project/lofarvwf/Software/singularity/test_lofar_sksp_v3.3.5_cascadelake_cascadelake_avx512_cuda11_3_ddf.sif

cd $RUNDIR

echo "RETRIEVING INPUT DATA ..."
# Run the pipeline
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/lofar-vlbi-setup/pipeline.cfg .
cp /home/lofarvwf-jdejong/scripts/prefactor_helpers/lofar-vlbi-setup/Delay-Calibration.parset .

sed -i "s?DDF_OUTPUT?$DDF_OUTPUT?g" Delay-Calibration.parset
sed -i "s?CORES?$CORES?g" Delay-Calibration.parset
sed -i "s?RESULTS_DIR?$RESULTS_DIR?g" Delay-Calibration.parset
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG CleanSHM.py
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG genericpipeline.py -d -c pipeline.cfg Delay-Calibration.parset
singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG python /home/lofarvwf-jdejong/scripts/prefactor_helpers/helper_scripts/change_hash_name.py --path ${RUNDIR}/Delay-Calibration --suffix msdpppconcat

echo "... done"
echo "GENERIC PIPELINE FINISHED"

#!/bin/bash
#SBATCH -N 1 -c 8 -t 48:00:00 --constraint=intel --job-name=pre-facet-cal

CORES=8

#1 --> result directory


echo "Job landed on $(hostname)"
echo "GENERIC PIPELINE STARTING"
export RUNDIR=$(mktemp -d -p "$TMPDIR")
export RESULTS_DIR=$1
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.3.3_x86-64_generic_avx512_ddf_public.sif

echo "RUNDIR is $(readlink -f $RUNDIR)"
cd $RUNDIR

echo "RETRIEVING INPUT DATA ..."
# Run the pipeline
cp ~/scripts/prefactor_helpers/prefactor_pipeline/pipeline.cfg .
cp ~/scripts/prefactor_helpers/prefactor_pipeline/Delay-Calibration.parset .

sed -i "s?CORES?$CORES?g" Pre-Facet-Calibrator.parset
sed -i "s?RESULTS_DIR?$RESULTS_DIR?g" Pre-Facet-Calibrator.parset
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg

singularity exec -B $PWD,/project $SIMG genericpipeline.py -d -c pipeline.cfg Pre-Facet-Calibrator.parset 

echo "Copying results to $RESULTS_DIR ..."
mkdir -p $RESULTS_DIR
cp -r Pre-Facet-Calibrator $RESULTS_DIR/
echo "... done"

echo "Cleaning up RUNDIR ..."
rm -rf $RUNDIR
echo "... done"
echo "GENERIC PIPELINE FINISHED "

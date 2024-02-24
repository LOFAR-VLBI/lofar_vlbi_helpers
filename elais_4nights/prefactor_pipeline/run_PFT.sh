#!/bin/bash
#SBATCH -N 1 -c 16 -t 120:00:00 --constraint=intel --job-name=pre-facet-target

CORES=16

echo "Job landed on $(hostname)"
echo "GENERIC PIPELINE STARTING"

RUNDIR=$(mktemp -d -p "$TMPDIR")
RESULTS_DIR=$1
CAL_DIR=$2
SIMG=$( python $HOME/parse_settings.py --SIMG )
SING_BIND=$( python $HOME/parse_settings.py --BIND )

echo "SINGULARITY IS $SIMG"

echo "RUNDIR is $(readlink -f $RUNDIR)"
cd $RUNDIR

echo "RETRIEVING INPUT DATA ..."
# Run the pipeline
cp /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/prefactor_pipeline/pipeline.cfg .
cp /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/prefactor_pipeline/Pre-Facet-Target.parset .

sed -i "s?CORES?$CORES?g" Pre-Facet-Target.parset
sed -i "s?RESULTS_DIR?$RESULTS_DIR?g" Pre-Facet-Target.parset
sed -i "s?CAL_DIR?$CAL_DIR?g" Pre-Facet-Target.parset
sed -i "s?PREFACTOR_SCRATCH_DIR?$RUNDIR?g" pipeline.cfg

singularity exec -B $SING_BIND $SIMG genericpipeline.py -d -c pipeline.cfg Pre-Facet-Target.parset

echo "Copying results to $RESULTS_DIR ..."
mkdir -p $RESULTS_DIR
cp -r Pre-Facet-Target $RESULTS_DIR/
echo "... done"

echo "Cleaning up RUNDIR ..."
rm -rf $RUNDIR
echo "... done"
echo "GENERIC PIPELINE FINISHED"

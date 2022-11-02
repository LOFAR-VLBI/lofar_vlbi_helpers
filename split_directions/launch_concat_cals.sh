#!/bin/bash
#SBATCH -N 1 -c 1 -t 120:00:00 --constraint=ssd --job-name=concatcals -o concat-%j

#############  WRITTEN BY FRITS SWEIJEN   #############

echo Job landed on $(hostname)
echo GENERIC PIPELINE STARTING

export RUNDIR=$(mktemp -d -p "$TMPDIR")
export RESULTS_DIR=/project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/
export SIMG=/project/lofarvwf/Software/singularity/lofar-grid-hpccloud_lofar_sksp@94aa06259a602eb0c19a237199b330c4fa7ca2d7.sif

echo RUNDIR is $(readlink -f $RUNDIR)
cd $RUNDIR

echo RETRIEVING INPUT DATA ...

# Run the pipeline
for b in $(ls -xd /project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/output_pybdsfcat/*MHz); do
	mkdir $(basename $b)
	cp -r $b/MYPOINTING $(basename $b)/
done

for f in ./*.tar; do
	tar xf $f
	rm -rf $f
done
echo ... done

# Now phaseshift to directions
singularity exec -B $PWD,/project $SIMG DPPP numthreads=1 msin=$(echo [$(ls -dm *MHz/$(basename MYPOINTING))] | sed "s/ //g") msout=$(basename MYPOINTING .ms)_concat.ms msout.storagemanagery=dysco steps=[]

echo Copying results to $RESULTS_DIR/ ...
mkdir -p $RESULTS_DIR/
cp -r ILT*concat.ms $RESULTS_DIR/
echo ... done

echo Cleaning up RUNDIR ...
rm -rf $RUNDIR
echo ... done
echo GENERIC PIPELINE FINISHED
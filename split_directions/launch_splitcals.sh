#!/bin/bash
#SBATCH -N 1 -c 4 -t 120:00:00 --constraint=ssd --job-name=splitcals

#############  BASED ON SCRIPT BY FRITS SWEIJEN   #############

PARSET=$1
MS=$2

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

H5=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/delayselfcal/merged_selfcalcyle000_linearfulljones_L816272_120_168MHz_averaged.ms.avg.h5

echo Job landed on $(hostname)
echo "-----------------STARTED-----------------"

export RUNDIR=$PWD
export RESULTS_DIR=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/ddcal
export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif


mkdir -p ${RESULTS_DIR}

echo RUNDIR is $(readlink -f $RUNDIR)
cd $RUNDIR

echo RETRIEVING INPUT DATA ...
# Run the pipeline
cp ${PARSET} .
gfal-copy -t 7200 ${MS} .

for f in ./*.tar; do
	tar xf $f
	rm -rf $f
done
echo ... done

# Apply DI solutions
cp ${H5} .

echo "Adding back CS to h5parms ..."
singularity exec -B $PWD,/project $SIMG python /project/lofarvwf/Software/lofar-vlbi/bin/gains_toCS_h5parm.py --solset_in=sol000 --solset_out=sol001 --superstation ST001 --soltab_list=phase000 ${H5} *.ms
singularity exec -B $PWD,/project $SIMG python /project/lofarvwf/Software/lofar-vlbi/bin/gains_toCS_h5parm.py --solset_in=sol000 --solset_out=sol001 --superstation ST001 --soltab_list=phase000,amplitude000 ${H5} *.ms
echo "... done"

echo "Applying DI solutions ..."
singularity exec -B $PWD,/project $SIMG DPPP numthreads=4 msin=results/*.ms msout=$(basename results/*.ms) msout.storagemanager=dysco steps=[applyp,applyap] applyp.type=applycal applyp.solset=sol001 applyp.correction=phase000 applyp.parmdb=${H5} applyap.type=applycal applyap.parmdb=${H5} applyap.solset=sol001 applyap.steps=[p,a] applyap.p.correction=phase000 applyap.a.correction=amplitude000
echo "... done"

echo "Phaseshifting to DDE calibrators ..."
singularity exec -B $PWD,/project $SIMG DPPP $(basename *.parset) numthreads=4 msin=*.ms
echo "... done"

BAND=$(ls -d *.ms | grep -P -o "\d{3}MHz")
echo "Copying results to ${RESULTS_DIR}/${BAND} ..."
mkdir -p $RESULTS_DIR/$BAND
cp -r ILTJ*.ms $RESULTS_DIR/$BAND
echo "... done"

echo "-----------------FINISHED-----------------"
#!/bin/bash
#SBATCH -N 1 -c 4 -t 120:00:00 --constraint=ssd --job-name=splitcals

#############  WRITTEN BY FRITS SWEIJEN   #############

echo Job landed on $(hostname)
echo GENERIC PIPELINE STARTING

export RUNDIR=$(mktemp -d -p "$TMPDIR")
export RESULTS_DIR=/project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/output_pybdsfcat
export SIMG=/project/lofarvwf/Software/singularity/lofar-grid-hpccloud_lofar_sksp@94aa06259a602eb0c19a237199b330c4fa7ca2d7.sif

echo RUNDIR is $(readlink -f $RUNDIR)
cd $RUNDIR

echo RETRIEVING INPUT DATA ...
# Run the pipeline
cp MYPARSET .
gfal-copy -t 7200 MYMS .

for f in ./*.tar; do
	tar xf $f
	rm -rf $f
done
echo ... done

# Apply DI solutions
cp /project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/phaseonlySL331132_sub6asec_L686962_SB001_uv_12CFFDDA8t_121MHz.ms.sub.shift.avg_12CFFDDAFt_144MHz.msdpppconcatsolsgrid_9.h5 .
cp /project/lofarvwf/Share/ELAIS-N1/long_baseline_dd/step2_find_calibrators/SL331132_sub6asec_L686962_SB001_uv_12CFFDDA8t_121MHz.ms.sub.shift.avg_12CFFDDAFt_144MHz.msdpppconcatsolsgrid_9.h5 .
H5_PHASE=phaseonlySL331132_sub6asec_L686962_SB001_uv_12CFFDDA8t_121MHz.ms.sub.shift.avg_12CFFDDAFt_144MHz.msdpppconcatsolsgrid_9.h5
H5_AMP=SL331132_sub6asec_L686962_SB001_uv_12CFFDDA8t_121MHz.ms.sub.shift.avg_12CFFDDAFt_144MHz.msdpppconcatsolsgrid_9.h5

echo Adding back CS to h5parms ...
singularity exec -B $PWD,/project $SIMG python /project/lofarvwf/Software/lofar-vlbi/bin/gains_toCS_h5parm.py --solset_in=sol000 --solset_out=sol001 --superstation ST001 --soltab_list=phase000 $H5_PHASE results/*.ms
singularity exec -B $PWD,/project $SIMG python /project/lofarvwf/Software/lofar-vlbi/bin/gains_toCS_h5parm.py --solset_in=sol000 --solset_out=sol001 --superstation ST001 --soltab_list=phase000,amplitude000 $H5_AMP results/*.ms
echo ... done

echo Applying DI solutions ...
# In the case of only phase solutions
#singularity exec -B $PWD,/project $SIMG DPPP numthreads=4 msin=results/*.ms msout=$(basename results/*.ms) msout.storagemanager=dysco steps=[applyp] applyp.type=applycal applyp.solset=sol001 applyp.correction=phase000 applyp.parmdb=$H5_PHASE
# In the case of both phase and amplitude solutions
singularity exec -B $PWD,/project $SIMG DPPP numthreads=4 msin=results/*.ms msout=$(basename results/*.ms) msout.storagemanager=dysco steps=[applyp,applyap] applyp.type=applycal applyp.solset=sol001 applyp.correction=phase000 applyp.parmdb=$H5_PHASE applyap.type=applycal applyap.parmdb=$H5_AMP applyap.solset=sol001 applyap.steps=[p,a] applyap.p.correction=phase000 applyap.a.correction=amplitude000
echo ... done

echo Phaseshifting to DDE calibrators ...
# Now phaseshift to directions
singularity exec -B $PWD,/project $SIMG DPPP $(basename *.parset) numthreads=4 msin=*.ms
echo ... done

BAND=$(ls -d *.ms | grep -P -o "\d{3}MHz")
echo Copyting results to $RESULTS_DIR/$BAND ...
mkdir -p $RESULTS_DIR/$BAND
cp -r ILTJ*.ms $RESULTS_DIR/$BAND
echo ... done

echo Cleaning up RUNDIR ...
rm -rf $RUNDIR
echo ... done
echo GENERIC PIPELINE FINISHED
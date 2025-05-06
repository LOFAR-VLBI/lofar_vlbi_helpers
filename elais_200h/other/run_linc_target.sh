#!/bin/bash
#SBATCH -c 31
#SBATCH -p infinite
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err

FLOCSRUNNERS=/project/lofarvwf/Software/flocs/runners

STARTDIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=/project/lofarvwf/Software/singularity/flocs_v5.2.0_znver2_znver2.sif


cd target
if ls L??????_LINC_target 1> /dev/null 2>&1; then
    rm -rf L??????_LINC_target
    rm job_output_full.txt
fi
singularity exec -B ${SING_BIND} ${SIMG} $FLOCSRUNNERS/run_LINC_target_HBA.sh -d $STARTDIR/target/data -c $STARTDIR/calibrator/*_LINC_calibrator/results_LINC_calibrator/cal_solutions.h5 -e "--make_structure_plot=False" -l /project/lofarvwf/Software/LINC
cd ../

#!/bin/bash
#SBATCH -c 31
#SBATCH -p infinite
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err

FLOCSRUNNERS=/project/lofarvwf/Software/flocs/runners

STARTDIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

source ~/venv/bin/activate

echo "Run LINC calibrator from $SCRIPT_DIR on Data in $STARTDIR/calibrator"
cd calibrator
source $FLOCSRUNNERS/run_LINC_calibrator_toil.sh -d $STARTDIR/calibrator/data -s $SIMG -b $SING_BIND
cd ../

#echo "Run LINC target from $SCRIPT_DIR on Data in $STARTDIR/target"
#cd target
#singularity exec -B ${SING_BIND} ${SIMG} $FLOCSRUNNERS/run_LINC_target.sh -d $STARTDIR/target/data -c $STARTDIR/calibrator/*_LINC_calibrator/results_LINC_calibrator/cal_solutions.h5 -e "--make_structure_plot=False"
#cd ../

deactivate
#!/bin/bash
#SBATCH -c 31
#SBATCH -p infinite
#SBATCH --output=linc_%j.out
#SBATCH --error=linc_%j.err

STARTDIR=$PWD

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

#GET ORIGINAL SCRIPT DIRECTORY
if [ -n "${SLURM_JOB_ID:-}" ] ; then
SCRIPT=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

echo "Run LINC calibrator from $SCRIPT_DIR on Data in $STARTDIR/calibrator"
cd calibrator
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_calibrator.sh -d $STARTDIR/calibrator/data
mv tmp.* linc_calibrator_output
cd ../

echo "Run LINC target from $SCRIPT_DIR on Data in $STARTDIR/target"
cd target
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_target.sh -d $STARTDIR/target/data -c $STARTDIR/calibrator/*_LINC_calibrator/results_LINC_calibrator/cal_solutions.h5
cd ../

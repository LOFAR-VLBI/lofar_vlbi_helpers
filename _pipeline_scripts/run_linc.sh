#!/bin/bash
#SBATCH -c 8
#SBATCH -t 72:00:00
#SBATCH --output=runlinc_%j.out
#SBATCH --error=runlinc_%j.err

STARTDIR=$PWD

#if [ $# -eq 0 ]
#  then
#    echo "No arguments supplied"
#    echo "Please run script as [ run_linc.sh <DATA_CALIBRATOR_FOLDER> <DATA_TARGET_FOLDER> ]"
#    exit 0
#fi

#GET ORIGINAL SCRIPT DIRECTORY
if [ -n "${SLURM_JOB_ID:-}" ] ; then
SCRIPT=$(scontrol show job "$SLURM_JOB_ID" | awk -F= '/Command=/{print $2}')
SCRIPT_DIR=$( echo ${SCRIPT%/*} )
else
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

echo "Run LINC calibrator from $SCRIPT_DIR on Data in $STARTDIR/calibrator"
cd calibrator
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_calibrator.sh -d $STARTDIR/calibrator/Data
mv tmp.* linc_calibrator_output
cd ../

echo "Run LINC target from $SCRIPT_DIR on Data in $STARTDIR/target"
cd target
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_target.sh -d $STARTDIR/target/Data -c $STARTDIR/calibrator/linc_calibrator_output/results_LINC_calibrator/cal_solutions.h5
cd ../

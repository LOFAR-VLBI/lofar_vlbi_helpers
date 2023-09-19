#!/bin/bash
#SBATCH -c 8
#SBATCH -t 72:00:00
#SBATCH --output=runlinc_%j.out
#SBATCH --error=runlinc_%j.err

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    echo "Please run script as [ run_linc.sh <DATA_CALIBRATOR_FOLDER> <DATA_TARGET_FOLDER> ]"
    exit 0
fi

#SINGULARITY SETTINGS
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SING_BIND=$( python3 $SCRIPT_DIR/settings/parse_settings.py --BIND )
SIMG=$( python3 $SCRIPT_DIR/settings/parse_settings.py --SIMG )

DATA_CAL=$1
DATA_TAR=$2

echo "Run LINC calibrator from $SCRIPT_DIR on Data in $DATA_CAL"
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_calibrator.sh -d $DATA_CAL

cd $DATA_TAR
cd ../

echo "Run LINC target from $SCRIPT_DIR on Data in $DATA_TAR"
singularity exec -B ${SING_BIND} ${SIMG} run_LINC_target.sh -d $DATA_TAR -c $DATA_CAL

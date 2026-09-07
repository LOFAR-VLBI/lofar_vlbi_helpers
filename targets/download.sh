#!/bin/bash
#SBATCH -c 8 -p short,normal

# INPUT
STAGE_ID_CALIBRATOR=$1
STAGE_ID_TARGET=$2
SASID=$3
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/lirgs

# SETUP
source $SCRIPT_DIR/setup.sh --no-git --no-sing
source /project/lofarvwf/Software/venv3.12/bin/activate

mkdir -p $MASTERDIR/L${SASID}
cd $MASTERDIR/L${SASID}

# DOWNLOAD CALIBRATOR
mkdir -p calibrator
cd calibrator
flocs-lta download --parallel-downloads 8 --stage-id $STAGE_ID_CALIBRATOR
cd ../

# DOWNLOAD TARGET
mkdir -p target
cd target
flocs-lta download --parallel-downloads 8 --stage-id $STAGE_ID_TARGET

deactivate

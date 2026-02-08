#!/bin/bash
#SBATCH -c 10

# INPUT
STAGE_ID_CALIBRATOR=$1
STAGE_ID_TARGET=$2
SASID=$3
SCRIPT_DIR=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/edfn

# SETUP
source $SCRIPT_DIR/setup.sh --no-git --no-sing

mkdir -p $MASTERDIR/L${SASID}
cd $MASTERDIR/L${SASID}

# DOWNLOAD CALIBRATOR
mkdir -p calibrator
cd calibrator
singularity exec $SING_IMG python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_CALIBRATOR
for CAL in L*; do
  rm -f ${CAL}/*SB*.tar*
  mkdir -p ${CAL}/data
  mv ${CAL}/*.MS ${CAL}/data/
done
cd ../

# DOWNLOAD TARGET
mkdir -p target
cd target
singularity exec $SING_IMG python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_TARGET
for TARGET in L*; do
  rm -f ${TARGET}/*SB*.tar*
  mkdir -p data
  mv ${TARGET}/*.MS data/
done

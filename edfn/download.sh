#!/bin/bash

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
mkdir -p calibrator/data
cd calibrator/data
singularity exec $SING_IMG python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_CALIBRATOR
for TAR in *SB*.tar*; do
    echo "Extracting $TAR ..."
    tar -xf $TAR
    rm -f $TAR
done
cd ../../

# SPLIT CALIBRATORS
cal1_prefix=""
cal2_prefix=""
for d in L[0-9][0-9][0-9][0-9][0-9][0-9][0-9]_* L[0-9][0-9][0-9][0-9][0-9][0-9]_*; do
    [ -d "$d" ] || continue
    prefix=${d%%_*}
    if [[ -z $cal1_prefix || $prefix == $cal1_prefix ]]; then
        cal1_prefix=$prefix
        mkdir -p ../../calibrator_1/data
        mv $d ../../calibrator_1/data/
    else
        cal2_prefix=$prefix
        mkdir -p ../../calibrator_2/data
        mv $d ../../calibrator_2/data/
    fi
done

# DOWNLOAD TARGET
mkdir -p target/data
cd target/data
singularity exec $SING_IMG python $SOFTWAREDIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_TARGET
for TAR in *SB*.tar*; do
    echo "Extracting $TAR ..."
    tar -xf $TAR
    rm -f $TAR
done
cd ../../

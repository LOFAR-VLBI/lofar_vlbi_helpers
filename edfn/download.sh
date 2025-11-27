#!/bin/bash

# INPUT
STAGE_ID_CALIBRATOR=$1
STAGE_ID_TARGET=$2
SASID=$3

# SETUP
if [[ -n ${SLURM_SUBMIT_DIR:-} ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fi
source $SCRIPT_DIR/setup.sh --no-git --no-sing

cd $MASTERDIR/L${SASID}

# DOWNLOAD CALIBRATOR
mkdir -p calibrator/data
cd calibrator/data
singularity exec $SING_IMG python $SOFTWARE_DIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_CALIBRATOR
for TAR in *SB*.tar*; do
    echo "Extracting $tar ..."
    tar -xf $tar
    rm -f $tar
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
singularity exec $SING_IMG python $SOFTWARE_DIR/flocs-lta/flocs_lta/flocs_download.py --parallel-downloads 10 $STAGE_ID_TARGET
for tar in *SB*.tar*; do
    echo "Extracting $tar ..."
    tar -xf $tar
    rm -f $tar
done
cd ../../

#!/bin/bash

TARHTML=$1

TARDAT=$( realpath $TARHTML )

LNUM=$( grep -Po 'L\d+' $TARDAT | head -n 1 )

#SINGULARITY SETTINGS
SIMG=$( python3 $SCRIPT_DIR/settings/parse_settings.py --SIMG )
BIND=$( python3 $SCRIPT_DIR/settings/parse_settings.py --BIND )

# make data folder
mkdir -p data
cd data

# download data
wget -ci $TARDAT

# untar data
for TAR in *SB*.tar*; do
  mv $TAR tmp.tar
  tar -xvf tmp.tar
  rm tmp.tar
done

singularity exec -B $BIND $SIMG source concat.sh ${LNUM}
cd ../

#singularity exec -B $PWD $SIMG python removebands.py

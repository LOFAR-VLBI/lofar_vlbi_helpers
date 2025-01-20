#!/bin/bash

TARHTML=$1
TARDAT=$( realpath $TARHTML )

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

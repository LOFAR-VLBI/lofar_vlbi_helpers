#!/bin/bash

RUNDIR=$1

for FILE in $RUNDIR/subtract_lotss/L*.ms
do
  echo "$FILE"
  sbatch /home/lofarvwf-jdejong/scripts/prefactor_helpers/subtract_lotss/subtraction.sh $FILE
done
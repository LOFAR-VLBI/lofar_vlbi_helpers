#!/bin/bash
#SBATCH -c 10

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )

singularity exec -B $BIND $SIMG python merge_all.py

mkdir -p /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions
cp merged_L??????.h5 /project/lofarvwf/Share/jdejong/output/ELAIS/ALL_L/dd_solutions

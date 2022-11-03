#!/bin/bash

#############  BASED ON SCRIPT FROM FRITS SWEIJEN   #############

MS=$1

for f in $(gfal-ls gsiftp://gridftp.grid.sara.nl:2811/pnfs/grid.sara.nl/data/lofar/user/lofarvwf/disk/ELAIS-N1/L686962/step1_subtract_lotss); do
	for P in $(readlink -f shift*.parset); do
		sbatch launch_splitcalls.sh ${P} ${MS}
	done
done
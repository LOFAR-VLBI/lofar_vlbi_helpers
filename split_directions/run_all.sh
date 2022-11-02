#!/bin/bash

#############  WRITTEN BY FRITS SWEIJEN   #############

for f in $(gfal-ls gsiftp://gridftp.grid.sara.nl:2811/pnfs/grid.sara.nl/data/lofar/user/lofarvwf/disk/ELAIS-N1/L686962/step1_subtract_lotss); do
	echo Dispatching $f
	cat launch_splitcals.sh | sed "s?MYMS?gsiftp://gridftp.grid.sara.nl:2811/pnfs/grid.sara.nl/data/lofar/user/lofarvwf/disk/ELAIS-N1/L686962/step1_subtract_lotss/$f?" > tmpjob.sh
	for p in $(readlink -f shift*.parset); do
		cat tmpjob.sh | sed "s?MYPARSET?$p?" > tmpjob2.sh
		sbatch tmpjob2.sh
	done
done
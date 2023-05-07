#!/bin/bash
#SBATCH -N 1 -c 1 --job-name=concat --constraint=amd

SCRIPTS=/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers

#SINGULARITY
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

#BOOKKEEPING
mkdir -p sub_parsets
mkdir -p concat_parsets
mv *.parset sub_parsets

#MAKE PARSETS
singularity exec -B $SING_BIND ${SIMG} python ${SCRIPTS}/split_directions/make_concat_parsets.py

#CONCAT PARSETS
for P in *.parset; do
  sbatch ${SCRIPTS}/split_directions/run_concat_parset.sh ${P}
done

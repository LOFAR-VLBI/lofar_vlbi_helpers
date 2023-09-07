#!/bin/bash

#SINGULARITY SETTINGS
SING_BIND=$( python3 $HOME/parse_settings.py --BIND )
SIMG=$( python3 $HOME/parse_settings.py --SIMG )

FNUM=$1

MAINDIR=$PWD
F=facet_$FNUM

echo $F

cd $F/imaging
singularity exec -B ${SING_BIND} ${SIMG} \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/imaging/split_facets/make_image.py \
--resolution 0.3 \
--facet $FNUM \
--facet_info $MAINDIR/polygon_info.csv \
--ms *.ms \
--tmpdir

sbatch wsclean.cmd

cd ../../

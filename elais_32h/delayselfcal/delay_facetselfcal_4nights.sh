#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=delayselfcal --constraint=amd

#RUN DELAYSELFCAL FOR MULTIPLE NIGHTS

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/L769393/subtract/subtract_lotss/L769393_120_168MHz_averaged.ms .
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/L816272/subtract/subtract_lotss/L816272_120_168MHz_averaged.ms .
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/L798074/subtract/subtract_lotss/L798074_120_168MHz_averaged.ms .
cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/L686962/subtract/subtract_lotss/L686962_120_168MHz_averaged.ms .

cp /project/lofarvwf/Share/jdejong/output/ELAIS/7C1604+5529.skymodel .

singularity exec -B $BIND $SIMG \
/home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/delayselfcal/delaycal.sh
#!/bin/bash
#SBATCH -N 1 -c 4 --job-name=applycal

#INPUT MS and H5
MSIN=$1
H5=$2

SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_vlbi_helpers/applycal/applycal.py \
--msin ${MSIN} \
--h5 ${H5} \
--msout applycal_${MSIN##*/}
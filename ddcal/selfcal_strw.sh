#!/bin/bash

MS=$1

#SINGULARITY SETTINGS
SIMG=$( python ../parse_settings.py --SIMG )
BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"

singularity exec -B $BIND $SIMG \
python /net/rijn/data2/rvweeren/LoTSS_ClusterCAL/lofar_facet_selfcal/facetselfcal.py \
-i selfcal \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--useaoflagger \
--stop=1 \
--no-beamcor \
--makeimage-fullpol \
--helperscriptspathh5merge=/home/jurjendejong/scripts/lofar_helpers \
${MS}

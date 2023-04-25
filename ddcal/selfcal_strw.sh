#!/bin/bash

MS=$1

#SINGULARITY SETTINGS
SIMG=$( python ../parse_settings.py --SIMG )
BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python ../parse_settings.py --lofar_facet_selfcal )

singularity exec -B $BIND $SIMG \
python $lofar_facet_selfcal \
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

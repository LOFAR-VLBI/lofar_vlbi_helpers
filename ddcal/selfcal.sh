#!/bin/bash
#SBATCH -c 12
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd

MS=$1

#SINGULARITY SETTINGS
SIMG=$( python ../parse_settings.py --SIMG )
BIND=$( python ../parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python ../parse_settings.py --facet_selfcal )

singularity exec -B $BIND $SIMG \
python $lofar_facet_selfcal \
-i selfcal \
--phaseupstations='core' \
--auto \
--useaoflagger \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--no-beamcor \
--makeimage-fullpol \
--helperscriptspath=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal \
--helperscriptspathh5merge=/home/lofarvwf-jdejong/scripts/lofar_helpers \
${MS}

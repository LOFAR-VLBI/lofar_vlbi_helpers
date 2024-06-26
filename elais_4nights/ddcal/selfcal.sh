#!/bin/bash
#SBATCH -c 12
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl
#SBATCH --constraint=amd

MS=$1

#SINGULARITY SETTINGS
SIMG=$( python3 $HOME/parse_settings.py --SIMG )
BIND=$( python3 $HOME/parse_settings.py --BIND )
echo "SINGULARITY IS $SIMG"
#SCRIPTS
lofar_facet_selfcal=$( python3 $HOME/parse_settings.py --facet_selfcal )

singularity exec -B $BIND $SIMG \
python $lofar_facet_selfcal \
-i selfcal \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--makeimage-fullpol \
--get_diagnostics \
--helperscriptspath=/project/lofarvwf/Software/lofar_facet_selfcal \
--helperscriptspathh5merge=/project/lofarvwf/Software/lofar_helpers \
${MS}

#!/bin/bash
#SBATCH -c 6
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=jurjendejong@strw.leidenuniv.nl

MS=$1

#SINGULARITY SETTINGS
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts
SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

singularity exec -B $BIND $SIMG \
python /home/lofarvwf-jdejong/scripts/lofar_facet_selfcal/facetselfcal.py \
-i selfcal \
--phaseupstations='core' \
--auto \
--makeimage-ILTlowres-HBA \
--targetcalILT='scalarphase' \
--stop=12 \
--helperscriptspath=/home/lofarvwf-jdejong/scripts/lofar_facet_selfcal \
--helperscriptspathh5merge=/home/lofarvwf-jdejong/scripts/lofar_helpers \
${MS}
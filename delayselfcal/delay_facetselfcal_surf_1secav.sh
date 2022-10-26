#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=delayselfcal

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts

#INPUT CONCATTENATED MS FILE
MSIN=$1

singularity exec -B $BIND $SIMG \
/home/lofarvwf-jdejong/scripts/prefactor_helpers/delayselfcal/delaycal_1secav.sh ${MSIN}
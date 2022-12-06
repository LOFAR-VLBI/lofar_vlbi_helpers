#!/bin/bash
#SBATCH -N 1 -c 2 --job-name=concat_parset

PARSET=$1

SCRIPTS=/home/lofarvwf-jdejong/scripts/prefactor_helpers

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts ${SIMG} DP3 ${PARSET}

mv ${PARSET} concat_parsets

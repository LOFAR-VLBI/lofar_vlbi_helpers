#!/bin/bash
#SBATCH -N 1 -c 24 --job-name=delayselfcal

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts

#INPUT CONCATTENATED MS FILE
MSIN=${OBSERVATION}_120_168MHz_averaged.ms

cp -r /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss/${MSIN} .

singularity exec -B $BIND $SIMG \
/home/lofarvwf-jdejong/scripts/prefactor_helpers/delayselfcal/delaycal_1secav.sh ${MSIN}
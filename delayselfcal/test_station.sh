#!/bin/bash
#SBATCH -N 1 -c 4
#SBATCH --job-name=test_station

re="L[0-9][0-9][0-9][0-9][0-9][0-9]"
if [[ $PWD =~ $re ]]; then OBSERVATION=${BASH_REMATCH}; fi

SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif
BIND=$PWD,/project,/home/lofarvwf-jdejong/scripts

singularity exec -B $BIND $SIMG python /home/lofarvwf-jdejong/scripts/prefactor_helpers/delayselfcal/test_stations.py \
--msfile /project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss/${OBSERVATION}_120_168MHz_averaged.ms

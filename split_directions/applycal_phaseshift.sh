#!/bin/bash
#SBATCH -N 1 -c 2 --job-name=splitcal

PARSET=$1
MS=$2
H5=$3

export SIMG=/project/lofarvwf/Software/singularity/lofar_sksp_v3.4_x86-64_generic_noavx512_ddf.sif

echo Job landed on $(hostname)


echo "Job landed on $(hostname)"

PATH_MS=/project/lofarvwf/Share/jdejong/output/ELAIS/${OBSERVATION}/subtract/subtract_lotss
SCRIPTS=/home/lofarvwf-jdejong/scripts/prefactor_helpers

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG \
python /home/lofarvwf-jdejong/scripts/prefactor_helpers/applycal/applycal.py \
--msin ${MS} \
--h5 ${H5} \
--msout applycal_${MS##*/}

singularity exec -B $PWD,/project,/home/lofarvwf-jdejong/scripts $SIMG DP3 \
msin=${MS} ${PARSET}
